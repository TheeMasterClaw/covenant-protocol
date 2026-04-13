// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IStakingPool
 * @notice Interface for the StakingPool contract
 */
interface IStakingPool {
    struct Stake {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lockEnd;
        uint256 multiplier;
    }

    event Staked(address indexed account, uint256 amount, uint256 lockDuration);
    event Unstaked(address indexed account, uint256 amount);
    event RewardsClaimed(address indexed account, uint256 amount);
    event PoolUpdated(uint256 accRewardPerShare);

    error InsufficientStake();
    error StakeLocked();
    error ZeroAmount();
    error PoolEmpty();

    function stake(uint256 amount, uint256 lockDuration) external;
    function unstake(uint256 amount) external;
    function claimRewards() external returns (uint256);
    function updatePool() external;
    function getStake(address account) external view returns (Stake memory);
    function pendingRewards(address account) external view returns (uint256);
    function totalStaked() external view returns (uint256);
    function getRewardToken() external view returns (address);
    function getStakeToken() external view returns (address);
}
