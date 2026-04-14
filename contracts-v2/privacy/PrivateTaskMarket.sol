// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PrivateTaskMarket
 * @notice Dark-pool style task market with ZK-sealed bids and commit-reveal
 * @dev Combines privacy-preserving bidding with reputation-gated assignment
 */
interface IZKBidValidator {
    struct BidProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[4] publicSignals;
    }
    function verifyProof(uint256[2] calldata a, uint256[2][2] calldata b, uint256[2] calldata c, uint256[4] calldata publicSignals) external view returns (bool);
}

interface IReputationOracle {
    function getTaskVerificationStatus(uint256 taskId) external view returns (bool verified, uint8[] memory oracleTypes, uint256 aggregatedConfidence);
}

contract PrivateTaskMarket is ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum TaskStatus { 
        OPEN,           // Accepting commitments
        COMMIT,         // Commit phase active
        REVEAL,         // Reveal phase active
        ASSIGNED,       // Task assigned
        IN_PROGRESS,    // Work started
        SUBMITTED,      // Work submitted
        COMPLETED,      // Work completed
        DISPUTED,       // Under dispute
        FINISHED,       // Finalized
        CANCELLED       // Cancelled
    }

    struct Task {
        uint256 id;
        address poster;
        uint128 reward;
        address rewardToken;
        uint128 collateral;
        uint40 deadline;
        uint40 commitDeadline;
        uint40 revealDeadline;
        TaskStatus status;
        address assignee;
        uint64 minReputation;
        bool zkRequired;
        bytes32 metadataHash;
        bytes32 resultHash;
    }

    struct BidCommitment {
        bytes32 commitment;
        uint40 timestamp;
        bool revealed;
    }

    struct RevealedBid {
        address bidder;
        uint128 amount;
        uint40 estimatedTime;
        bytes32 proposalHash;
        uint64 reputation;
        bool accepted;
    }

    IZKBidValidator public zkBidValidator;
    IReputationOracle public reputationOracle;

    uint256 public nextTaskId;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(address => BidCommitment)) public bidCommits;
    mapping(uint256 => RevealedBid[]) public revealedBids;
    mapping(uint256 => mapping(address => uint256)) public bidIndexByBidder;
    mapping(address => uint64) public agentReputation;
    mapping(address => uint256) public lockedDeposits;

    uint256 public constant PLATFORM_FEE_BPS = 100;
    uint256 public constant BPS_DENOMINATOR = 10000;
    uint256 public constant MAX_BIDS_PER_TASK = 50;
    uint256 public constant MIN_COMMIT_DURATION = 30 minutes;
    uint256 public constant MIN_REVEAL_DURATION = 30 minutes;
    uint256 public bidDepositAmount = 0.05 ether;

    event TaskPosted(uint256 indexed taskId, address indexed poster, uint128 reward, uint40 commitDeadline, uint40 revealDeadline);
    event BidCommitted(uint256 indexed taskId, address indexed bidder, bytes32 commitment);
    event BidRevealed(uint256 indexed taskId, address indexed bidder, uint128 amount, uint40 estimatedTime);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee, uint128 amount);
    event WorkStarted(uint256 indexed taskId, address indexed worker);
    event WorkSubmitted(uint256 indexed taskId, bytes32 resultHash);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee, uint128 payment);
    event TaskDisputed(uint256 indexed taskId, uint256 indexed disputeId);
    event TaskCancelled(uint256 indexed taskId);
    event ReputationUpdated(address indexed agent, uint64 newScore);

    error InvalidDeadline();
    error InvalidReward();
    error NotCommitPhase();
    error NotRevealPhase();
    error InvalidCommitment();
    error AlreadyCommitted();
    error AlreadyRevealed();
    error ZKProofRequired();
    error InvalidZKProof();
    error BidExceedsReward();
    error ReputationTooLow();
    error InvalidReveal();
    error TaskNotFound();
    error UnauthorizedAction();
    error TaskNotAssigned();
    error TaskNotSubmitted();
    error MaxBidsReached();
    error InvalidBidAmount();
    error CommitPhaseActive();
    error NoBidsRevealed();

    constructor(address _zkBidValidator, address _reputationOracle) {
        zkBidValidator = IZKBidValidator(_zkBidValidator);
        reputationOracle = IReputationOracle(_reputationOracle);
        nextTaskId = 1;
    }

    /**
     * @notice Post a new task with private bidding
     * @param reward Payment amount for task completion
     * @param rewardToken ERC20 token address (zero for native ETH)
     * @param totalDuration Total auction duration (commit + reveal)
     * @param minReputation Minimum reputation score required to bid
     * @param zkRequired Whether ZK validity proofs are required for bidding
     * @param metadataHash IPFS hash of task metadata
     */
    function postTask(
        uint128 reward,
        address rewardToken,
        uint40 totalDuration,
        uint64 minReputation,
        bool zkRequired,
        bytes32 metadataHash
    ) external payable nonReentrant returns (uint256 taskId) {
        if (totalDuration < MIN_COMMIT_DURATION + MIN_REVEAL_DURATION) revert InvalidDeadline();
        if (reward == 0) revert InvalidReward();

        taskId = nextTaskId++;
        uint40 now_ = uint40(block.timestamp);
        uint40 commitEnd = now_ + (totalDuration / 2);
        uint40 revealEnd = now_ + totalDuration;

        uint128 collateral = reward;
        if (rewardToken == address(0)) {
            if (msg.value < reward) revert InvalidReward();
            collateral = uint128(msg.value);
        } else {
            IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), reward);
        }

        tasks[taskId] = Task({
            id: taskId,
            poster: msg.sender,
            reward: reward,
            rewardToken: rewardToken,
            collateral: collateral,
            deadline: revealEnd,
            commitDeadline: commitEnd,
            revealDeadline: revealEnd,
            status: TaskStatus.COMMIT,
            assignee: address(0),
            minReputation: minReputation,
            zkRequired: zkRequired,
            metadataHash: metadataHash,
            resultHash: bytes32(0)
        });

        emit TaskPosted(taskId, msg.sender, reward, commitEnd, revealEnd);
    }

    /**
     * @notice Commit a sealed bid hash with optional ZK proof
     * @param taskId Task to bid on
     * @param commitment keccak256(abi.encode(bidder, amount, estimatedTime, proposalHash, salt))
     * @param zkProof Optional ZK proof of bid validity (if task.zkRequired)
     */
    function commitBid(
        uint256 taskId,
        bytes32 commitment,
        IZKBidValidator.BidProof calldata zkProof
    ) external payable nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.COMMIT) revert NotCommitPhase();
        if (block.timestamp >= task.commitDeadline) revert NotCommitPhase();
        if (msg.sender == task.poster) revert UnauthorizedAction();
        if (agentReputation[msg.sender] < task.minReputation) revert ReputationTooLow();
        if (msg.value < bidDepositAmount) revert InvalidBidAmount();

        BidCommitment storage bc = bidCommits[taskId][msg.sender];
        if (bc.commitment != bytes32(0)) revert AlreadyCommitted();

        if (task.zkRequired) {
            // ZK public signals: [taskId, commitmentHash, reputation, minReputation]
            if (zkProof.publicSignals[0] != taskId) revert InvalidZKProof();
            if (zkProof.publicSignals[1] != uint256(commitment) % 21888242871839275222246405745257275088548364400416034343698204186575808495617) revert InvalidZKProof();
            if (zkProof.publicSignals[2] != agentReputation[msg.sender]) revert InvalidZKProof();
            if (zkProof.publicSignals[3] != task.minReputation) revert InvalidZKProof();

            bool valid = zkBidValidator.verifyProof(zkProof.a, zkProof.b, zkProof.c, zkProof.publicSignals);
            if (!valid) revert InvalidZKProof();
        }

        bc.commitment = commitment;
        bc.timestamp = uint40(block.timestamp);
        lockedDeposits[msg.sender] += msg.value;

        emit BidCommitted(taskId, msg.sender, commitment);
    }

    /**
     * @notice Reveal a committed bid
     * @param taskId Task being bid on
     * @param amount Bid amount (must be <= task reward)
     * @param estimatedTime Estimated completion time
     * @param proposalHash IPFS hash of proposal details
     * @param salt Random salt used in commitment
     */
    function revealBid(
        uint256 taskId,
        uint128 amount,
        uint40 estimatedTime,
        bytes32 proposalHash,
        bytes32 salt
    ) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.COMMIT) revert NotRevealPhase();
        if (block.timestamp < task.commitDeadline) revert CommitPhaseActive();
        if (block.timestamp >= task.revealDeadline) revert NotRevealPhase();
        if (amount > task.reward) revert BidExceedsReward();

        BidCommitment storage bc = bidCommits[taskId][msg.sender];
        if (bc.commitment == bytes32(0)) revert InvalidCommitment();
        if (bc.revealed) revert AlreadyRevealed();

        bytes32 expected = keccak256(abi.encode(msg.sender, amount, estimatedTime, proposalHash, salt));
        if (bc.commitment != expected) revert InvalidCommitment();

        bc.revealed = true;

        RevealedBid[] storage bids = revealedBids[taskId];
        if (bids.length >= MAX_BIDS_PER_TASK) revert MaxBidsReached();

        bids.push(RevealedBid({
            bidder: msg.sender,
            amount: amount,
            estimatedTime: estimatedTime,
            proposalHash: proposalHash,
            reputation: agentReputation[msg.sender],
            accepted: false
        }));

        bidIndexByBidder[taskId][msg.sender] = bids.length;

        emit BidRevealed(taskId, msg.sender, amount, estimatedTime);
    }

    /**
     * @notice Accept a revealed bid and assign the task
     * @param taskId Task to assign
     * @param bidIndex Index in revealedBids array
     */
    function acceptBid(uint256 taskId, uint256 bidIndex) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.COMMIT) revert InvalidReveal();
        if (msg.sender != task.poster) revert UnauthorizedAction();
        if (block.timestamp < task.commitDeadline) revert CommitPhaseActive();
        if (block.timestamp >= task.revealDeadline) revert NotRevealPhase();

        RevealedBid[] storage bids = revealedBids[taskId];
        if (bidIndex >= bids.length) revert InvalidReveal();

        RevealedBid storage chosen = bids[bidIndex];
        if (chosen.accepted) revert AlreadyRevealed();

        chosen.accepted = true;
        task.status = TaskStatus.ASSIGNED;
        task.assignee = chosen.bidder;

        emit TaskAssigned(taskId, chosen.bidder, chosen.amount);
    }

    /**
     * @notice Worker marks task as started
     */
    function startWork(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.ASSIGNED) revert TaskNotAssigned();
        if (task.assignee != msg.sender) revert UnauthorizedAction();

        task.status = TaskStatus.IN_PROGRESS;
        emit WorkStarted(taskId, msg.sender);
    }

    /**
     * @notice Worker submits completed work
     */
    function submitWork(uint256 taskId, bytes32 resultHash) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.IN_PROGRESS) revert TaskNotAssigned();
        if (task.assignee != msg.sender) revert UnauthorizedAction();

        task.status = TaskStatus.SUBMITTED;
        task.resultHash = resultHash;
        emit WorkSubmitted(taskId, resultHash);
    }

    /**
     * @notice Poster accepts submitted work and releases payment
     */
    function completeTask(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.SUBMITTED) revert TaskNotSubmitted();
        if (task.poster != msg.sender) revert UnauthorizedAction();

        task.status = TaskStatus.COMPLETED;

        uint128 fee = uint128((uint256(task.reward) * PLATFORM_FEE_BPS) / BPS_DENOMINATOR);
        uint128 payment = task.reward - fee;

        // Update reputation
        agentReputation[task.assignee] += 10;

        // Release deposit
        lockedDeposits[task.assignee] -= bidDepositAmount;
        (bool depositSuccess, ) = payable(task.assignee).call{value: bidDepositAmount}("");
        if (!depositSuccess) revert InvalidBidAmount();

        // Transfer payment
        if (task.rewardToken == address(0)) {
            (bool success, ) = payable(task.assignee).call{value: payment}("");
            if (!success) revert InvalidReward();
        } else {
            IERC20(task.rewardToken).safeTransfer(task.assignee, payment);
        }

        emit TaskCompleted(taskId, task.assignee, payment);
        emit ReputationUpdated(task.assignee, agentReputation[task.assignee]);
    }

    /**
     * @notice Dispute a submitted task
     */
    function disputeTask(uint256 taskId) external returns (uint256 disputeId) {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.SUBMITTED) revert TaskNotSubmitted();
        if (msg.sender != task.poster && msg.sender != task.assignee) revert UnauthorizedAction();

        task.status = TaskStatus.DISPUTED;
        disputeId = uint256(keccak256(abi.encodePacked(taskId, block.timestamp, msg.sender)));

        emit TaskDisputed(taskId, disputeId);
    }

    /**
     * @notice Cancel task during commit phase (poster only)
     */
    function cancelTask(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.poster != msg.sender) revert UnauthorizedAction();
        if (task.status != TaskStatus.COMMIT && task.status != TaskStatus.OPEN) revert NotCommitPhase();

        task.status = TaskStatus.CANCELLED;

        // Refund collateral
        if (task.rewardToken == address(0)) {
            (bool success, ) = payable(task.poster).call{value: task.collateral}("");
            if (!success) revert InvalidReward();
        } else {
            IERC20(task.rewardToken).safeTransfer(task.poster, task.collateral);
        }

        emit TaskCancelled(taskId);
    }

    /**
     * @notice Auto-assign to lowest bid if reveal phase ends without manual selection
     */
    function autoAssign(uint256 taskId) external nonReentrant {
        Task storage task = tasks[taskId];
        if (task.id == 0) revert TaskNotFound();
        if (task.status != TaskStatus.COMMIT) revert InvalidReveal();
        if (block.timestamp < task.revealDeadline) revert NotRevealPhase();

        RevealedBid[] storage bids = revealedBids[taskId];
        if (bids.length == 0) revert NoBidsRevealed();

        // Find lowest bid
        uint256 lowestIndex = 0;
        uint128 lowestAmount = bids[0].amount;

        for (uint256 i = 1; i < bids.length; i++) {
            if (bids[i].amount < lowestAmount) {
                lowestAmount = bids[i].amount;
                lowestIndex = i;
            }
        }

        RevealedBid storage chosen = bids[lowestIndex];
        chosen.accepted = true;
        task.status = TaskStatus.ASSIGNED;
        task.assignee = chosen.bidder;

        emit TaskAssigned(taskId, chosen.bidder, chosen.amount);
    }

    // ============ Admin Functions ============

    function setAgentReputation(address agent, uint64 reputation) external {
        // In production, restrict to ReputationOracle
        agentReputation[agent] = reputation;
    }

    function setBidDeposit(uint256 amount) external {
        bidDepositAmount = amount;
    }

    function setZKValidator(address validator) external {
        zkBidValidator = IZKBidValidator(validator);
    }

    // ============ View Functions ============

    function getTask(uint256 taskId) external view returns (Task memory) {
        return tasks[taskId];
    }

    function getBids(uint256 taskId) external view returns (RevealedBid[] memory) {
        return revealedBids[taskId];
    }

    function getCommitment(uint256 taskId, address bidder) external view returns (BidCommitment memory) {
        return bidCommits[taskId][bidder];
    }

    receive() external payable {}
}
