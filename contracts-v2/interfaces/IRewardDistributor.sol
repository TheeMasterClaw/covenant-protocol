// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IRewardDistributor
 * @notice Interface for the RewardDistributor contract
 */
interface IRewardDistributor {
    struct Distribution {
        address token;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 claimed;
    }

    event RewardsAdded(address indexed token, uint256 amount, uint256 duration);
    event RewardsClaimed(address indexed account, address indexed token, uint256 amount);

    error NoRewardsAvailable();
    error RewardsAlreadyAdded();
    error InvalidDuration();

    function addRewards(address token, uint256 amount, uint256 duration) external;
    function claimRewards(address token) external returns (uint256 amount);
    function getClaimableRewards(address account, address token) external view returns (uint256);
    function getDistribution(address token) external view returns (Distribution memory);
}
