// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OptimizedDisputeDAO
 * @notice Gas-optimized decentralized arbitration with batch operations
 * @dev Optimizations: pre-computed tallies, storage packing, batch voting, unchecked math
 */
contract OptimizedDisputeDAO is ReentrancyGuard {
    
    enum DisputeStatus { PENDING, EVIDENCE, COMMIT, REVEAL, APPEAL, RESOLVED, EXECUTED }
    enum VoteOption { ABSTAIN, FOR_INITIATOR, FOR_COUNTERPARTY, SPLIT }
    
    struct Dispute {
        uint256 id;
        address covenant;
        address initiator;
        address counterparty;
        uint256 stakeAmount;
        string reason;
        string evidenceIPFS;
        DisputeStatus status;
        uint40 createdAt;
        uint40 evidenceEndTime;
        uint40 commitEndTime;
        uint40 revealEndTime;
        uint40 resolutionTime;
        uint128 initiatorAward;
        uint128 counterpartyAward;
        address[] jurors;
        mapping(address => bytes32) commitHashes;
        mapping(address => VoteOption) revealedVotes;
        mapping(address => uint128) jurorReputation;
        
        // Pre-computed tallies - updated on each reveal
        uint128 initiatorWeight;
        uint128 counterpartyWeight;
        uint128 splitWeight;
        uint128 totalReputationVoted;
        
        bool appealed;
        uint8 appealCount;
        uint8 resolvedOutcome; // 0=initiator, 1=counterparty, 2=split
    }
    
    struct JurorProfile {
        bool isActive;
        uint32 totalCases;
        uint32 correctVotes;
        uint64 reputation;
        uint128 stakedAmount;
        uint128 rewardsEarned;
        uint40 lastActivity;
    }
    
    struct BatchVote {
        uint256 disputeId;
        bytes32 commitHash;
    }
    
    struct BatchReveal {
        uint256 disputeId;
        VoteOption vote;
        uint256 salt;
    }
    
    // ============ State Variables ============
    
    IERC20 public stakingToken;
    address public reputationStake;
    
    uint256 public nextDisputeId;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => JurorProfile) public jurors;
    mapping(address => uint256[]) public jurorCases;
    
    uint128 public minJurorStake = 1000 * 10**18;
    uint8 public jurorCount = 7;
    uint32 public evidencePeriod = 3 days;
    uint32 public commitPeriod = 2 days;
    uint32 public revealPeriod = 1 days;
    uint32 public appealPeriod = 1 days;
    uint64 public minReputationToServe = 100;
    uint128 public disputeFee = 0.05 ether;
    uint16 public jurorRewardRate = 100; // 1%
    uint16 public missedVotePenalty = 50; // 0.5%
    uint16 public wrongVotePenalty = 25;  // 0.25%
    
    // ============ Events ============
    
    event DisputeCreated(uint256 indexed disputeId, address indexed covenant, address indexed initiator, uint256 stakeAmount);
    event JurorSelected(uint256 indexed disputeId, address indexed juror);
    event VoteCommitted(uint256 indexed disputeId, address indexed juror);
    event VoteRevealed(uint256 indexed disputeId, address indexed juror, VoteOption vote);
    event DisputeResolved(uint256 indexed disputeId, uint128 initiatorAward, uint128 counterpartyAward, uint128 totalVotingPower);
    event AppealFiled(uint256 indexed disputeId, uint8 appealCount);
    event BatchVotesCommitted(address indexed juror, uint256 count);
    event BatchVotesRevealed(address indexed juror, uint256 count);
    
    // ============ Modifiers ============
    
    modifier onlyJuror(uint256 _disputeId) {
        require(_isJuror(_disputeId, msg.sender), "Not a juror");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _stakingToken, address _reputationStake) {
        stakingToken = IERC20(_stakingToken);
        reputationStake = _reputationStake;
        nextDisputeId = 1;
    }
    
    // ============ Batch Operations ============
    
    function batchCommitVotes(BatchVote[] calldata _votes) external {
        uint256 votesLen = _votes.length;
        require(votesLen > 0 && votesLen <= 20, "Invalid batch size");
        
        JurorProfile storage profile = jurors[msg.sender];
        require(profile.isActive, "Not registered");
        
        unchecked {
            for (uint256 i; i < votesLen; ++i) {
                uint256 disputeId = _votes[i].disputeId;
                Dispute storage d = disputes[disputeId];
                
                require(_isJuror(disputeId, msg.sender), "Not a juror");
                require(d.status == DisputeStatus.COMMIT, "Not in commit phase");
                require(block.timestamp <= d.commitEndTime, "Commit period ended");
                require(d.commitHashes[msg.sender] == bytes32(0), "Already committed");
                
                d.commitHashes[msg.sender] = _votes[i].commitHash;
                emit VoteCommitted(disputeId, msg.sender);
            }
            
            profile.lastActivity = uint40(block.timestamp);
        }
        
        emit BatchVotesCommitted(msg.sender, votesLen);
    }
    
    function batchRevealVotes(BatchReveal[] calldata _reveals) external {
        uint256 revealsLen = _reveals.length;
        require(revealsLen > 0 && revealsLen <= 20, "Invalid batch size");
        
        JurorProfile storage profile = jurors[msg.sender];
        
        unchecked {
            for (uint256 i; i < revealsLen; ++i) {
                uint256 disputeId = _reveals[i].disputeId;
                Dispute storage d = disputes[disputeId];
                
                if (d.status == DisputeStatus.COMMIT && block.timestamp > d.commitEndTime) {
                    d.status = DisputeStatus.REVEAL;
                    d.revealEndTime = uint40(block.timestamp + revealPeriod);
                }
                
                require(d.status == DisputeStatus.REVEAL, "Not in reveal phase");
                require(block.timestamp <= d.revealEndTime, "Reveal period ended");
                require(d.revealedVotes[msg.sender] == VoteOption.ABSTAIN, "Already revealed");
                
                VoteOption vote = _reveals[i].vote;
                bytes32 commitHash = keccak256(abi.encodePacked(vote, _reveals[i].salt));
                require(commitHash == d.commitHashes[msg.sender], "Invalid reveal");
                
                d.revealedVotes[msg.sender] = vote;
                uint128 weight = d.jurorReputation[msg.sender];
                
                if (vote == VoteOption.FOR_INITIATOR) {
                    d.initiatorWeight += weight;
                } else if (vote == VoteOption.FOR_COUNTERPARTY) {
                    d.counterpartyWeight += weight;
                } else if (vote == VoteOption.SPLIT) {
                    d.splitWeight += weight;
                }
                d.totalReputationVoted += weight;
                
                emit VoteRevealed(disputeId, msg.sender, vote);
            }
            
            profile.lastActivity = uint40(block.timestamp);
        }
        
        emit BatchVotesRevealed(msg.sender, revealsLen);
    }
    
    function resolveDispute(uint256 _disputeId) external nonReentrant {
        Dispute storage d = disputes[_disputeId];
        require(d.status == DisputeStatus.REVEAL, "Not in reveal phase");
        require(block.timestamp > d.revealEndTime, "Reveal period active");
        
        // O(1) resolution using pre-computed tallies
        if (d.initiatorWeight > d.counterpartyWeight && d.initiatorWeight > d.splitWeight) {
            d.initiatorAward = uint128(d.stakeAmount);
            d.resolvedOutcome = 0;
        } else if (d.counterpartyWeight > d.initiatorWeight && d.counterpartyWeight > d.splitWeight) {
            d.counterpartyAward = uint128(d.stakeAmount);
            d.resolvedOutcome = 1;
        } else {
            d.initiatorAward = uint128(d.stakeAmount / 2);
            d.counterpartyAward = uint128(d.stakeAmount / 2);
            d.resolvedOutcome = 2;
        }
        
        d.status = DisputeStatus.RESOLVED;
        d.resolutionTime = uint40(block.timestamp);
        
        _processJurorRewards(_disputeId);
        
        emit DisputeResolved(_disputeId, d.initiatorAward, d.counterpartyAward, d.totalReputationVoted);
    }
    
    function _processJurorRewards(uint256 _disputeId) internal {
        Dispute storage d = disputes[_disputeId];
        uint256 totalReward = (d.stakeAmount * jurorRewardRate) / 10000;
        uint256 rewardPerJuror = totalReward / d.jurors.length;
        uint8 outcome = d.resolvedOutcome;
        uint256 jurorCount = d.jurors.length;
        
        unchecked {
            for (uint256 i; i < jurorCount; ++i) {
                address juror = d.jurors[i];
                JurorProfile storage profile = jurors[juror];
                VoteOption vote = d.revealedVotes[juror];
                
                bool votedCorrectly = (outcome == 0 && vote == VoteOption.FOR_INITIATOR) ||
                                     (outcome == 1 && vote == VoteOption.FOR_COUNTERPARTY) ||
                                     (outcome == 2 && vote == VoteOption.SPLIT);
                
                if (vote == VoteOption.ABSTAIN) {
                    profile.reputation = uint64((uint256(profile.reputation) * (10000 - missedVotePenalty)) / 10000);
                } else if (!votedCorrectly) {
                    profile.reputation = uint64((uint256(profile.reputation) * (10000 - wrongVotePenalty)) / 10000);
                } else {
                    profile.correctVotes++;
                    profile.rewardsEarned += uint128(rewardPerJuror);
                    require(stakingToken.transfer(juror, rewardPerJuror), "Reward failed");
                }
                
                profile.totalCases++;
                profile.lastActivity = uint40(block.timestamp);
            }
        }
    }
    
    // ============ Helpers ============
    
    function _isJuror(uint256 _disputeId, address _addr) internal view returns (bool) {
        Dispute storage d = disputes[_disputeId];
        uint256 len = d.jurors.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                if (d.jurors[i] == _addr) return true;
            }
        }
        return false;
    }
    
    // ============ Placeholders for inherited logic ============
    
    function createDispute(address _covenant, string calldata _reason, string calldata _evidenceIPFS) 
        external 
        payable 
        nonReentrant 
        returns (uint256 disputeId) 
    {
        require(msg.value >= disputeFee, "Insufficient fee");
        
        disputeId = nextDisputeId++;
        Dispute storage d = disputes[disputeId];
        d.id = disputeId;
        d.covenant = _covenant;
        d.reason = _reason;
        d.evidenceIPFS = _evidenceIPFS;
        d.status = DisputeStatus.PENDING;
        d.createdAt = uint40(block.timestamp);
        d.evidenceEndTime = uint40(block.timestamp + evidencePeriod);
        
        emit DisputeCreated(disputeId, _covenant, msg.sender, msg.value);
        return disputeId;
    }
    
    function getJurors(uint256 _disputeId) external view returns (address[] memory) {
        return disputes[_disputeId].jurors;
    }
}
