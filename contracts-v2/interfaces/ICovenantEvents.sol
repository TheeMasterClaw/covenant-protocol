// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantEvents
 * @notice Standardized event interface for the COVENANT protocol
 */
interface ICovenantEvents {
    // Covenant lifecycle events
    event CovenantCreated(uint256 indexed covenantId, address indexed creator, address indexed proxy);
    event CovenantUpdated(uint256 indexed covenantId, bytes32 indexed updateType, bytes data);
    event CovenantActivated(uint256 indexed covenantId, uint256 timestamp);
    event CovenantPaused(uint256 indexed covenantId, uint256 timestamp);
    event CovenantResolved(uint256 indexed covenantId, uint256 timestamp);
    event CovenantTerminated(uint256 indexed covenantId, uint256 timestamp);

    // Task lifecycle events
    event TaskCreated(uint256 indexed taskId, uint256 indexed covenantId, address indexed creator);
    event TaskAssigned(uint256 indexed taskId, address indexed assignee);
    event TaskSubmitted(uint256 indexed taskId, bytes32 proofHash);
    event TaskApproved(uint256 indexed taskId, address indexed approver);
    event TaskRejected(uint256 indexed taskId, address indexed approver, string reason);

    // Reputation events
    event ReputationStaked(address indexed account, uint256 amount);
    event ReputationUnstaked(address indexed account, uint256 amount);
    event ReputationUpdated(address indexed account, uint256 newScore);
    event ReputationDecayed(address indexed account, uint256 decayAmount);

    // Dispute events
    event DisputeOpened(uint256 indexed disputeId, uint256 indexed taskId, address indexed initiator);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, bytes32 evidenceHash);
    event DisputeVoteCast(uint256 indexed disputeId, address indexed voter, uint8 vote);
    event DisputeResolved(uint256 indexed disputeId, uint8 outcome);
    event DisputeAppealed(uint256 indexed disputeId, address indexed appellant);

    // Governance events
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint8 support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    // Cross-chain events
    event MessageSent(uint256 indexed messageId, uint16 indexed targetChain, address targetContract);
    event MessageReceived(uint256 indexed messageId, uint16 indexed sourceChain, address sourceContract);

    // Security events
    event EmergencyPaused(address indexed pauser);
    event EmergencyUnpaused(address indexed unpauser);
    event UpgradeAuthorized(address indexed implementation, uint256 effectiveTime);
}
