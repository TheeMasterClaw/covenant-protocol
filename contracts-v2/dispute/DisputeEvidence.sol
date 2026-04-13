// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDisputeEvidence} from "../interfaces/IDisputeEvidence.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DisputeEvidence
 * @notice Evidence management for disputes
 */
contract DisputeEvidence is IDisputeEvidence, Ownable {
    uint256 private _nextEvidenceId;
    mapping(uint256 => Evidence) public evidenceRecords;
    mapping(uint256 => uint256[]) public evidenceByDispute;
    mapping(uint256 => uint256) public evidencePeriodEnd;
    uint256 public evidencePeriod = 3 days;

    constructor() Ownable(msg.sender) {
        _nextEvidenceId = 1;
    }

    /// @inheritdoc IDisputeEvidence
    function submitEvidence(
        uint256 disputeId,
        bytes32 evidenceHash,
        bytes32 metadataHash
    ) external returns (uint256 evidenceId) {
        if (evidenceHash == bytes32(0)) revert InvalidEvidence();
        if (block.timestamp > evidencePeriodEnd[disputeId] && evidencePeriodEnd[disputeId] != 0) {
            revert EvidencePeriodClosed();
        }
        if (evidencePeriodEnd[disputeId] == 0) {
            evidencePeriodEnd[disputeId] = block.timestamp + evidencePeriod;
        }

        evidenceId = _nextEvidenceId++;
        evidenceRecords[evidenceId] = Evidence({
            evidenceId: evidenceId,
            disputeId: disputeId,
            submitter: msg.sender,
            evidenceHash: evidenceHash,
            metadataHash: metadataHash,
            submittedAt: block.timestamp
        });

        evidenceByDispute[disputeId].push(evidenceId);

        emit EvidenceSubmitted(evidenceId, disputeId, msg.sender, evidenceHash);
    }

    /// @inheritdoc IDisputeEvidence
    function getEvidence(uint256 evidenceId) external view returns (Evidence memory) {
        return evidenceRecords[evidenceId];
    }

    /// @inheritdoc IDisputeEvidence
    function getEvidenceByDispute(uint256 disputeId) external view returns (uint256[] memory) {
        return evidenceByDispute[disputeId];
    }

    /// @inheritdoc IDisputeEvidence
    function getEvidencePeriodEnd(uint256 disputeId) external view returns (uint256) {
        return evidencePeriodEnd[disputeId];
    }

    function setEvidencePeriod(uint256 period) external onlyOwner {
        evidencePeriod = period;
    }
}
