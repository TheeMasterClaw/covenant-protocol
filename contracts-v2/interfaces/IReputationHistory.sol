// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReputationHistory
 * @notice Interface for the ReputationHistory contract
 */
interface IReputationHistory {
    struct ReputationSnapshot {
        uint256 timestamp;
        uint256 score;
        bytes32 context;
    }

    event SnapshotRecorded(address indexed account, uint256 score, bytes32 context);

    error NoHistoryFound();

    function recordSnapshot(address account, uint256 score, bytes32 context) external;
    function getHistory(address account) external view returns (ReputationSnapshot[] memory);
    function getHistoryRange(address account, uint256 start, uint256 end) external view returns (ReputationSnapshot[] memory);
    function getLatestSnapshot(address account) external view returns (ReputationSnapshot memory);
    function getScoreAtTime(address account, uint256 timestamp) external view returns (uint256);
}
