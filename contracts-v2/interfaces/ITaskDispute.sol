// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITaskDispute
 * @notice Interface for the TaskDispute contract
 */
interface ITaskDispute {
    struct TaskDisputeRecord {
        uint256 disputeId;
        uint256 taskId;
        address initiator;
        address respondent;
        uint256 initiatedAt;
        uint8 status; // 0: Open, 1: Evidence, 2: Voting, 3: Resolved, 4: Appealed
        uint8 outcome; // 0: Pending, 1: InitiatorWins, 2: RespondentWins, 3: Split
        bytes32 reasonHash;
    }

    event TaskDisputeInitiated(uint256 indexed disputeId, uint256 indexed taskId, address indexed initiator);
    event TaskDisputeResponded(uint256 indexed disputeId, address indexed respondent);
    event TaskDisputeResolved(uint256 indexed disputeId, uint8 outcome);

    error TaskDisputeNotFound();
    error TaskDisputeAlreadyResolved();
    error UnauthorizedInitiator();
    error InvalidTaskStatus();

    function initiateDispute(uint256 taskId, bytes32 reasonHash) external returns (uint256 disputeId);
    function respondToDispute(uint256 disputeId) external;
    function resolveTaskDispute(uint256 disputeId, uint8 outcome) external;
    function getTaskDispute(uint256 disputeId) external view returns (TaskDisputeRecord memory);
    function getDisputesByTask(uint256 taskId) external view returns (uint256[] memory);
}
