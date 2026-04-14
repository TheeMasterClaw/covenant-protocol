// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationStake} from "../interfaces/IReputationStake.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ReputationStake
 * @notice Staking mechanics for reputation system
 */
contract ReputationStake is IReputationStake, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;
    mapping(address => StakeInfo) public stakes;
    uint256 public totalStakedAmount;

    constructor(address _stakeToken) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeToken);
    }

    /// @inheritdoc IReputationStake
    function stake(uint256 amount, uint256 lockDuration) external nonReentrant {
        if (amount == 0) revert InvalidAmount();

        StakeInfo storage info = stakes[msg.sender];
        uint256 unlockTime = block.timestamp + lockDuration;

        if (info.amount > 0) {
            // Extend lock if new lock is longer
            if (unlockTime > info.unlockTime) {
                info.unlockTime = unlockTime;
            }
            info.amount += amount;
        } else {
            stakes[msg.sender] = StakeInfo({
                amount: amount,
                stakedAt: block.timestamp,
                unlockTime: unlockTime,
                locked: lockDuration > 0
            });
        }

        totalStakedAmount += amount;
        stakeToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, unlockTime);
    }

    /// @inheritdoc IReputationStake
    function unstake(uint256 amount) external nonReentrant {
        StakeInfo storage info = stakes[msg.sender];
        if (info.amount < amount) revert InsufficientStake();
        if (block.timestamp < info.unlockTime) revert StakeLocked();

        info.amount -= amount;
        totalStakedAmount -= amount;

        stakeToken.safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /// @inheritdoc IReputationStake
    function slash(address account, uint256 amount, bytes32 reason) external onlyOwner {
        StakeInfo storage info = stakes[account];
        if (info.amount < amount) revert InsufficientStake();

        info.amount -= amount;
        totalStakedAmount -= amount;

        stakeToken.safeTransfer(owner(), amount);

        emit Slashed(account, amount, reason);
    }

    /// @inheritdoc IReputationStake
    function getStakeInfo(address account) external view returns (StakeInfo memory) {
        return stakes[account];
    }

    /// @inheritdoc IReputationStake
    function totalStaked() external view returns (uint256) {
        return totalStakedAmount;
    }

    /// @inheritdoc IReputationStake
    function getStakeToken() external view returns (address) {
        return address(stakeToken);
    }
}