// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStakingPool} from "../interfaces/IStakingPool.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title StakingPool
 * @notice Staking pool with lock multipliers and reward distribution
 */
contract StakingPool is IStakingPool, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    IERC20 public stakeToken;
    IERC20 public rewardToken;

    uint256 public accRewardPerShare;
    uint256 public rewardPerSecond;
    uint256 public lastUpdateTime;
    uint256 public totalStakedAmount;
    uint256 public rewardEndTime;

    mapping(address => Stake) public stakes;

    constructor(address _stakeToken, address _rewardToken) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        lastUpdateTime = block.timestamp;
    }

    /// @inheritdoc IStakingPool
    function stake(uint256 amount, uint256 lockDuration) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        updatePool();

        Stake storage userStake = stakes[msg.sender];
        if (userStake.amount > 0) {
            uint256 pending = _pendingRewards(msg.sender);
            if (pending > 0) {
                rewardToken.safeTransfer(msg.sender, pending);
                emit RewardsClaimed(msg.sender, pending);
            }
        }

        uint256 multiplier = 10000; // base 1x
        if (lockDuration >= 365 days) multiplier = 20000; // 2x
        else if (lockDuration >= 180 days) multiplier = 15000; // 1.5x
        else if (lockDuration >= 90 days) multiplier = 12500; // 1.25x

        uint256 effectiveAmount = (amount * multiplier) / 10000;

        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        userStake.amount += effectiveAmount;
        userStake.rewardDebt = (userStake.amount * accRewardPerShare) / 1e12;
        if (userStake.lockEnd < block.timestamp + lockDuration) {
            userStake.lockEnd = block.timestamp + lockDuration;
        }
        userStake.multiplier = multiplier;

        totalStakedAmount += effectiveAmount;

        emit Staked(msg.sender, amount, lockDuration);
    }

    /// @inheritdoc IStakingPool
    function unstake(uint256 amount) external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        if (userStake.amount < amount) revert InsufficientStake();
        if (block.timestamp < userStake.lockEnd) revert StakeLocked();

        updatePool();

        uint256 pending = _pendingRewards(msg.sender);
        if (pending > 0) {
            rewardToken.safeTransfer(msg.sender, pending);
            emit RewardsClaimed(msg.sender, pending);
        }

        userStake.amount -= amount;
        userStake.rewardDebt = (userStake.amount * accRewardPerShare) / 1e12;
        totalStakedAmount -= amount;

        uint256 rawAmount = (amount * 10000) / userStake.multiplier;
        stakeToken.safeTransfer(msg.sender, rawAmount);

        emit Unstaked(msg.sender, rawAmount);
    }

    /// @inheritdoc IStakingPool
    function claimRewards() external nonReentrant returns (uint256) {
        updatePool();
        uint256 pending = _pendingRewards(msg.sender);
        if (pending == 0) revert PoolEmpty();

        stakes[msg.sender].rewardDebt = (stakes[msg.sender].amount * accRewardPerShare) / 1e12;
        rewardToken.safeTransfer(msg.sender, pending);

        emit RewardsClaimed(msg.sender, pending);
        return pending;
    }

    /// @inheritdoc IStakingPool
    function updatePool() public {
        if (block.timestamp <= lastUpdateTime) return;
        if (totalStakedAmount == 0) {
            lastUpdateTime = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp - lastUpdateTime;
        if (block.timestamp > rewardEndTime && rewardEndTime > lastUpdateTime) {
            timeElapsed = rewardEndTime - lastUpdateTime;
        }

        uint256 reward = rewardPerSecond * timeElapsed;
        accRewardPerShare += (reward * 1e12) / totalStakedAmount;
        lastUpdateTime = block.timestamp;

        emit PoolUpdated(accRewardPerShare);
    }

    /// @inheritdoc IStakingPool
    function getStake(address account) external view returns (Stake memory) {
        return stakes[account];
    }

    /// @inheritdoc IStakingPool
    function pendingRewards(address account) external view returns (uint256) {
        return _pendingRewards(account);
    }

    function _pendingRewards(address account) internal view returns (uint256) {
        Stake storage userStake = stakes[account];
        uint256 _accRewardPerShare = accRewardPerShare;

        if (block.timestamp > lastUpdateTime && totalStakedAmount != 0) {
            uint256 timeElapsed = block.timestamp - lastUpdateTime;
            if (block.timestamp > rewardEndTime && rewardEndTime > lastUpdateTime) {
                timeElapsed = rewardEndTime - lastUpdateTime;
            }
            uint256 reward = rewardPerSecond * timeElapsed;
            _accRewardPerShare += (reward * 1e12) / totalStakedAmount;
        }

        return (userStake.amount * _accRewardPerShare) / 1e12 - userStake.rewardDebt;
    }

    /// @inheritdoc IStakingPool
    function totalStaked() external view returns (uint256) {
        return totalStakedAmount;
    }

    /// @inheritdoc IStakingPool
    function getRewardToken() external view returns (address) {
        return address(rewardToken);
    }

    /// @inheritdoc IStakingPool
    function getStakeToken() external view returns (address) {
        return address(stakeToken);
    }

    function setRewardRate(uint256 _rewardPerSecond, uint256 duration) external onlyOwner {
        updatePool();
        rewardPerSecond = _rewardPerSecond;
        rewardEndTime = block.timestamp + duration;
    }

    function depositRewards(uint256 amount) external onlyOwner {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
    }
}