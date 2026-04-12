// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ReputationStake
 * @notice Staking and slashing mechanism for agent reputation
 * @dev Agents stake tokens to signal trustworthiness
 */
contract ReputationStake {
    
    // ============ Structs ============
    
    struct Stake {
        uint256 amount;
        uint256 since;
        uint256 unlockTime;
        bool withdrawn;
    }
    
    struct AgentProfile {
        uint256 totalStaked;
        uint256 reputationScore;
        uint256 successfulCovenants;
        uint256 breachedCovenants;
        uint256 lastActivity;
        bool isActive;
        string metadataURI; // IPFS URI with agent details
    }
    
    // ============ State Variables ============
    
    IERC20 public stakeToken;
    address public feeRecipient;
    
    mapping(address => AgentProfile) public agents;
    mapping(address => Stake[]) public agentStakes;
    mapping(address => bool) public authorizedSlashers;
    
    uint256 public minimumStake = 100 * 10**18; // 100 tokens
    uint256 public slashingPercentage = 1000; // 10%
    uint256 public lockPeriod = 7 days;
    uint256 public protocolFeeBps = 100; // 1%
    
    // Reputation calculation weights
    uint256 public stakeWeight = 40;
    uint256 public historyWeight = 30;
    uint256 public activityWeight = 30;
    
    uint256 public totalStaked;
    uint256 public totalAgents;
    
    // ============ Events ============
    
    event AgentRegistered(address indexed agent, string metadataURI);
    event StakeDeposited(address indexed agent, uint256 amount, uint256 unlockTime);
    event StakeWithdrawn(address indexed agent, uint256 amount);
    event ReputationUpdated(address indexed agent, uint256 newScore);
    event AgentSlashed(address indexed agent, uint256 amount, string reason);
    event RewardDistributed(address indexed agent, uint256 amount);
    
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
        authorizedSlashers[msg.sender] = true; // Owner is slasher
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Register as an agent
     */
    function registerAgent(string calldata _metadataURI) external {
        require(!agents[msg.sender].isActive, "Already registered");
        
        agents[msg.sender] = AgentProfile({
            totalStaked: 0,
            reputationScore: 0,
            successfulCovenants: 0,
            breachedCovenants: 0,
            lastActivity: block.timestamp,
            isActive: true,
            metadataURI: _metadataURI
        });
        
        totalAgents++;
        
        emit AgentRegistered(msg.sender, _metadataURI);
    }
    
    /**
     * @notice Stake tokens to build reputation
     */
    function stake(uint256 _amount) external onlyRegistered {
        require(_amount > 0, "Amount must be > 0");
        
        // Transfer tokens
        require(
            stakeToken.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        
        // Create stake
        Stake memory newStake = Stake({
            amount: _amount,
            since: block.timestamp,
            unlockTime: block.timestamp + lockPeriod,
            withdrawn: false
        });
        
        agentStakes[msg.sender].push(newStake);
        agents[msg.sender].totalStaked += _amount;
        totalStaked += _amount;
        
        // Update reputation
        _updateReputation(msg.sender);
        
        emit StakeDeposited(msg.sender, _amount, newStake.unlockTime);
    }
    
    /**
     * @notice Withdraw unlocked stakes
     */
    function withdrawStake(uint256 _stakeIndex) external onlyRegistered {
        require(_stakeIndex < agentStakes[msg.sender].length, "Invalid index");
        
        Stake storage stakeEntry = agentStakes[msg.sender][_stakeIndex];
        require(!stakeEntry.withdrawn, "Already withdrawn");
        require(block.timestamp >= stakeEntry.unlockTime, "Still locked");
        
        stakeEntry.withdrawn = true;
        uint256 amount = stakeEntry.amount;
        
        agents[msg.sender].totalStaked -= amount;
        totalStaked -= amount;
        
        // Update reputation after unstaking
        _updateReputation(msg.sender);
        
        require(stakeToken.transfer(msg.sender, amount), "Transfer failed");
        
        emit StakeWithdrawn(msg.sender, amount);
    }
    
    /**
     * @notice Record successful covenant completion
     */
    function recordSuccess(address _agent) external onlyAuthorizedSlasher {
        require(agents[_agent].isActive, "Not registered");
        
        agents[_agent].successfulCovenants++;
        agents[_agent].lastActivity = block.timestamp;
        
        _updateReputation(_agent);
        
        // Reward for consistent good behavior
        if (agents[_agent].successfulCovenants % 10 == 0) {
            _distributeReward(_agent);
        }
    }
    
    /**
     * @notice Record covenant breach and slash
     */
    function recordBreach(
        address _agent, 
        uint256 _slashingMultiplier,
        string calldata _reason
    ) external onlyAuthorizedSlasher {
        require(agents[_agent].isActive, "Not registered");
        
        agents[_agent].breachedCovenants++;
        agents[_agent].lastActivity = block.timestamp;
        
        // Calculate slash amount
        uint256 slashAmount = (agents[_agent].totalStaked * 
            slashingPercentage * _slashingMultiplier) / 10000;
        
        if (slashAmount > 0 && agents[_agent].totalStaked > 0) {
            // Slash from active stakes (oldest first)
            uint256 remainingToSlash = slashAmount;
            Stake[] storage stakes = agentStakes[_agent];
            
            for (uint256 i = 0; i < stakes.length && remainingToSlash > 0; i++) {
                if (!stakes[i].withdrawn && stakes[i].amount > 0) {
                    uint256 fromThisStake = remainingToSlash > stakes[i].amount 
                        ? stakes[i].amount 
                        : remainingToSlash;
                    
                    stakes[i].amount -= fromThisStake;
                    agents[_agent].totalStaked -= fromThisStake;
                    totalStaked -= fromThisStake;
                    remainingToSlash -= fromThisStake;
                }
            }
            
            // Transfer slashed amount to fee recipient
            require(
                stakeToken.transfer(feeRecipient, slashAmount - remainingToSlash),
                "Slash transfer failed"
            );
        }
        
        _updateReputation(_agent);
        
        emit AgentSlashed(_agent, slashAmount, _reason);
    }
    
    /**
     * @notice Calculate reputation score
     */
    function calculateReputation(address _agent) public view returns (uint256) {
        AgentProfile storage profile = agents[_agent];
        
        if (!profile.isActive) return 0;
        
        // Stake component (0-400 points)
        uint256 stakeScore = profile.totalStaked > 0 
            ? (profile.totalStaked * stakeWeight) / minimumStake 
            : 0;
        if (stakeScore > 400) stakeScore = 400;
        
        // History component (0-300 points)
        uint256 totalCovenants = profile.successfulCovenants + profile.breachedCovenants;
        uint256 historyScore = 0;
        if (totalCovenants > 0) {
            uint256 successRate = (profile.successfulCovenants * 100) / totalCovenants;
            historyScore = (successRate * historyWeight * 10) / 100; // 0-300
        }
        
        // Activity component (0-300 points)
        uint256 daysSinceActivity = (block.timestamp - profile.lastActivity) / 1 days;
        uint256 activityScore = daysSinceActivity < 30 
            ? ((30 - daysSinceActivity) * activityWeight * 10) / 30 
            : 0;
        
        return stakeScore + historyScore + activityScore;
    }
    
    // ============ Internal Functions ============
    
    function _updateReputation(address _agent) internal {
        uint256 newScore = calculateReputation(_agent);
        agents[_agent].reputationScore = newScore;
        emit ReputationUpdated(_agent, newScore);
    }
    
    function _distributeReward(address _agent) internal {
        // Simple reward: 1% of stake back
        uint256 reward = agents[_agent].totalStaked / 100;
        if (reward > 0) {
            require(stakeToken.transfer(_agent, reward), "Reward failed");
            emit RewardDistributed(_agent, reward);
        }
    }
    
    // ============ Admin Functions ============
    
    function addSlasher(address _slasher) external {
        require(authorizedSlashers[msg.sender], "Not authorized");
        authorizedSlashers[_slasher] = true;
    }
    
    function removeSlasher(address _slasher) external {
        require(authorizedSlashers[msg.sender], "Not authorized");
        authorizedSlashers[_slasher] = false;
    }
    
    function setParameters(
        uint256 _minimumStake,
        uint256 _slashingPercentage,
        uint256 _lockPeriod
    ) external {
        require(authorizedSlashers[msg.sender], "Not authorized");
        minimumStake = _minimumStake;
        slashingPercentage = _slashingPercentage;
        lockPeriod = _lockPeriod;
    }
    
    // ============ View Functions ============
    
    function getStakeCount(address _agent) external view returns (uint256) {
        return agentStakes[_agent].length;
    }
    
    function getStake(address _agent, uint256 _index) 
        external 
        view 
        returns (Stake memory) 
    {
        return agentStakes[_agent][_index];
    }
    
    function getAgentProfile(address _agent) 
        external 
        view 
        returns (AgentProfile memory) 
    {
        return agents[_agent];
    }
    
    function isRegistered(address _agent) external view returns (bool) {
        return agents[_agent].isActive;
    }
}
