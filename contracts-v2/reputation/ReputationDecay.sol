// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationDecay} from "../interfaces/IReputationDecay.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReputationDecay
 * @notice Time-based reputation decay
 */
contract ReputationDecay is IReputationDecay, Ownable {
    // Rate in basis points (1% = 100) per interval
    uint256 public decayRate = 100; // 1% per interval default
    uint256 public decayInterval = 30 days;
    
    mapping(address => uint256) public lastDecayTime;
    mapping(address => uint256) public currentScore;

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IReputationDecay
    function applyDecay(address account) external returns (uint256 decayedAmount) {
        decayedAmount = calculateDecay(account);
        if (decayedAmount > 0) {
            currentScore[account] -= decayedAmount;
            lastDecayTime[account] = block.timestamp;
            emit DecayApplied(account, decayedAmount, currentScore[account]);
        }
    }

    /// @inheritdoc IReputationDecay
    function calculateDecay(address account) public view returns (uint256) {
        uint256 lastDecay = lastDecayTime[account];
        if (lastDecay == 0) return 0;

        uint256 timeElapsed = block.timestamp - lastDecay;
        uint256 intervals = timeElapsed / decayInterval;
        if (intervals == 0) return 0;

        uint256 score = currentScore[account];
        uint256 decayed = 0;
        for (uint256 i = 0; i < intervals; ) {
            uint256 decay = (score * decayRate) / 10000;
            score -= decay;
            decayed += decay;
            unchecked {
                ++i;
            }
        }
        return decayed;
    }

    /// @inheritdoc IReputationDecay
    function setDecayRate(uint256 rate) external onlyOwner {
        if (rate > 5000) revert InvalidDecayRate(); // Max 50%
        decayRate = rate;
        emit DecayRateUpdated(rate);
    }

    /// @inheritdoc IReputationDecay
    function setDecayInterval(uint256 interval) external onlyOwner {
        if (interval == 0) revert InvalidInterval();
        decayInterval = interval;
        emit DecayIntervalUpdated(interval);
    }

    /// @inheritdoc IReputationDecay
    function getDecayRate() external view returns (uint256) {
        return decayRate;
    }

    /// @inheritdoc IReputationDecay
    function getDecayInterval() external view returns (uint256) {
        return decayInterval;
    }

    /// @inheritdoc IReputationDecay
    function getLastDecayTime(address account) external view returns (uint256) {
        return lastDecayTime[account];
    }

    function setScore(address account, uint256 score) external onlyOwner {
        currentScore[account] = score;
        if (lastDecayTime[account] == 0) {
            lastDecayTime[account] = block.timestamp;
        }
    }
}
