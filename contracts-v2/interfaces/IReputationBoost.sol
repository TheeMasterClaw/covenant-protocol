// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IReputationBoost
 * @notice Interface for the ReputationBoost contract
 */
interface IReputationBoost {
    struct Boost {
        uint256 amount;
        uint256 expiresAt;
        bytes32 reason;
        bool active;
    }

    event BoostGranted(address indexed account, uint256 amount, bytes32 reason, uint256 expiresAt);
    event BoostRevoked(address indexed account, uint256 boostId);
    event BoostExpired(address indexed account, uint256 boostId);

    error BoostNotFound();
    error BoostExpiredError();
    error UnauthorizedGrant();
    error InvalidBoostAmount();

    function grantBoost(address account, uint256 amount, bytes32 reason, uint256 duration) external returns (uint256 boostId);
    function revokeBoost(address account, uint256 boostId) external;
    function getActiveBoosts(address account) external view returns (Boost[] memory);
    function getTotalBoost(address account) external view returns (uint256);
    function isBoostActive(address account, uint256 boostId) external view returns (bool);
}
