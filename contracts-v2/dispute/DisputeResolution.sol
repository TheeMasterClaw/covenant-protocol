// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDisputeResolution} from "../interfaces/IDisputeResolution.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DisputeResolution
 * @notice Resolution execution for disputes
 */
contract DisputeResolution is IDisputeResolution, Ownable {
    struct Resolution {
        ResolutionOutcome outcome;
        bytes32 detailsHash;
        bool executed;
        uint256 resolvedAt;
    }

    mapping(uint256 => Resolution) public resolutions;
    mapping(uint256 => bool) public appealable;
    uint256 public appealWindow = 2 days;

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IDisputeResolution
    function resolveDispute(uint256 disputeId, ResolutionOutcome outcome, bytes32 detailsHash) external onlyOwner {
        if (resolutions[disputeId].resolvedAt != 0) revert DisputeAlreadyResolved();
        if (outcome == ResolutionOutcome.Pending) revert InvalidOutcome();

        resolutions[disputeId] = Resolution({
            outcome: outcome,
            detailsHash: detailsHash,
            executed: false,
            resolvedAt: block.timestamp
        });

        appealable[disputeId] = true;

        emit DisputeResolved(disputeId, outcome, detailsHash);
    }

    /// @inheritdoc IDisputeResolution
    function executeResolution(uint256 disputeId) external {
        Resolution storage resolution = resolutions[disputeId];
        if (resolution.resolvedAt == 0) revert DisputeNotFound();
        if (resolution.executed) revert DisputeAlreadyResolved();
        if (appealable[disputeId] && block.timestamp < resolution.resolvedAt + appealWindow) {
            revert InvalidOutcome();
        }

        resolution.executed = true;
        appealable[disputeId] = false;

        emit ResolutionExecuted(disputeId);
    }

    /// @inheritdoc IDisputeResolution
    function getResolution(uint256 disputeId) external view returns (ResolutionOutcome outcome, bytes32 detailsHash, bool executed) {
        Resolution storage r = resolutions[disputeId];
        return (r.outcome, r.detailsHash, r.executed);
    }

    /// @inheritdoc IDisputeResolution
    function canAppeal(uint256 disputeId) external view returns (bool) {
        Resolution storage r = resolutions[disputeId];
        if (r.resolvedAt == 0 || r.executed) return false;
        return appealable[disputeId] && block.timestamp < r.resolvedAt + appealWindow;
    }

    function setAppealWindow(uint256 window) external onlyOwner {
        appealWindow = window;
    }

    function waiveAppeal(uint256 disputeId) external onlyOwner {
        appealable[disputeId] = false;
    }
}
