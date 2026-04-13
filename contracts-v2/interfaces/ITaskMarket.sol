// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITaskMarket
 * @notice Interface for the TaskMarket contract
 */
interface ITaskMarket {
    struct Task {
        uint256 id;
        uint256 covenantId;
        address creator;
        address assignee;
        uint256 reward;
        address rewardToken;
        uint256 deadline;
        uint8 status; // 0: Open, 1: Assigned, 2: Submitted, 3: Completed, 4: Disputed, 5: Cancelled
        bytes32 metadataHash;
    }

    event TaskCreated(uint256 indexed taskId, uint256 indexed covenantId, address indexed creator, uint256 reward);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskSubmitted(uint256 indexed taskId, bytes32 proofHash);
    event TaskCompleted(uint256 indexed taskId, address indexed assignee, uint256 reward);
    event TaskDisputed(uint256 indexed taskId, uint256 indexed disputeId);
    event TaskCancelled(uint256 indexed taskId);

    error InvalidCovenant();
    error InvalidReward();
    error InvalidDeadline();
    error TaskNotOpen();
    error TaskNotAssigned();
    error TaskNotSubmitted();
    error UnauthorizedTaskAction();
    error DeadlinePassed();

    function createTask(
        uint256 covenantId,
        uint256 reward,
        address rewardToken,
        uint256 deadline,
        bytes32 metadataHash
    ) external payable returns (uint256 taskId);

    function assignTask(uint256 taskId) external;
    function submitTask(uint256 taskId, bytes32 proofHash) external;
    function completeTask(uint256 taskId) external;
    function disputeTask(uint256 taskId) external returns (uint256 disputeId);
    function cancelTask(uint256 taskId) external;
    function getTask(uint256 taskId) external view returns (Task memory);
    function getTasksByCovenant(uint256 covenantId) external view returns (uint256[] memory);
    function getTasksByAssignee(address assignee) external view returns (uint256[] memory);
}
