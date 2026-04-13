// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReputationStake
 * @notice Interface for the ReputationStake contract
 */
interface IReputationStake {
    struct StakeInfo {
        uint256 amount;
        uint256 stakedAt;
        uint256 unlockTime;
        bool locked;
    }

    event Staked(address indexed account, uint256 amount, uint256 unlockTime);
    event Unstaked(address indexed account, uint256 amount);
    event Slashed(address indexed account, uint256 amount, bytes32 reason);

    error InsufficientStake();
    error StakeLocked();
    error InvalidAmount();
    error TransferFailed();

    function stake(uint256 amount, uint256 lockDuration) external;
    function unstake(uint256 amount) external;
    function slash(address account, uint256 amount, bytes32 reason) external;
    function getStakeInfo(address account) external view returns (StakeInfo memory);
    function totalStaked() external view returns (uint256);
    function getStakeToken() external view returns (address);
}
