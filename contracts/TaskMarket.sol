// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TaskMarket
 * @notice Decentralized marketplace for AI agent tasks
 * @dev Agents can post tasks, bid on them, and get paid upon completion
 */
contract TaskMarket {
    
    // ============ Enums ============
    
    enum TaskStatus {
        OPEN,           // Accepting bids
        ASSIGNED,       // Worker selected
        IN_PROGRESS,    // Work started
        COMPLETED,      // Work done, awaiting approval
        DISPUTED,       // Under dispute
        FINISHED,       // Paid and closed
        CANCELLED       // Cancelled by poster
    }
    
    enum TaskPriority {
        LOW,            // 3 day deadline
        MEDIUM,         // 1 day deadline
        HIGH,           // 4 hour deadline
        URGENT          // 1 hour deadline
    }
    
    // ============ Structs ============
    
    struct Task {
        uint256 id;
        address poster;
        string title;
        string description;
        string requirementsIPFS;    // Detailed requirements
        uint256 reward;             // Payment amount
        uint256 collateral;         // Poster collateral
        TaskPriority priority;
        TaskStatus status;
        uint256 createdAt;
        uint256 deadline;
        address assignedTo;
        string resultIPFS;          // Deliverable
        uint256 completedAt;
    }
    
    struct Bid {
        address bidder;
        uint256 amount;             // Bid amount (can be less than reward)
        uint256 estimatedTime;      // Estimated completion time
        string proposalIPFS;        // Detailed proposal
        uint256 reputation;         // Bidder's reputation score
        uint256 timestamp;
        bool accepted;
    }
    
    // ============ State Variables ============
    
    uint256 public nextTaskId = 1;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Bid[]) public taskBids;
    mapping(address => uint256[]) public agentTasks;        // Tasks by agent
    mapping(address => uint256) public agentReputation;     // Reputation scores
    mapping(address => uint256) public agentCompletedTasks;
    mapping(address => uint256) public agentTotalEarnings;
    
    address public feeRecipient;
    uint256 public protocolFeeBps = 250; // 2.5%
    uint256 public minimumReward = 0.001 ether;
    uint256 public cancellationFeeBps = 500; // 5% to cancel
    
    // Platform stats
    uint256 public totalTasksPosted;
    uint256 public totalTasksCompleted;
    uint256 public totalValueLocked;
    uint256 public totalFeesCollected;
    
    // ============ Events ============
    
    event TaskPosted(
        uint256 indexed taskId,
        address indexed poster,
        string title,
        uint256 reward,
        TaskPriority priority,
        uint256 deadline
    );
    
    event BidSubmitted(
        uint256 indexed taskId,
        address indexed bidder,
        uint256 amount,
        uint256 estimatedTime
    );
    
    event BidAccepted(
        uint256 indexed taskId,
        address indexed bidder,
        uint256 amount
    );
    
    event WorkStarted(uint256 indexed taskId, address indexed worker);
    
    event WorkCompleted(
        uint256 indexed taskId,
        address indexed worker,
        string resultIPFS
    );
    
    event TaskApproved(
        uint256 indexed taskId,
        address indexed worker,
        uint256 payment
    );
    
    event TaskDisputed(uint256 indexed taskId, address indexed by, string reason);
    
    event TaskCancelled(uint256 indexed taskId, uint256 refundAmount);
    
    event ReputationUpdated(address indexed agent, uint256 newScore);
    
    // ============ Modifiers ============
    
    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].id != 0, "Task not found");
        _;
    }
    
    modifier onlyPoster(uint256 _taskId) {
        require(tasks[_taskId].poster == msg.sender, "Not poster");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Post a new task
     */
    function postTask(
        string calldata _title,
        string calldata _description,
        string calldata _requirementsIPFS,
        uint256 _reward,
        TaskPriority _priority
    ) external payable returns (uint256 taskId) {
        
        require(_reward >= minimumReward, "Reward too low");
        require(msg.value >= _reward, "Insufficient payment");
        
        // Calculate deadline based on priority
        uint256 duration;
        if (_priority == TaskPriority.LOW) duration = 3 days;
        else if (_priority == TaskPriority.MEDIUM) duration = 1 days;
        else if (_priority == TaskPriority.HIGH) duration = 4 hours;
        else duration = 1 hours;
        
        taskId = nextTaskId++;
        
        tasks[taskId] = Task({
            id: taskId,
            poster: msg.sender,
            title: _title,
            description: _description,
            requirementsIPFS: _requirementsIPFS,
            reward: _reward,
            collateral: msg.value,
            priority: _priority,
            status: TaskStatus.OPEN,
            createdAt: block.timestamp,
            deadline: block.timestamp + duration,
            assignedTo: address(0),
            resultIPFS: "",
            completedAt: 0
        });
        
        agentTasks[msg.sender].push(taskId);
        totalTasksPosted++;
        totalValueLocked += msg.value;
        
        emit TaskPosted(
            taskId,
            msg.sender,
            _title,
            _reward,
            _priority,
            block.timestamp + duration
        );
        
        return taskId;
    }
    
    /**
     * @notice Bid on a task
     */
    function bidOnTask(
        uint256 _taskId,
        uint256 _amount,
        uint256 _estimatedTime,
        string calldata _proposalIPFS
    ) external taskExists(_taskId) {
        
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OPEN, "Not open");
        require(block.timestamp < task.deadline, "Deadline passed");
        require(_amount <= task.reward, "Bid exceeds reward");
        require(msg.sender != task.poster, "Cannot bid on own task");
        
        // Check if already bid
        for (uint256 i = 0; i < taskBids[_taskId].length; i++) {
            require(taskBids[_taskId][i].bidder != msg.sender, "Already bid");
        }
        
        Bid memory newBid = Bid({
            bidder: msg.sender,
            amount: _amount,
            estimatedTime: _estimatedTime,
            proposalIPFS: _proposalIPFS,
            reputation: agentReputation[msg.sender],
            timestamp: block.timestamp,
            accepted: false
        });
        
        taskBids[_taskId].push(newBid);
        
        emit BidSubmitted(_taskId, msg.sender, _amount, _estimatedTime);
    }
    
    /**
     * @notice Accept a bid and assign task
     */
    function acceptBid(uint256 _taskId, uint256 _bidIndex) 
        external 
        taskExists(_taskId) 
        onlyPoster(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OPEN, "Not open");
        require(_bidIndex < taskBids[_taskId].length, "Invalid bid");
        
        Bid storage bid = taskBids[_taskId][_bidIndex];
        require(!bid.accepted, "Already accepted");
        
        bid.accepted = true;
        task.assignedTo = bid.bidder;
        task.status = TaskStatus.ASSIGNED;
        task.reward = bid.amount; // Update to bid amount
        
        agentTasks[bid.bidder].push(_taskId);
        
        emit BidAccepted(_taskId, bid.bidder, bid.amount);
    }
    
    /**
     * @notice Worker starts the task
     */
    function startWork(uint256 _taskId) external taskExists(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.assignedTo == msg.sender, "Not assigned");
        require(task.status == TaskStatus.ASSIGNED, "Not assigned");
        
        task.status = TaskStatus.IN_PROGRESS;
        
        emit WorkStarted(_taskId, msg.sender);
    }
    
    /**
     * @notice Submit completed work
     */
    function submitWork(uint256 _taskId, string calldata _resultIPFS) 
        external 
        taskExists(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(task.assignedTo == msg.sender, "Not assigned");
        require(task.status == TaskStatus.IN_PROGRESS, "Not in progress");
        
        task.resultIPFS = _resultIPFS;
        task.completedAt = block.timestamp;
        task.status = TaskStatus.COMPLETED;
        
        emit WorkCompleted(_taskId, msg.sender, _resultIPFS);
    }
    
    /**
     * @notice Poster approves work and releases payment
     */
    function approveWork(uint256 _taskId) 
        external 
        taskExists(_taskId) 
        onlyPoster(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.COMPLETED, "Not completed");
        
        task.status = TaskStatus.FINISHED;
        
        // Calculate payment
        uint256 fee = (task.reward * protocolFeeBps) / 10000;
        uint256 payment = task.reward - fee;
        
        // Update stats
        totalValueLocked -= task.collateral;
        totalFeesCollected += fee;
        totalTasksCompleted++;
        
        // Update agent reputation
        agentReputation[task.assignedTo] += 10;
        agentCompletedTasks[task.assignedTo]++;
        agentTotalEarnings[task.assignedTo] += payment;
        
        // Transfer payment
        (bool success, ) = task.assignedTo.call{value: payment}("");
        require(success, "Payment failed");
        
        // Transfer fee
        (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");
        
        // Refund excess collateral to poster
        uint256 excess = task.collateral - task.reward;
        if (excess > 0) {
            (bool refundSuccess, ) = task.poster.call{value: excess}("");
            require(refundSuccess, "Refund failed");
        }
        
        emit TaskApproved(_taskId, task.assignedTo, payment);
        emit ReputationUpdated(task.assignedTo, agentReputation[task.assignedTo]);
    }
    
    /**
     * @notice Dispute a task
     */
    function disputeTask(uint256 _taskId, string calldata _reason) 
        external 
        taskExists(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(
            msg.sender == task.poster || msg.sender == task.assignedTo,
            "Not involved"
        );
        require(
            task.status == TaskStatus.IN_PROGRESS || 
            task.status == TaskStatus.COMPLETED,
            "Cannot dispute"
        );
        
        task.status = TaskStatus.DISPUTED;
        
        emit TaskDisputed(_taskId, msg.sender, _reason);
    }
    
    /**
     * @notice Cancel an open task
     */
    function cancelTask(uint256 _taskId) 
        external 
        taskExists(_taskId) 
        onlyPoster(_taskId) 
    {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.OPEN, "Not open");
        
        task.status = TaskStatus.CANCELLED;
        
        // Apply cancellation fee
        uint256 fee = (task.collateral * cancellationFeeBps) / 10000;
        uint256 refund = task.collateral - fee;
        
        totalValueLocked -= task.collateral;
        totalFeesCollected += fee;
        
        // Transfer fee
        (bool feeSuccess, ) = feeRecipient.call{value: fee}("");
        require(feeSuccess, "Fee transfer failed");
        
        // Refund poster
        (bool refundSuccess, ) = task.poster.call{value: refund}("");
        require(refundSuccess, "Refund failed");
        
        emit TaskCancelled(_taskId, refund);
    }
    
    // ============ View Functions ============
    
    function getTask(uint256 _taskId) external view returns (Task memory) {
        return tasks[_taskId];
    }
    
    function getBidCount(uint256 _taskId) external view returns (uint256) {
        return taskBids[_taskId].length;
    }
    
    function getBids(uint256 _taskId) external view returns (Bid[] memory) {
        return taskBids[_taskId];
    }
    
    function getAgentTasks(address _agent) external view returns (uint256[] memory) {
        return agentTasks[_agent];
    }
    
    function getOpenTasks(uint256 _offset, uint256 _limit) 
        external 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory openTasks = new uint256[](_limit);
        uint256 count = 0;
        
        for (uint256 i = _offset + 1; i < nextTaskId && count < _limit; i++) {
            if (tasks[i].status == TaskStatus.OPEN) {
                openTasks[count] = i;
                count++;
            }
        }
        
        // Trim array
        assembly {
            mstore(openTasks, count)
        }
        
        return openTasks;
    }
    
    function getAgentStats(address _agent) external view returns (
        uint256 reputation,
        uint256 completed,
        uint256 earnings
    ) {
        return (
            agentReputation[_agent],
            agentCompletedTasks[_agent],
            agentTotalEarnings[_agent]
        );
    }
    
    // Allow receiving ETH
    receive() external payable {}
}
