// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ICovenant.sol";
import "../interfaces/IReputationStake.sol";

/**
 * @title DisputeDAO
 * @notice Decentralized arbitration court for AI agent conflicts
 * @dev Uses commit-reveal voting with reputation-weighted decisions
 */
contract DisputeDAO is ReentrancyGuard {
    
    enum DisputeStatus {
        PENDING,        // Awaiting juror selection
        EVIDENCE,       // Evidence submission phase
        COMMIT,         // Jurors commit votes
        REVEAL,         // Jurors reveal votes
        APPEAL,         // Appeal window open
        RESOLVED,       // Final decision reached
        EXECUTED        // Resolution executed
    }

    enum VoteOption {
        ABSTAIN,
        FOR_INITIATOR,
        FOR_COUNTERPARTY,
        SPLIT
    }

    struct Dispute {
        uint256 id;
        address covenant;
        address initiator;
        address counterparty;
        uint256 stakeAmount;
        string reason;
        string evidenceIPFS;
        DisputeStatus status;
        uint256 createdAt;
        uint256 evidenceEndTime;
        uint256 commitEndTime;
        uint256 revealEndTime;
        uint256 resolutionTime;
        uint256 initiatorAward;
        uint256 counterpartyAward;
        address[] jurors;
        mapping(address => bytes32) commitHashes;
        mapping(address => VoteOption) revealedVotes;
        mapping(address => uint256) jurorReputation;
        uint256 totalReputationVoted;
        bool appealed;
        uint256 appealCount;
    }

    struct JurorProfile {
        bool isActive;
        uint256 totalCases;
        uint256 correctVotes;
        uint256 reputation;
        uint256 stakedAmount;
        uint256 rewardsEarned;
        uint256 lastActivity;
    }

    // ============ State Variables ============
    
    IERC20 public stakingToken;
    IReputationStake public reputationStake;
    
    uint256 public nextDisputeId = 1;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => JurorProfile) public jurors;
    mapping(address => uint256[]) public jurorCases;
    
    // Parameters
    uint256 public minJurorStake = 1000e18; // 1000 tokens
    uint256 public jurorCount = 7; // 7 jurors per case
    uint256 public evidencePeriod = 3 days;
    uint256 public commitPeriod = 2 days;
    uint256 public revealPeriod = 1 days;
    uint256 public appealPeriod = 1 days;
    uint256 public minReputationToServe = 100;
    
    // Fees
    uint256 public disputeFee = 0.05 ether;
    uint256 public jurorRewardRate = 100; // 1% of stake per juror
    
    // Penalties
    uint256 public missedVotePenalty = 50; // 5% reputation
    uint256 public wrongVotePenalty = 25;  // 2.5% reputation
    
    // ============ Events ============
    
    event DisputeCreated(
        uint256 indexed disputeId,
        address indexed covenant,
        address indexed initiator,
        uint256 stakeAmount
    );
    
    event JurorSelected(uint256 indexed disputeId, address indexed juror);
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed by, string ipfsHash);
    event VoteCommitted(uint256 indexed disputeId, address indexed juror);
    event VoteRevealed(uint256 indexed disputeId, address indexed juror, VoteOption vote);
    event DisputeResolved(
        uint256 indexed disputeId,
        uint256 initiatorAward,
        uint256 counterpartyAward,
        uint256 totalVotingPower
    );
    event JurorRewarded(uint256 indexed disputeId, address indexed juror, uint256 amount);
    event JurorPenalized(uint256 indexed disputeId, address indexed juror, uint256 amount, string reason);
    event AppealFiled(uint256 indexed disputeId, uint256 appealCount);
    
    // ============ Modifiers ============
    
    modifier onlyJuror(uint256 _disputeId) {
        require(_isJuror(_disputeId, msg.sender), "Not a juror");
        _;
    }
    
    modifier onlyDisputeParty(uint256 _disputeId) {
        Dispute storage d = disputes[_disputeId];
        require(
            msg.sender == d.initiator || msg.sender == d.counterparty,
            "Not a party"
        );
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _stakingToken, address _reputationStake) {
        stakingToken = IERC20(_stakingToken);
        reputationStake = IReputationStake(_reputationStake);
    }
    
    // ============ Juror Management ============
    
    function registerAsJuror(uint256 _stakeAmount) external nonReentrant {
        require(_stakeAmount >= minJurorStake, "Insufficient stake");
        require(!jurors[msg.sender].isActive, "Already registered");
        require(
            reputationStake.calculateReputation(msg.sender) >= minReputationToServe,
            "Insufficient reputation"
        );
        
        require(
            stakingToken.transferFrom(msg.sender, address(this), _stakeAmount),
            "Transfer failed"
        );
        
        jurors[msg.sender] = JurorProfile({
            isActive: true,
            totalCases: 0,
            correctVotes: 0,
            reputation: _stakeAmount / 1e18, // 1 token = 1 reputation point
            stakedAmount: _stakeAmount,
            rewardsEarned: 0,
            lastActivity: block.timestamp
        });
    }
    
    function unstakeAsJuror() external nonReentrant {
        JurorProfile storage juror = jurors[msg.sender];
        require(juror.isActive, "Not registered");
        require(juror.stakedAmount > 0, "No stake");
        
        // Check no active cases
        uint256[] storage cases = jurorCases[msg.sender];
        for (uint256 i = 0; i < cases.length; i++) {
            require(
                disputes[cases[i]].status == DisputeStatus.RESOLVED ||
                disputes[cases[i]].status == DisputeStatus.EXECUTED,
                "Active cases"
            );
        }
        
        uint256 amount = juror.stakedAmount;
        juror.isActive = false;
        juror.stakedAmount = 0;
        
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
    }
    
    // ============ Dispute Creation ============
    
    function createDispute(
        address _covenant,
        string calldata _reason,
        string calldata _evidenceIPFS
    ) external payable nonReentrant returns (uint256 disputeId) {
        require(msg.value >= disputeFee, "Insufficient fee");
        
        ICovenant covenant = ICovenant(_covenant);
        require(covenant.status() == 3, "Covenant not disputed"); // DISPUTED status
        
        disputeId = nextDisputeId++;
        Dispute storage d = disputes[disputeId];
        
        d.id = disputeId;
        d.covenant = _covenant;
        d.initiator = covenant.initiator();
        d.counterparty = covenant.counterparty();
        d.stakeAmount = covenant.remainingBalance();
        d.reason = _reason;
        d.evidenceIPFS = _evidenceIPFS;
        d.status = DisputeStatus.PENDING;
        d.createdAt = block.timestamp;
        d.evidenceEndTime = block.timestamp + evidencePeriod;
        
        // Select jurors
        _selectJurors(disputeId);
        
        emit DisputeCreated(disputeId, _covenant, d.initiator, d.stakeAmount);
        
        return disputeId;
    }
    
    function _selectJurors(uint256 _disputeId) internal {
        Dispute storage d = disputes[_disputeId];
        
        // In production, this would use Chainlink VRF for random selection
        // For now, use pseudo-random based on block hash
        for (uint256 i = 0; i < jurorCount; i++) {
            address juror = _getRandomJuror(_disputeId, i);
            if (juror != address(0)) {
                d.jurors.push(juror);
                jurorCases[juror].push(_disputeId);
                d.jurorReputation[juror] = jurors[juror].reputation;
                emit JurorSelected(_disputeId, juror);
            }
        }
        
        require(d.jurors.length >= 3, "Insufficient jurors");
        d.status = DisputeStatus.EVIDENCE;
    }
    
    function _getRandomJuror(uint256 _disputeId, uint256 _salt) internal view returns (address) {
        // Simplified - in production use Chainlink VRF
        bytes32 hash = keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            _disputeId,
            _salt,
            block.timestamp
        ));
        
        // This would iterate through registered jurors
        // Simplified for demo
        return address(uint160(uint256(hash)));
    }
    
    // ============ Evidence Phase ============
    
    function submitEvidence(uint256 _disputeId, string calldata _evidenceIPFS) 
        external 
        onlyDisputeParty(_disputeId) 
    {
        Dispute storage d = disputes[_disputeId];
        require(d.status == DisputeStatus.EVIDENCE, "Not in evidence phase");
        require(block.timestamp <= d.evidenceEndTime, "Evidence period ended");
        
        emit EvidenceSubmitted(_disputeId, msg.sender, _evidenceIPFS);
    }
    
    function advanceToCommitPhase(uint256 _disputeId) external {
        Dispute storage d = disputes[_disputeId];
        require(d.status == DisputeStatus.EVIDENCE, "Not in evidence phase");
        require(block.timestamp > d.evidenceEndTime, "Evidence period active");
        
        d.status = DisputeStatus.COMMIT;
        d.commitEndTime = block.timestamp + commitPeriod;
    }
    
    // ============ Voting Phase ============
    
    function commitVote(uint256 _disputeId, bytes32 _commitHash) 
        external 
        onlyJuror(_disputeId) 
    {
        Dispute storage d = disputes[_disputeId];
        require(d.status == DisputeStatus.COMMIT, "Not in commit phase");
        require(block.timestamp <= d.commitEndTime, "Commit period ended");
        require(d.commitHashes[msg.sender] == bytes32(0), "Already committed");
        
        d.commitHashes[msg.sender] = _commitHash;
        emit VoteCommitted(_disputeId, msg.sender);
    }
    
    function revealVote(
        uint256 _disputeId,
        VoteOption _vote,
        uint256 _salt
    ) external onlyJuror(_disputeId) {
        Dispute storage d = disputes[_disputeId];
        require(d.status == DisputeStatus.COMMIT || d.status == DisputeStatus.REVEAL, "Not in reveal phase");
        
        if (d.status == DisputeStatus.COMMIT && block.timestamp > d.commitEndTime) {
            d.status = DisputeStatus.REVEAL;
            d.revealEndTime = block.timestamp + revealPeriod;
        }
        
        require(d.status == DisputeStatus.REVEAL, "Not in reveal phase");
        require(block.timestamp <= d.revealEndTime, "Reveal period ended");
        require(d.revealedVotes[msg.sender] == VoteOption.ABSTAIN, "Already revealed");
        
        // Verify commitment
        bytes32 commitHash = keccak256(abi.encodePacked(_vote, _salt));
        require(commitHash == d.commitHashes[msg.sender], "Invalid reveal");
        
        d.revealedVotes[msg.sender] = _vote;
        d.totalReputationVoted += d.jurorReputation[msg.sender];
        
        emit VoteRevealed(_disputeId, msg.sender, _vote);
    }
    
    // ============ Resolution ============
    
    function resolveDispute(uint256 _disputeId) external nonReentrant {
        Dispute storage d = disputes[_disputeId];
        require(d.status == DisputeStatus.REVEAL, "Not in reveal phase");
        require(block.timestamp > d.revealEndTime, "Reveal period active");
        
        // Calculate weighted votes
        uint256 initiatorWeight = 0;
        uint256 counterpartyWeight = 0;
        uint256 splitWeight = 0;
        
        for (uint256 i = 0; i < d.jurors.length; i++) {
            address juror = d.jurors[i];
            uint256 weight = d.jurorReputation[juror];
            
            if (d.revealedVotes[juror] == VoteOption.FOR_INITIATOR) {
                initiatorWeight += weight;
            } else if (d.revealedVotes[juror] == VoteOption.FOR_COUNTERPARTY) {
                counterpartyWeight += weight;
            } else if (d.revealedVotes[juror] == VoteOption.SPLIT) {
                splitWeight += weight;
            }
        }
        
        // Determine outcome
        if (initiatorWeight > counterpartyWeight && initiatorWeight > splitWeight) {
            // Initiator wins
            d.initiatorAward = d.stakeAmount;
            d.counterpartyAward = 0;
        } else if (counterpartyWeight > initiatorWeight && counterpartyWeight > splitWeight) {
            // Counterparty wins
            d.initiatorAward = 0;
            d.counterpartyAward = d.stakeAmount;
        } else {
            // Split decision
            d.initiatorAward = d.stakeAmount / 2;
            d.counterpartyAward = d.stakeAmount / 2;
        }
        
        d.status = DisputeStatus.RESOLVED;
        d.resolutionTime = block.timestamp;
        
        // Reward/penalize jurors
        _processJurorRewards(_disputeId, initiatorWeight > counterpartyWeight);
        
        emit DisputeResolved(
            _disputeId,
            d.initiatorAward,
            d.counterpartyAward,
            d.totalReputationVoted
        );
    }
    
    function _processJurorRewards(uint256 _disputeId, bool initiatorWon) internal {
        Dispute storage d = disputes[_disputeId];
        uint256 totalReward = (d.stakeAmount * jurorRewardRate) / 10000;
        uint256 rewardPerJuror = totalReward / d.jurors.length;
        
        for (uint256 i = 0; i < d.jurors.length; i++) {
            address juror = d.jurors[i];
            JurorProfile storage profile = jurors[juror];
            
            VoteOption vote = d.revealedVotes[juror];
            bool votedCorrectly = (initiatorWon && vote == VoteOption.FOR_INITIATOR) ||
                                 (!initiatorWon && vote == VoteOption.FOR_COUNTERPARTY);
            
            if (vote == VoteOption.ABSTAIN) {
                // Penalty for not voting
                profile.reputation = (profile.reputation * (10000 - missedVotePenalty)) / 10000;
                emit JurorPenalized(_disputeId, juror, missedVotePenalty, "Missed vote");
            } else if (!votedCorrectly) {
                // Penalty for wrong vote
                profile.reputation = (profile.reputation * (10000 - wrongVotePenalty)) / 10000;
                emit JurorPenalized(_disputeId, juror, wrongVotePenalty, "Wrong vote");
            } else {
                // Reward for correct vote
                profile.correctVotes++;
                profile.rewardsEarned += rewardPerJuror;
                require(stakingToken.transfer(juror, rewardPerJuror), "Reward failed");
                emit JurorRewarded(_disputeId, juror, rewardPerJuror);
            }
            
            profile.totalCases++;
            profile.lastActivity = block.timestamp;
        }
    }
    
    // ============ Appeal ============
    
    function fileAppeal(uint256 _disputeId, string calldata _reason) 
        external 
        payable 
        onlyDisputeParty(_disputeId) 
    {
        require(msg.value >= disputeFee * 2, "Insufficient appeal fee");
        Dispute storage d = disputes[_disputeId];
        require(d.status == DisputeStatus.RESOLVED, "Not resolved");
        require(!d.appealed, "Already appealed");
        require(d.appealCount < 2, "Max appeals reached");
        
        d.appealed = true;
        d.appealCount++;
        d.status = DisputeStatus.PENDING;
        
        // Reset and select new jurors
        delete d.jurors;
        _selectJurors(_disputeId);
        
        emit AppealFiled(_disputeId, d.appealCount);
    }
    
    // ============ Execution ============
    
    function executeResolution(uint256 _disputeId) external nonReentrant {
        Dispute storage d = disputes[_disputeId];
        require(d.status == DisputeStatus.RESOLVED, "Not resolved");
        require(
            block.timestamp > d.resolutionTime + appealPeriod || d.appealed,
            "Appeal period active"
        );
        
        ICovenant covenant = ICovenant(d.covenant);
        covenant.resolveDispute(d.initiatorAward, d.counterpartyAward);
        
        d.status = DisputeStatus.EXECUTED;
    }
    
    // ============ View Functions ============
    
    function _isJuror(uint256 _disputeId, address _addr) internal view returns (bool) {
        Dispute storage d = disputes[_disputeId];
        for (uint256 i = 0; i < d.jurors.length; i++) {
            if (d.jurors[i] == _addr) return true;
        }
        return false;
    }
    
    function getDispute(uint256 _disputeId) external view returns (
        address covenant,
        DisputeStatus status,
        uint256 stakeAmount,
        uint256 jurorCount,
        bool canAppeal
    ) {
        Dispute storage d = disputes[_disputeId];
        return (
            d.covenant,
            d.status,
            d.stakeAmount,
            d.jurors.length,
            d.status == DisputeStatus.RESOLVED && !d.appealed && d.appealCount < 2
        );
    }
    
    function getJurors(uint256 _disputeId) external view returns (address[] memory) {
        return disputes[_disputeId].jurors;
    }
    
    function hasCommitted(uint256 _disputeId, address _juror) external view returns (bool) {
        return disputes[_disputeId].commitHashes[_juror] != bytes32(0);
    }
    
    function hasRevealed(uint256 _disputeId, address _juror) external view returns (bool) {
        return disputes[_disputeId].revealedVotes[_juror] != VoteOption.ABSTAIN;
    }
}
