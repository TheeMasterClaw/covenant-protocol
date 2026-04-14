// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRewardDistributor} from "../interfaces/IRewardDistributor.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RewardDistributor
 * @notice Reward distribution contract for protocol incentives
 */
contract RewardDistributor is IRewardDistributor, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => Distribution) public distributions;
    mapping(address => mapping(address => uint256)) public userClaimed;
    mapping(address => uint256) public totalParticipants;

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IRewardDistributor
    function addRewards(address token, uint256 amount, uint256 duration) external onlyOwner nonReentrant {
        if (duration == 0) revert InvalidDuration();
        if (distributions[token].amount != 0) revert RewardsAlreadyAdded();

        distributions[token] = Distribution({
            token: token,
            amount: amount,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            claimed: 0
        });

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit RewardsAdded(token, amount, duration);
    }

    /// @inheritdoc IRewardDistributor
    function claimRewards(address token) external nonReentrant returns (uint256 amount) {
        Distribution storage dist = distributions[token];
        if (dist.amount == 0) revert NoRewardsAvailable();
        if (block.timestamp < dist.startTime) revert NoRewardsAvailable();

        uint256 userShare = _calculateUserShare(msg.sender, token);
        uint256 alreadyClaimed = userClaimed[token][msg.sender];
        amount = userShare > alreadyClaimed ? userShare - alreadyClaimed : 0;

        if (amount == 0) revert NoRewardsAvailable();

        userClaimed[token][msg.sender] += amount;
        dist.claimed += amount;

        IERC20(token).safeTransfer(msg.sender, amount);

        emit RewardsClaimed(msg.sender, token, amount);
    }

    /// @inheritdoc IRewardDistributor
    function getClaimableRewards(address account, address token) external view returns (uint256) {
        Distribution storage dist = distributions[token];
        if (dist.amount == 0 || block.timestamp < dist.startTime) return 0;

        uint256 userShare = _calculateUserShare(account, token);
        uint256 alreadyClaimed = userClaimed[token][account];
        return userShare > alreadyClaimed ? userShare - alreadyClaimed : 0;
    }

    /// @inheritdoc IRewardDistributor
    function getDistribution(address token) external view returns (Distribution memory) {
        return distributions[token];
    }

    function _calculateUserShare(address account, address token) internal view returns (uint256) {
        // Simplified: equal share for all registered participants
        // In production, this would integrate with staking/activity tracking
        account;
        Distribution storage dist = distributions[token];
        uint256 participants = totalParticipants[token] > 0 ? totalParticipants[token] : 1;
        return dist.amount / participants;
    }

    function registerParticipant(address token) external {
        totalParticipants[token]++;
    }
}