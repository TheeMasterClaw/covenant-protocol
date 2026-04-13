// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDisputeEvidence
 * @notice Interface for the DisputeEvidence contract
 */
interface IDisputeEvidence {
    struct Evidence {
        uint256 evidenceId;
        uint256 disputeId;
        address submitter;
        bytes32 evidenceHash;
        bytes32 metadataHash;
        uint256 submittedAt;
    }

    event EvidenceSubmitted(uint256 indexed evidenceId, uint256 indexed disputeId, address indexed submitter, bytes32 evidenceHash);

    error InvalidEvidence();
    error EvidencePeriodClosed();
    error UnauthorizedSubmitter();

    function submitEvidence(uint256 disputeId, bytes32 evidenceHash, bytes32 metadataHash) external returns (uint256 evidenceId);
    function getEvidence(uint256 evidenceId) external view returns (Evidence memory);
    function getEvidenceByDispute(uint256 disputeId) external view returns (uint256[] memory);
    function getEvidencePeriodEnd(uint256 disputeId) external view returns (uint256);
}
