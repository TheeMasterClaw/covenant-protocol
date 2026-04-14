// TaskMarket.spec
// Formal verification specification for TaskMarket contract

methods {
    function createTask(uint256 covenantId, uint256 reward, address rewardToken, uint256 deadline, bytes32 metadataHash) external returns (uint256) envfree;
    function assignTask(uint256 taskId) external envfree;
    function submitTask(uint256 taskId, bytes32 proofHash) external envfree;
    function completeTask(uint256 taskId) external envfree;
    function disputeTask(uint256 taskId) external returns (uint256) envfree;
    function cancelTask(uint256 taskId) external envfree;
    function getTask(uint256 taskId) external returns (TaskMarket.Task memory) envfree;
    function nextTaskId() external returns (uint256) envfree;
    function tasksByCovenant(uint256 covenantId, uint256 index) external returns (uint256) envfree;
    function tasksByAssignee(address assignee, uint256 index) external returns (uint256) envfree;
}

// Status enum definitions
definition OPEN() returns uint8 = 0;
definition ASSIGNED() returns uint8 = 1;
definition SUBMITTED() returns uint8 = 2;
definition COMPLETED() returns uint8 = 3;
definition DISPUTED() returns uint8 = 4;
definition CANCELLED() returns uint8 = 5;

// Ghost variable to track if a task has been completed
ghost mapping(uint256 => bool) taskWasCompleted;
ghost mapping(uint256 => bool) taskWasCancelled;

hook Sstore tasks[KEY uint256 taskId].status uint8 newStatus (uint8 oldStatus) {
    if (newStatus == COMPLETED() && oldStatus != COMPLETED()) {
        taskWasCompleted[taskId] = true;
    }
    if (newStatus == CANCELLED() && oldStatus != CANCELLED()) {
        taskWasCancelled[taskId] = true;
    }
}

// ============================================
// INVARIANTS
// ============================================

// INVARIANT: Task status is always valid
invariant validTaskStatus(uint256 taskId)
    getTask(taskId).status >= OPEN() && getTask(taskId).status <= CANCELLED();

// INVARIANT: If task is assigned or beyond, assignee is non-zero
invariant assigneeSetWhenActive(uint256 taskId)
    getTask(taskId).status > OPEN() => getTask(taskId).assignee != 0;

// INVARIANT: Completed tasks stay completed
invariant completedTasksImmutable(uint256 taskId)
    taskWasCompleted[taskId] => getTask(taskId).status == COMPLETED();

// INVARIANT: Cancelled tasks stay cancelled  
invariant cancelledTasksImmutable(uint256 taskId)
    taskWasCancelled[taskId] => getTask(taskId).status == CANCELLED();

// ============================================
// RULES
// ============================================

// RULE: Only open tasks can be assigned
rule onlyOpenTasksAssignable(uint256 taskId, env e) {
    uint8 statusBefore = getTask(taskId).status;
    
    assignTask@withrevert(e, taskId);
    bool reverted = lastReverted;
    
    if (!reverted) {
        assert statusBefore == OPEN(),
            "Can only assign open tasks";
    }
}

// RULE: Creator can only complete submitted tasks
rule onlySubmittedTasksCompletable(uint256 taskId, env e) {
    require e.msg.sender == getTask(taskId).creator;
    
    uint8 statusBefore = getTask(taskId).status;
    
    completeTask@withrevert(e, taskId);
    bool reverted = lastReverted;
    
    if (!reverted) {
        assert statusBefore == SUBMITTED(),
            "Can only complete submitted tasks";
        assert taskWasCompleted[taskId],
            "Task should be marked completed";
    }
}

// RULE: Assignee must match submitter
rule onlyAssigneeCanSubmit(uint256 taskId, bytes32 proofHash, env e) {
    address assignee = getTask(taskId).assignee;
    require e.msg.sender != assignee;
    
    submitTask@withrevert(e, taskId, proofHash);
    assert lastReverted,
        "Only assignee can submit task";
}

// RULE: Cancelled tasks cannot be completed
rule cancelledTasksNotCompletable(uint256 taskId, env e) {
    require getTask(taskId).status == CANCELLED();
    
    completeTask@withrevert(e, taskId);
    assert lastReverted,
        "Cancelled tasks should not be completable";
}

// RULE: Disputed tasks cannot be completed
rule disputedTasksNotCompletable(uint256 taskId, env e) {
    require getTask(taskId).status == DISPUTED();
    
    completeTask@withrevert(e, taskId);
    assert lastReverted,
        "Disputed tasks should not be completable";
}

// RULE: Task ID increments monotonically
rule taskIdMonotonicity(env e) {
    uint256 idBefore = nextTaskId();
    
    method f;
    calldataarg args;
    
    f(e, args);
    
    assert nextTaskId() >= idBefore,
        "Task ID should never decrease";
}

// RULE: Deadline must be in the future for new tasks
rule newTaskFutureDeadline(env e, uint256 covenantId, uint256 reward, address rewardToken, uint256 deadline, bytes32 metadataHash) {
    require deadline <= e.block.timestamp;
    require reward > 0;
    require covenantId > 0;
    
    createTask@withrevert(e, covenantId, reward, rewardToken, deadline, metadataHash);
    assert lastReverted,
        "Task deadline must be in the future";
}
