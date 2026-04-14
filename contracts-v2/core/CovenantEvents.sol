// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantEvents} from "../interfaces/ICovenantEvents.sol";

/**
 * @title CovenantEvents
 * @notice Standardized event emitter for the COVENANT protocol
 */
contract CovenantEvents is ICovenantEvents {
    /// @notice Emits a CovenantCreated event
    function emitCovenantCreated(uint256 covenantId, address creator, address proxy) external {
        emit CovenantCreated(covenantId, creator, proxy);
    }

    /// @notice Emits a CovenantUpdated event
    function emitCovenantUpdated(uint256 covenantId, bytes32 updateType, bytes calldata data) external {
        emit CovenantUpdated(covenantId, updateType, data);
    }

    /// @notice Emits a CovenantActivated event
    function emitCovenantActivated(uint256 covenantId, uint256 timestamp) external {
        emit CovenantActivated(covenantId, timestamp);
    }

    /// @notice Emits a CovenantPaused event
    function emitCovenantPaused(uint256 covenantId, uint256 timestamp) external {
        emit CovenantPaused(covenantId, timestamp);
    }

    /// @notice Emits a CovenantResolved event
    function emitCovenantResolved(uint256 covenantId, uint256 timestamp) external {
        emit CovenantResolved(covenantId, timestamp);
    }

    /// @notice Emits a CovenantTerminated event
    function emitCovenantTerminated(uint256 covenantId, uint256 timestamp) external {
        emit CovenantTerminated(covenantId, timestamp);
    }

    /// @notice Emits a TaskCreated event
    function emitTaskCreated(uint256 taskId, uint256 covenantId, address creator) external {
        emit TaskCreated(taskId, covenantId, creator);
    }

    /// @notice Emits a TaskAssigned event
    function emitTaskAssigned(uint256 taskId, address assignee) external {
        emit TaskAssigned(taskId, assignee);
    }

    /// @notice Emits a TaskSubmitted event
    function emitTaskSubmitted(uint256 taskId, bytes32 proofHash) external {
        emit TaskSubmitted(taskId, proofHash);
    }

    /// @notice Emits a TaskApproved event
    function emitTaskApproved(uint256 taskId, address approver) external {
        emit TaskApproved(taskId, approver);
    }

    /// @notice Emits a TaskRejected event
    function emitTaskRejected(uint256 taskId, address approver, string calldata reason) external {
        emit TaskRejected(taskId, approver, reason);
    }

    /// @notice Emits a ReputationStaked event
    function emitReputationStaked(address account, uint256 amount) external {
        emit ReputationStaked(account, amount);
    }

    /// @notice Emits a ReputationUnstaked event
    function emitReputationUnstaked(address account, uint256 amount) external {
        emit ReputationUnstaked(account, amount);
    }

    /// @notice Emits a ReputationUpdated event
    function emitReputationUpdated(address account, uint256 newScore) external {
        emit ReputationUpdated(account, newScore);
    }

    /// @notice Emits a ReputationDecayed event
    function emitReputationDecayed(address account, uint256 decayAmount) external {
        emit ReputationDecayed(account, decayAmount);
    }

    /// @notice Emits a DisputeOpened event
    function emitDisputeOpened(uint256 disputeId, uint256 taskId, address initiator) external {
        emit DisputeOpened(disputeId, taskId, initiator);
    }

    /// @notice Emits a DisputeEvidenceSubmitted event
    function emitDisputeEvidenceSubmitted(uint256 disputeId, address submitter, bytes32 evidenceHash) external {
        emit DisputeEvidenceSubmitted(disputeId, submitter, evidenceHash);
    }

    /// @notice Emits a DisputeVoteCast event
    function emitDisputeVoteCast(uint256 disputeId, address voter, uint8 vote) external {
        emit DisputeVoteCast(disputeId, voter, vote);
    }

    /// @notice Emits a DisputeResolved event
    function emitDisputeResolved(uint256 disputeId, uint8 outcome) external {
        emit DisputeResolved(disputeId, outcome);
    }

    /// @notice Emits a DisputeAppealed event
    function emitDisputeAppealed(uint256 disputeId, address appellant) external {
        emit DisputeAppealed(disputeId, appellant);
    }

    /// @notice Emits a ProposalCreated event
    function emitProposalCreated(uint256 proposalId, address proposer, string calldata description) external {
        emit ProposalCreated(proposalId, proposer, description);
    }

    /// @notice Emits a VoteCast event
    function emitVoteCast(uint256 proposalId, address voter, uint8 support, uint256 votes) external {
        emit VoteCast(proposalId, voter, support, votes);
    }

    /// @notice Emits a ProposalExecuted event
    function emitProposalExecuted(uint256 proposalId) external {
        emit ProposalExecuted(proposalId);
    }

    /// @notice Emits a ProposalCanceled event
    function emitProposalCanceled(uint256 proposalId) external {
        emit ProposalCanceled(proposalId);
    }

    /// @notice Emits a MessageSent event
    function emitMessageSent(uint256 messageId, uint16 targetChain, address targetContract) external {
        emit MessageSent(messageId, targetChain, targetContract);
    }

    /// @notice Emits a MessageReceived event
    function emitMessageReceived(uint256 messageId, uint16 sourceChain, address sourceContract) external {
        emit MessageReceived(messageId, sourceChain, sourceContract);
    }

    /// @notice Emits an EmergencyPaused event
    function emitEmergencyPaused(address pauser) external {
        emit EmergencyPaused(pauser);
    }

    /// @notice Emits an EmergencyUnpaused event
    function emitEmergencyUnpaused(address unpauser) external {
        emit EmergencyUnpaused(unpauser);
    }

    /// @notice Emits an UpgradeAuthorized event
    function emitUpgradeAuthorized(address implementation, uint256 effectiveTime) external {
        emit UpgradeAuthorized(implementation, effectiveTime);
    }
}