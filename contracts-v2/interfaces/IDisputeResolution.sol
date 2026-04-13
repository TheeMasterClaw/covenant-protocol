// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDisputeResolution
 * @notice Interface for the DisputeResolution contract
 */
interface IDisputeResolution {
    enum ResolutionOutcome {
        Pending,
        InitiatorWins,
        RespondentWins,
        Split,
        Dismissed
    }

    event DisputeResolved(uint256 indexed disputeId, ResolutionOutcome outcome, bytes32 detailsHash);
    event ResolutionExecuted(uint256 indexed disputeId);

    error DisputeNotFound();
    error DisputeAlreadyResolved();
    error InvalidOutcome();
    error ExecutionFailed();

    function resolveDispute(uint256 disputeId, ResolutionOutcome outcome, bytes32 detailsHash) external;
    function executeResolution(uint256 disputeId) external;
    function getResolution(uint256 disputeId) external view returns (ResolutionOutcome outcome, bytes32 detailsHash, bool executed);
    function canAppeal(uint256 disputeId) external view returns (bool);
}
