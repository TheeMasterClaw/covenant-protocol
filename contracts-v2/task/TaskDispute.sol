// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITaskDispute} from "../interfaces/ITaskDispute.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaskDispute
 * @notice Task-level dispute management
 */
contract TaskDispute is ITaskDispute, Ownable {
    uint256 private _nextDisputeId;
    mapping(uint256 => TaskDisputeRecord) public disputes;
    mapping(uint256 => uint256[]) public disputesByTask;

    constructor() Ownable(msg.sender) {
        _nextDisputeId = 1;
    }

    /// @inheritdoc ITaskDispute
    function initiateDispute(uint256 taskId, bytes32 reasonHash) external returns (uint256 disputeId) {
        if (taskId == 0) revert InvalidTaskStatus();
        if (reasonHash == bytes32(0)) revert InvalidTaskStatus();

        disputeId = _nextDisputeId++;
        disputes[disputeId] = TaskDisputeRecord({
            disputeId: disputeId,
            taskId: taskId,
            initiator: msg.sender,
            respondent: address(0),
            initiatedAt: block.timestamp,
            status: 0,
            outcome: 0,
            reasonHash: reasonHash
        });
        disputesByTask[taskId].push(disputeId);

        emit TaskDisputeInitiated(disputeId, taskId, msg.sender);
    }

    /// @inheritdoc ITaskDispute
    function respondToDispute(uint256 disputeId) external {
        TaskDisputeRecord storage dispute = disputes[disputeId];
        if (dispute.disputeId == 0) revert TaskDisputeNotFound();
        if (dispute.status != 0) revert TaskDisputeAlreadyResolved();
        if (dispute.initiator == msg.sender) revert UnauthorizedInitiator();

        dispute.respondent = msg.sender;
        dispute.status = 1;

        emit TaskDisputeResponded(disputeId, msg.sender);
    }

    /// @inheritdoc ITaskDispute
    function resolveTaskDispute(uint256 disputeId, uint8 outcome) external onlyOwner {
        TaskDisputeRecord storage dispute = disputes[disputeId];
        if (dispute.disputeId == 0) revert TaskDisputeNotFound();
        if (dispute.status == 3) revert TaskDisputeAlreadyResolved();
        if (outcome == 0 || outcome > 3) revert InvalidTaskStatus();

        dispute.outcome = outcome;
        dispute.status = 3;

        emit TaskDisputeResolved(disputeId, outcome);
    }

    /// @inheritdoc ITaskDispute
    function getTaskDispute(uint256 disputeId) external view returns (TaskDisputeRecord memory) {
        return disputes[disputeId];
    }

    /// @inheritdoc ITaskDispute
    function getDisputesByTask(uint256 taskId) external view returns (uint256[] memory) {
        return disputesByTask[taskId];
    }
}