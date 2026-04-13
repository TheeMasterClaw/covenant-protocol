// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReputationDecay
 * @notice Interface for the ReputationDecay contract
 */
interface IReputationDecay {
    event DecayApplied(address indexed account, uint256 decayAmount, uint256 newScore);
    event DecayRateUpdated(uint256 newRate);
    event DecayIntervalUpdated(uint256 newInterval);

    error InvalidDecayRate();
    error InvalidInterval();

    function applyDecay(address account) external returns (uint256 decayedAmount);
    function calculateDecay(address account) external view returns (uint256);
    function setDecayRate(uint256 rate) external; // Rate in basis points per interval
    function setDecayInterval(uint256 interval) external;
    function getDecayRate() external view returns (uint256);
    function getDecayInterval() external view returns (uint256);
    function getLastDecayTime(address account) external view returns (uint256);
}
