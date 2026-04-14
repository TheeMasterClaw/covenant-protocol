// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title OptimizedReputationStake
 * @notice Gas-optimized staking and slashing for agent reputation
 * @dev Optimizations: storage packing, transient storage, cached reads, unchecked math
 */
contract OptimizedReputationStake {
    
    // ============ Optimized Structs ============
    
    struct AgentProfile {
        uint128 totalStaked;        // slot 0: 128 bits
        uint64 reputationScore;     // slot 0: 64 bits  
        uint32 successfulCovenants; // slot 0: 32 bits
        uint32 breachedCovenants;   // slot 0: 32 bits (total 256 bits)
        
        uint40 lastActivity;        // slot 1: 40 bits
        bool isActive;              // slot 1: 8 bits
        uint208 _reserved;          // slot 1: 208 bits reserved
        
        string metadataURI;         // slot 2: dynamic
    }
    
    struct Stake {
        uint128 amount;             // slot: 128 bits
        uint40 since;               // slot: 40 bits
        uint40 unlockTime;          // slot: 40 bits
        bool withdrawn;             // slot: 8 bits (total 216 bits)
    }
    
    // ============ State Variables ============
    
    IERC20 public stakeToken;
    address public feeRecipient;
    
    mapping(address => AgentProfile) public agents;
    mapping(address => Stake[]) public agentStakes;
    mapping(address => bool) public authorizedSlashers;
    mapping(address => uint256) public agentFlags; // Bitmap for bool flags
    
    uint128 public minimumStake = 100 * 10**18;
    uint256 public slashingPercentage = 1000; // 10%
    uint256 public lockPeriod = 7 days;
    uint128 public totalStaked;
    uint256 public totalAgents;
    
    // Weights cached as immutable constants
    uint256 constant STAKE_WEIGHT = 40;
    uint256 constant HISTORY_WEIGHT = 30;
    uint256 constant ACTIVITY_WEIGHT = 30;
    
    // Bitmap flags
    uint256 constant FLAG_VERIFIED = 1 << 0;
    uint256 constant FLAG_PREMIUM = 1 << 1;
    
    // Transient storage slots
    tbytes32 constant REP_CACHE_SLOT = keccak256("covenant.reputation.cache");
    
    // ============ Events ============
    
    event AgentRegistered(address indexed agent, string metadataURI);
    event StakeDeposited(address indexed agent, uint128 amount, uint40 unlockTime);
    event StakeWithdrawn(address indexed agent, uint128 amount);
    event ReputationUpdated(address indexed agent, uint64 newScore);
    event AgentSlashed(address indexed agent, uint256 amount, string reason);
    
    // ============ Modifiers ============
    
    modifier onlyAuthorizedSlasher() {
        require(authorizedSlashers[msg.sender], "Not authorized");
        _;
    }
    
    modifier onlyRegistered() {
        require(agents[msg.sender].isActive, "Not registered");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _stakeToken, address _feeRecipient) {
        stakeToken = IERC20(_stakeToken);
        feeRecipient = _feeRecipient;
        authorizedSlashers[msg.sender] = true;
    }
    
    // ============ Core Functions ============
    
    function registerAgent(string calldata _metadataURI) external {
        require(!agents[msg.sender].isActive, "Already registered");
        
        agents[msg.sender] = AgentProfile({
            totalStaked: 0,
            reputationScore: 0,
            successfulCovenants: 0,
            breachedCovenants: 0,
            lastActivity: uint40(block.timestamp),
            isActive: true,
            _reserved: 0,
            metadataURI: _metadataURI
        });
        
        unchecked {
            totalAgents++;
        }
        
        emit AgentRegistered(msg.sender, _metadataURI);
    }
    
    function stake(uint128 _amount) external onlyRegistered {
        require(_amount > 0, "Amount must be > 0");
        
        // Cache old reputation in transient storage
        uint256 oldRep = agents[msg.sender].reputationScore;
        assembly {
            tstore(REP_CACHE_SLOT, oldRep)
        }
        
        uint40 unlockTime = uint40(block.timestamp + lockPeriod);
        
        unchecked {
            agentStakes[msg.sender].push(Stake({
                amount: _amount,
                since: uint40(block.timestamp),
                unlockTime: unlockTime,
                withdrawn: false
            }));
            
            agents[msg.sender].totalStaked += _amount;
            totalStaked += _amount;
        }
        
        emit StakeDeposited(msg.sender, _amount, unlockTime);
        
        // External call last
        require(stakeToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        _updateReputationWithCache(msg.sender);
    }
    
    function withdrawStake(uint256 _stakeIndex) external onlyRegistered {
        require(_stakeIndex < agentStakes[msg.sender].length, "Invalid index");
        
        Stake storage stakeEntry = agentStakes[msg.sender][_stakeIndex];
        require(!stakeEntry.withdrawn, "Already withdrawn");
        require(block.timestamp >= stakeEntry.unlockTime, "Still locked");
        
        uint128 amount = stakeEntry.amount;
        stakeEntry.withdrawn = true;
        
        unchecked {
            agents[msg.sender].totalStaked -= amount;
            totalStaked -= amount;
        }
        
        emit StakeWithdrawn(msg.sender, amount);
        
        require(stakeToken.transfer(msg.sender, amount), "Transfer failed");
        
        _updateReputation(msg.sender);
    }
    
    function recordSuccess(address _agent) external onlyAuthorizedSlasher {
        AgentProfile memory profile = agents[_agent];
        require(profile.isActive, "Not registered");
        
        unchecked {
            profile.successfulCovenants++;
            profile.lastActivity = uint40(block.timestamp);
        }
        
        agents[_agent] = profile;
        
        _updateReputation(_agent);
    }
    
    function recordBreach(
        address _agent, 
        uint256 _slashingMultiplier,
        string calldata _reason
    ) external onlyAuthorizedSlasher {
        AgentProfile memory profile = agents[_agent];
        require(profile.isActive, "Not registered");
        
        unchecked {
            profile.breachedCovenants++;
            profile.lastActivity = uint40(block.timestamp);
        }
        
        uint256 slashAmount = (profile.totalStaked * slashingPercentage * _slashingMultiplier) / 10000;
        
        if (slashAmount > 0 && profile.totalStaked > 0) {
            Stake[] storage stakes = agentStakes[_agent];
            uint256 remaining = slashAmount;
            uint256 totalReduction;
            
            uint256 len = stakes.length;
            unchecked {
                for (uint256 i; i < len && remaining > 0; ++i) {
                    Stake storage s = stakes[i];
                    if (!s.withdrawn && s.amount > 0) {
                        uint128 fromThis = remaining > s.amount ? s.amount : uint128(remaining);
                        s.amount -= fromThis;
                        totalReduction += fromThis;
                        remaining -= fromThis;
                    }
                }
                
                profile.totalStaked -= uint128(totalReduction);
                totalStaked -= uint128(totalReduction);
            }
            
            uint256 actualSlash = slashAmount - remaining;
            if (actualSlash > 0) {
                require(stakeToken.transfer(feeRecipient, actualSlash), "Slash transfer failed");
            }
        }
        
        agents[_agent] = profile;
        _updateReputation(_agent);
        
        emit AgentSlashed(_agent, slashAmount, _reason);
    }
    
    function calculateReputation(address _agent) public view returns (uint256) {
        AgentProfile memory profile = agents[_agent];
        if (!profile.isActive) return 0;
        
        // Stake component (0-400 points)
        uint256 stakeScore = profile.totalStaked > 0 
            ? (uint256(profile.totalStaked) * STAKE_WEIGHT) / minimumStake 
            : 0;
        if (stakeScore > 400) stakeScore = 400;
        
        // History component (0-300 points)
        uint256 totalCovenants = uint256(profile.successfulCovenants) + uint256(profile.breachedCovenants);
        uint256 historyScore = 0;
        if (totalCovenants > 0) {
            uint256 successRate = (uint256(profile.successfulCovenants) * 100) / totalCovenants;
            historyScore = (successRate * HISTORY_WEIGHT * 10) / 100;
        }
        
        // Activity component (0-300 points)
        uint256 daysSinceActivity = (block.timestamp - profile.lastActivity) / 1 days;
        uint256 activityScore = daysSinceActivity < 30 
            ? ((30 - daysSinceActivity) * ACTIVITY_WEIGHT * 10) / 30 
            : 0;
        
        return stakeScore + historyScore + activityScore;
    }
    
    // ============ Internal Functions ============
    
    function _updateReputation(address _agent) internal {
        uint256 newScore = calculateReputation(_agent);
        uint64 score = uint64(newScore);
        if (agents[_agent].reputationScore != score) {
            agents[_agent].reputationScore = score;
            emit ReputationUpdated(_agent, score);
        }
    }
    
    function _updateReputationWithCache(address _agent) internal {
        uint256 cachedRep;
        assembly {
            cachedRep := tload(REP_CACHE_SLOT)
        }
        
        uint256 newScore = calculateReputation(_agent);
        if (newScore != cachedRep) {
            agents[_agent].reputationScore = uint64(newScore);
            emit ReputationUpdated(_agent, uint64(newScore));
        }
    }
    
    // ============ Admin Functions ============
    
    function addSlasher(address _slasher) external onlyAuthorizedSlasher {
        authorizedSlashers[_slasher] = true;
    }
    
    function removeSlasher(address _slasher) external onlyAuthorizedSlasher {
        authorizedSlashers[_slasher] = false;
    }
    
    // ============ View Functions ============
    
    function getStakeCount(address _agent) external view returns (uint256) {
        return agentStakes[_agent].length;
    }
    
    function getAgentProfile(address _agent) external view returns (AgentProfile memory) {
        return agents[_agent];
    }
}
