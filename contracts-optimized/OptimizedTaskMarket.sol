// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OptimizedTaskMarket
 * @notice Gas-optimized decentralized marketplace for AI agent tasks
 * @dev Optimizations: storage packing, direct storage writes, batch ops, calldata optimization
 */
contract OptimizedTaskMarket is ReentrancyGuard {
    
    // ============ Bitpacked Structs ============
    
    struct Task {
        uint256 id;
        address poster;
        bytes32 titleHash;          // IPFS hash of title (32 bytes vs dynamic string)
        bytes32 descriptionHash;    // IPFS hash of description
        bytes32 requirementsIPFS;   // IPFS hash of requirements
        uint128 reward;             // Packed with collateral
        uint128 collateral;
        TaskPriority priority;      // Enums fit in 8 bits
        TaskStatus status;
        uint40 createdAt;           // Unix timestamp good until year 36,000
        uint40 deadline;
        address assignedTo;
        bytes32 resultIPFS;
        uint40 completedAt;
    }
    
    struct Bid {
        address bidder;
        uint128 amount;             // Most bids won't exceed 3.4e38 wei
        uint40 estimatedTime;       // Seconds (good for ~34 years)
        bytes32 proposalIPFS;       // Fixed-size IPFS hash
        uint64 reputation;          // Reputation score
        uint40 timestamp;           // Block timestamp
        bool accepted;
    }
    
    // ============ Enums ============
    
    enum TaskStatus { OPEN, ASSIGNED, IN_PROGRESS, COMPLETED, DISPUTED, FINISHED, CANCELLED }
    enum TaskPriority { LOW, MEDIUM, HIGH, URGENT }
    
    // ============ Constants ============
    
    uint256 constant MAX_BIDS_PER_TASK = 50;
    uint256 constant MIN_TASK_DURATION = 1 hours;
    uint256 constant MAX_TASK_DURATION = 365 days;
    uint256 constant PLATFORM_FEE_BPS = 100;
    uint256 constant BPS_DENOMINATOR = 10000;
    
    // ============ State Variables ============
    
    uint256 public nextTaskId;
    
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Bid[]) public taskBids;
    mapping(address => uint256) public agentTaskCount;
    mapping(address => uint64) public agentReputation;
    mapping(address => uint128) public agentTotalEarnings;
    
    address public feeRecipient;
    uint128 public totalValueLocked;
    uint128 public totalFeesCollected;
    uint256 public totalTasksPosted;
    uint256 public totalTasksCompleted;
    uint128 public minimumReward = 0.001 ether;
    
    // ============ Events ============
    
    event TaskPosted(uint256 indexed taskId, address indexed poster, bytes32 titleHash, uint128 reward, uint40 deadline);
    event BidSubmitted(uint256 indexed taskId, address indexed bidder, uint128 amount);
    event BidAccepted(uint256 indexed taskId, address indexed bidder, uint128 amount);
    event WorkStarted(uint256 indexed taskId, address indexed worker);
    event WorkCompleted(uint256 indexed taskId, address indexed worker, bytes32 resultIPFS);
    event TaskApproved(uint256 indexed taskId, address indexed worker, uint128 payment);
    event ReputationUpdated(address indexed agent, uint64 newScore);
    
    // ============ Constructor ============
    
    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
        nextTaskId = 1;
    }
    
    // ============ Core Functions ============
    
    function postTask(
        bytes32 _titleHash,
        bytes32 _descriptionHash,
        bytes32 _requirementsIPFS,
        uint128 _reward,
        TaskPriority _priority
    ) external payable nonReentrant returns (uint256 taskId) {
        require(_titleHash != bytes32(0), "Title required");
        require(_reward >= minimumReward, "Reward too low");
        require(msg.value >= _reward, "Insufficient payment");
        
        uint40 duration;
        if (_priority == TaskPriority.LOW) duration = uint40(3 days);
        else if (_priority == TaskPriority.MEDIUM) duration = uint40(1 days);
        else if (_priority == TaskPriority.HIGH) duration = uint40(4 hours);
        else duration = uint40(1 hours);
        
        require(duration >= MIN_TASK_DURATION && duration <= MAX_TASK_DURATION, "Invalid duration");
        
        taskId = nextTaskId++;
        uint40 deadline = uint40(block.timestamp) + duration;
        
        // Direct storage write - no memory struct allocation
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
        task.deadline = deadline;
        
        unchecked {
            agentTaskCount[msg.sender]++;
            totalTasksPosted++;
            totalValueLocked += uint128(msg.value);
        }
        
        emit TaskPosted(taskId, msg.sender, _titleHash, _reward, deadline);
        return taskId;
    }
    
    function batchPostTasks(
        bytes32[] calldata _titleHashes,
        bytes32[] calldata _descriptionHashes,
        bytes32[] calldata _requirementsHashes,
        uint128[] calldata _rewards,
        TaskPriority[] calldata _priorities
    ) external payable nonReentrant returns (uint256[] memory taskIds) {
        uint256 count = _titleHashes.length;
        require(
            count == _descriptionHashes.length && 
            count == _requirementsHashes.length &&
            count == _rewards.length &&
            count == _priorities.length,
            "Array length mismatch"
        );
        require(count > 0 && count <= 20, "Invalid count");
        
        taskIds = new uint256[](count);
        uint128 totalValue;
        
        unchecked {
            for (uint256 i; i < count; ++i) {
                totalValue += _rewards[i];
            }
        }
        require(msg.value >= totalValue, "Insufficient payment");
        
        for (uint256 i; i < count; ++i) {
            taskIds[i] = _createTask(
                _titleHashes[i],
                _descriptionHashes[i],
                _requirementsHashes[i],
                _rewards[i],
                _priorities[i]
            );
        }
        
        unchecked {
            totalTasksPosted += count;
            totalValueLocked += totalValue;
        }
        
        uint256 excess = msg.value - totalValue;
        if (excess > 0) {
            (bool success, ) = msg.sender.call{value: excess}("");
            require(success, "Refund failed");
        }
        
        return taskIds;
    }
    
    function _createTask(
        bytes32 _titleHash,
        bytes32 _descriptionHash,
        bytes32 _requirementsIPFS,
        uint128 _reward,
        TaskPriority _priority
    ) internal returns (uint256 taskId) {
        uint40 duration;
        if (_priority == TaskPriority.LOW) duration = uint40(3 days);
        else if (_priority == TaskPriority.MEDIUM) duration = uint40(1 days);
        else if (_priority == TaskPriority.HIGH) duration = uint40(4 hours);
        else duration = uint40(1 hours);
        
        taskId = nextTaskId++;
        uint40 deadline = uint40(block.timestamp) + duration;
        
        Task storage task = tasks[taskId];
        task.id = taskId;
        task.poster = msg.sender;
        task.titleHash = _titleHash;
        task.descriptionHash = _descriptionHash;
        task.requirementsIPFS = _requirementsIPFS;
        task.reward = _reward;
        task.priority = _priority;
        task.status = TaskStatus.OPEN;
        task.createdAt = uint40(block.timestamp);
        task.deadline = deadline;
        
        unchecked {
            agentTaskCount[msg.sender]++;
        }
        
        emit TaskPosted(taskId, msg.sender, _titleHash, _reward, deadline);
    }
    
    function bidOnTask(
        uint256 _taskId,
        uint128 _amount,
        uint40 _estimatedTime,
        bytes32 _proposalIPFS
    ) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OPEN, "Not open");
        require(block.timestamp < task.deadline, "Deadline passed");
        require(_amount <= task.reward, "Bid exceeds reward");
        require(msg.sender != task.poster, "Cannot bid on own task");
        
        Bid[] storage bids = taskBids[_taskId];
        require(bids.length < MAX_BIDS_PER_TASK, "Max bids reached");
        
        uint256 bidCount = bids.length;
        unchecked {
            for (uint256 i; i < bidCount; ++i) {
                require(bids[i].bidder != msg.sender, "Already bid");
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
    
    function approveWork(uint256 _taskId) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.COMPLETED, "Not completed");
        require(task.poster == msg.sender, "Not poster");
        
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
        require(success, "Payment failed");
        
        (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");
        
        uint256 excess = task.collateral - task.reward;
        if (excess > 0) {
            (bool refundSuccess, ) = task.poster.call{value: excess}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit TaskApproved(_taskId, task.assignedTo, payment);
        emit ReputationUpdated(task.assignedTo, agentReputation[task.assignedTo]);
    }
    
    receive() external payable {}
}
