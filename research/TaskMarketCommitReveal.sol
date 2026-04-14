// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TaskMarketCommitReveal
 * @notice MEV-resistant extension of OptimizedTaskMarket with commit-reveal bids,
 *         TWAP-based reserve pricing, and Flashbots-aware auction flags.
 */
contract TaskMarketCommitReveal is ReentrancyGuard {

    // ============ Bitpacked Structs ============
    struct Task {
        uint256 id;
        address poster;
        bytes32 titleHash;
        bytes32 descriptionHash;
        bytes32 requirementsIPFS;
        uint128 reward;
        uint128 collateral;
        TaskPriority priority;
        TaskStatus status;
        uint40 createdAt;
        uint40 deadline;
        address assignedTo;
        bytes32 resultIPFS;
        uint40 completedAt;
        uint40 commitDeadline;   // NEW: commit phase ends
        uint40 revealDeadline;   // NEW: reveal phase ends
        bool flashbotsPreferred; // NEW: hint for builders / frontends
    }

    struct BidCommitment {
        bytes32 commitment;
        uint40 timestamp;
        bool revealed;
    }

    struct Bid {
        address bidder;
        uint128 amount;
        uint40 estimatedTime;
        bytes32 proposalIPFS;
        uint64 reputation;
        uint40 timestamp;
        bool accepted;
    }

    enum TaskStatus { OPEN, ASSIGNED, IN_PROGRESS, COMPLETED, DISPUTED, FINISHED, CANCELLED }
    enum TaskPriority { LOW, MEDIUM, HIGH, URGENT }

    uint256 constant MAX_BIDS_PER_TASK = 50;
    uint256 constant MIN_TASK_DURATION = 1 hours;
    uint256 constant MAX_TASK_DURATION = 365 days;
    uint256 constant PLATFORM_FEE_BPS = 100;
    uint256 constant BPS_DENOMINATOR = 10000;
    uint256 constant COMMIT_REVEAL_RATIO = 2; // commit = duration/2, reveal = duration/2

    uint256 public nextTaskId;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => mapping(address => BidCommitment)) public bidCommits;
    mapping(uint256 => Bid[]) public taskBids;
    mapping(address => uint256) public agentTaskCount;
    mapping(address => uint64) public agentReputation;
    mapping(address => uint128) public agentTotalEarnings;

    address public feeRecipient;
    address public twapOracle;      // NEW
    uint128 public totalValueLocked;
    uint128 public totalFeesCollected;
    uint256 public totalTasksPosted;
    uint256 public totalTasksCompleted;
    uint128 public minimumReward = 0.001 ether;

    // ============ Events ============
    event TaskPosted(uint256 indexed taskId, address indexed poster, bytes32 titleHash, uint128 reward, uint40 deadline);
    event BidCommitted(uint256 indexed taskId, address indexed bidder, bytes32 commitment);
    event BidRevealed(uint256 indexed taskId, address indexed bidder, uint128 amount);
    event BidSubmitted(uint256 indexed taskId, address indexed bidder, uint128 amount);
    event BidAccepted(uint256 indexed taskId, address indexed bidder, uint128 amount);
    event WorkStarted(uint256 indexed taskId, address indexed worker);
    event WorkCompleted(uint256 indexed taskId, address indexed worker, bytes32 resultIPFS);
    event TaskApproved(uint256 indexed taskId, address indexed worker, uint128 payment);
    event ReputationUpdated(address indexed agent, uint64 newScore);

    // ============ Errors ============
    error NotOpen();
    error DeadlinePassed();
    error BidExceedsReward();
    error CannotBidOnOwnTask();
    error MaxBidsReached();
    error AlreadyBid();
    error NotPoster();
    error NotCompleted();
    error CommitPhaseEnded();
    error RevealPhaseNotStarted();
    error RevealPhaseEnded();
    error InvalidCommitment();
    error AlreadyRevealed();
    error TWAPBandViolation();

    // ============ Interfaces ============
    interface ITaskValuationOracle {
        function getSuggestedReward(uint256 categoryId) external view returns (uint128 minReward, uint128 maxReward);
    }

    constructor(address _feeRecipient, address _twapOracle) {
        feeRecipient = _feeRecipient;
        twapOracle = _twapOracle;
        nextTaskId = 1;
    }

    // ============ Task Posting ============
    function postTask(
        bytes32 _titleHash,
        bytes32 _descriptionHash,
        bytes32 _requirementsIPFS,
        uint128 _reward,
        TaskPriority _priority,
        bool _flashbotsPreferred
    ) external payable nonReentrant returns (uint256 taskId) {
        if (_titleHash == bytes32(0)) revert NotOpen();
        if (_reward < minimumReward) revert BidTooLow();
        if (msg.value < _reward) revert BidExceedsReward();

        uint40 duration;
        if (_priority == TaskPriority.LOW) duration = uint40(3 days);
        else if (_priority == TaskPriority.MEDIUM) duration = uint40(1 days);
        else if (_priority == TaskPriority.HIGH) duration = uint40(4 hours);
        else duration = uint40(1 hours);

        if (duration < MIN_TASK_DURATION || duration > MAX_TASK_DURATION) revert DeadlinePassed();

        // TWAP guardrail: if oracle set, enforce reward within suggested band
        if (twapOracle != address(0)) {
            (uint128 minReward, uint128 maxReward) = ITaskValuationOracle(twapOracle).getSuggestedReward(0);
            if (_reward > maxReward * 3) revert TWAPBandViolation();
            if (_reward < minReward / 3) revert TWAPBandViolation();
        }

        taskId = nextTaskId++;
        uint40 baseDeadline = uint40(block.timestamp) + duration;
        uint40 commitEnd = uint40(block.timestamp) + (duration / uint40(COMMIT_REVEAL_RATIO));

        Task storage task = tasks[taskId];
        task.id = taskId;
        task.poster = msg.sender;
        task.titleHash = _titleHash;
        task.descriptionHash = _descriptionHash;
        task.requirementsIPFS = _requirementsIPFS;
        task.reward = _reward;
        task.collateral = uint128(msg.value);
        task.priority = _priority;
        task.status = TaskStatus.OPEN;
        task.createdAt = uint40(block.timestamp);
        task.deadline = baseDeadline;
        task.commitDeadline = commitEnd;
        task.revealDeadline = baseDeadline;
        task.flashbotsPreferred = _flashbotsPreferred;

        unchecked {
            agentTaskCount[msg.sender]++;
            totalTasksPosted++;
            totalValueLocked += uint128(msg.value);
        }

        emit TaskPosted(taskId, msg.sender, _titleHash, _reward, baseDeadline);
        return taskId;
    }

    // ============ Commit-Reveal Bidding ============

    /**
     * @notice Commit a sealed bid hash.
     * @dev commitment = keccak256(abi.encode(msg.sender, amount, estimatedTime, proposalIPFS, salt))
     */
    function bidCommit(uint256 _taskId, bytes32 _commitment) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.OPEN) revert NotOpen();
        if (block.timestamp >= task.commitDeadline) revert CommitPhaseEnded();
        if (msg.sender == task.poster) revert CannotBidOnOwnTask();

        BidCommitment storage bc = bidCommits[_taskId][msg.sender];
        if (bc.commitment != bytes32(0)) revert AlreadyBid();

        bc.commitment = _commitment;
        bc.timestamp = uint40(block.timestamp);
        bc.revealed = false;

        emit BidCommitted(_taskId, msg.sender, _commitment);
    }

    /**
     * @notice Reveal bid and store it in public taskBids array.
     */
    function bidReveal(
        uint256 _taskId,
        uint128 _amount,
        uint40 _estimatedTime,
        bytes32 _proposalIPFS,
        bytes32 _salt
    ) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.OPEN) revert NotOpen();
        if (block.timestamp < task.commitDeadline) revert RevealPhaseNotStarted();
        if (block.timestamp >= task.revealDeadline) revert RevealPhaseEnded();
        if (_amount > task.reward) revert BidExceedsReward();

        BidCommitment storage bc = bidCommits[_taskId][msg.sender];
        if (bc.commitment == bytes32(0)) revert InvalidCommitment();
        if (bc.revealed) revert AlreadyRevealed();

        bytes32 expected = keccak256(abi.encode(msg.sender, _amount, _estimatedTime, _proposalIPFS, _salt));
        if (bc.commitment != expected) revert InvalidCommitment();

        bc.revealed = true;

        Bid[] storage bids = taskBids[_taskId];
        if (bids.length >= MAX_BIDS_PER_TASK) revert MaxBidsReached();

        bids.push(Bid({
            bidder: msg.sender,
            amount: _amount,
            estimatedTime: _estimatedTime,
            proposalIPFS: _proposalIPFS,
            reputation: agentReputation[msg.sender],
            timestamp: uint40(block.timestamp),
            accepted: false
        }));

        emit BidRevealed(_taskId, msg.sender, _amount);
        emit BidSubmitted(_taskId, msg.sender, _amount);
    }

    // Legacy plaintext bid for backwards compatibility / low-value tasks
    function bidOnTask(
        uint256 _taskId,
        uint128 _amount,
        uint40 _estimatedTime,
        bytes32 _proposalIPFS
    ) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.OPEN) revert NotOpen();
        if (block.timestamp >= task.deadline) revert DeadlinePassed();
        if (_amount > task.reward) revert BidExceedsReward();
        if (msg.sender == task.poster) revert CannotBidOnOwnTask();

        Bid[] storage bids = taskBids[_taskId];
        if (bids.length >= MAX_BIDS_PER_TASK) revert MaxBidsReached();

        uint256 bidCount = bids.length;
        unchecked {
            for (uint256 i; i < bidCount; ++i) {
                if (bids[i].bidder == msg.sender) revert AlreadyBid();
            }
        }

        bids.push(Bid({
            bidder: msg.sender,
            amount: _amount,
            estimatedTime: _estimatedTime,
            proposalIPFS: _proposalIPFS,
            reputation: agentReputation[msg.sender],
            timestamp: uint40(block.timestamp),
            accepted: false
        }));

        emit BidSubmitted(_taskId, msg.sender, _amount);
    }

    // ============ Acceptance & Settlement ============

    function acceptBid(uint256 _taskId, uint256 _bidIndex) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.OPEN) revert NotOpen();
        if (msg.sender != task.poster) revert NotPoster();
        if (block.timestamp >= task.revealDeadline) revert DeadlinePassed();

        Bid[] storage bids = taskBids[_taskId];
        if (_bidIndex >= bids.length) revert NotOpen();

        Bid storage chosen = bids[_bidIndex];
        if (chosen.accepted) revert AlreadyBid();
        chosen.accepted = true;
        task.status = TaskStatus.ASSIGNED;
        task.assignedTo = chosen.bidder;

        emit BidAccepted(_taskId, chosen.bidder, chosen.amount);
    }

    function startWork(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.ASSIGNED) revert NotOpen();
        if (task.assignedTo != msg.sender) revert NotPoster();
        task.status = TaskStatus.IN_PROGRESS;
        emit WorkStarted(_taskId, msg.sender);
    }

    function completeWork(uint256 _taskId, bytes32 _resultIPFS) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.IN_PROGRESS) revert NotOpen();
        if (task.assignedTo != msg.sender) revert NotPoster();
        task.status = TaskStatus.COMPLETED;
        task.resultIPFS = _resultIPFS;
        task.completedAt = uint40(block.timestamp);
        emit WorkCompleted(_taskId, msg.sender, _resultIPFS);
    }

    function approveWork(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.status != TaskStatus.COMPLETED) revert NotCompleted();
        if (task.poster != msg.sender) revert NotPoster();

        task.status = TaskStatus.FINISHED;

        uint128 fee = uint128((uint256(task.reward) * PLATFORM_FEE_BPS) / BPS_DENOMINATOR);
        uint128 payment = task.reward - fee;

        unchecked {
            totalValueLocked -= task.collateral;
            totalFeesCollected += fee;
            totalTasksCompleted++;
            agentReputation[task.assignedTo] += 10;
            agentTotalEarnings[task.assignedTo] += payment;
        }

        (bool success, ) = task.assignedTo.call{value: payment}("");
        if (!success) revert NotOpen();

        (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
        if (!feeSuccess) revert NotOpen();

        uint256 excess = task.collateral - task.reward;
        if (excess > 0) {
            (bool refundSuccess, ) = task.poster.call{value: excess}("");
            if (!refundSuccess) revert NotOpen();
        }

        emit TaskApproved(_taskId, task.assignedTo, payment);
        emit ReputationUpdated(task.assignedTo, agentReputation[task.assignedTo]);
    }

    // ============ TWAP Helpers ============
    function setTwapOracle(address _oracle) external {
        // In production, restrict to owner/governance
        twapOracle = _oracle;
    }

    receive() external payable {}

    error BidTooLow();
}
