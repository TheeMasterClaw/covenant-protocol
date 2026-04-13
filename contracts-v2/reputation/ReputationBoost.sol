// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IReputationBoost} from "../interfaces/IReputationBoost.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ReputationBoost
 * @notice Achievement-based reputation boosts
 */
contract ReputationBoost is IReputationBoost, Ownable {
    mapping(address => Boost[]) public boosts;
    mapping(address => bool) public authorizedGranters;

    modifier onlyGranter() {
        if (!authorizedGranters[msg.sender]) revert UnauthorizedGrant();
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IReputationBoost
    function grantBoost(
        address account,
        uint256 amount,
        bytes32 reason,
        uint256 duration
    ) external onlyGranter returns (uint256 boostId) {
        if (amount == 0) revert InvalidBoostAmount();
        
        boostId = boosts[account].length;
        boosts[account].push(Boost({
            amount: amount,
            expiresAt: block.timestamp + duration,
            reason: reason,
            active: true
        }));

        emit BoostGranted(account, amount, reason, block.timestamp + duration);
    }

    /// @inheritdoc IReputationBoost
    function revokeBoost(address account, uint256 boostId) external onlyOwner {
        Boost storage boost = boosts[account][boostId];
        if (!boost.active) revert BoostNotFound();
        boost.active = false;
        emit BoostRevoked(account, boostId);
    }

    /// @inheritdoc IReputationBoost
    function getActiveBoosts(address account) external view returns (Boost[] memory) {
        Boost[] storage all = boosts[account];
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < all.length; ) {
            if (all[i].active && all[i].expiresAt > block.timestamp) {
                activeCount++;
            }
            unchecked {
                ++i;
            }
        }

        Boost[] memory active = new Boost[](activeCount);
        uint256 j = 0;
        for (uint256 i = 0; i < all.length; ) {
            if (all[i].active && all[i].expiresAt > block.timestamp) {
                active[j] = all[i];
                j++;
            }
            unchecked {
                ++i;
            }
        }
        return active;
    }

    /// @inheritdoc IReputationBoost
    function getTotalBoost(address account) external view returns (uint256 total) {
        Boost[] storage all = boosts[account];
        for (uint256 i = 0; i < all.length; ) {
            if (all[i].active && all[i].expiresAt > block.timestamp) {
                total += all[i].amount;
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IReputationBoost
    function isBoostActive(address account, uint256 boostId) external view returns (bool) {
        if (boostId >= boosts[account].length) return false;
        Boost storage boost = boosts[account][boostId];
        return boost.active && boost.expiresAt > block.timestamp;
    }

    function authorizeGranter(address granter) external onlyOwner {
        authorizedGranters[granter] = true;
    }

    function revokeGranter(address granter) external onlyOwner {
        authorizedGranters[granter] = false;
    }
}
