// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDisputeDAO
 * @notice Interface for the DisputeDAO contract
 */
interface IDisputeDAO {
    struct DisputeParams {
        uint256 minStake;
        uint256 votingPeriod;
        uint256 quorum;
        uint256 appealThreshold;
    }

    event ParamsUpdated(bytes32 paramName, uint256 oldValue, uint256 newValue);
    event TreasuryWithdrawal(address indexed token, address indexed recipient, uint256 amount);

    error InvalidParam();
    error UnauthorizedUpdate();

    function updateParams(DisputeParams calldata params) external;
    function getParams() external view returns (DisputeParams memory);
    function withdrawTreasury(address token, address recipient, uint256 amount) external;
}
