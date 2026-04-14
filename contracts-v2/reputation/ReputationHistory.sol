// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationHistory} from "../interfaces/IReputationHistory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReputationHistory
 * @notice Historical tracking of reputation scores
 */
contract ReputationHistory is IReputationHistory, Ownable {
    mapping(address => ReputationSnapshot[]) private history;
    mapping(address => bool) public authorizedRecorders;

    modifier onlyRecorder() {
        require(authorizedRecorders[msg.sender], "Unauthorized recorder");
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IReputationHistory
    function recordSnapshot(address account, uint256 score, bytes32 context) external onlyRecorder {
        history[account].push(ReputationSnapshot({
            timestamp: block.timestamp,
            score: score,
            context: context
        }));

        emit SnapshotRecorded(account, score, context);
    }

    /// @inheritdoc IReputationHistory
    function getHistory(address account) external view returns (ReputationSnapshot[] memory) {
        return history[account];
    }

    /// @inheritdoc IReputationHistory
    function getHistoryRange(address account, uint256 start, uint256 end) external view returns (ReputationSnapshot[] memory) {
        ReputationSnapshot[] storage all = history[account];
        if (start >= all.length || end > all.length || start >= end) revert NoHistoryFound();

        uint256 len = end - start;
        ReputationSnapshot[] memory range = new ReputationSnapshot[](len);
        for (uint256 i = 0; i < len; ) {
            range[i] = all[start + i];
            unchecked {
                ++i;
            }
        }
        return range;
    }

    /// @inheritdoc IReputationHistory
    function getLatestSnapshot(address account) external view returns (ReputationSnapshot memory) {
        ReputationSnapshot[] storage all = history[account];
        if (all.length == 0) revert NoHistoryFound();
        return all[all.length - 1];
    }

    /// @inheritdoc IReputationHistory
    function getScoreAtTime(address account, uint256 timestamp) external view returns (uint256) {
        ReputationSnapshot[] storage all = history[account];
        if (all.length == 0) revert NoHistoryFound();

        // Binary search for the snapshot at or before timestamp
        uint256 left = 0;
        uint256 right = all.length;
        while (left < right) {
            uint256 mid = (left + right) / 2;
            if (all[mid].timestamp <= timestamp) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        if (left == 0) revert NoHistoryFound();
        return all[left - 1].score;
    }

    function authorizeRecorder(address recorder) external onlyOwner {
        authorizedRecorders[recorder] = true;
    }

    function revokeRecorder(address recorder) external onlyOwner {
        authorizedRecorders[recorder] = false;
    }
}