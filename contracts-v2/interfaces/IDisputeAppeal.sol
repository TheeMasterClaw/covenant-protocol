// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDisputeAppeal
 * @notice Interface for the DisputeAppeal contract
 */
interface IDisputeAppeal {
    struct Appeal {
        uint256 appealId;
        uint256 disputeId;
        address appellant;
        uint256 bond;
        uint256 appealedAt;
        uint8 status; // 0: Pending, 1: Upheld, 2: Overturned, 3: Rejected
    }

    event AppealFiled(uint256 indexed appealId, uint256 indexed disputeId, address indexed appellant, uint256 bond);
    event AppealResolved(uint256 indexed appealId, uint8 status);

    error AppealNotAllowed();
    error AppealPeriodExpired();
    error InsufficientAppealBond();
    error AppealAlreadyResolved();

    function fileAppeal(uint256 disputeId) external payable returns (uint256 appealId);
    function resolveAppeal(uint256 appealId, uint8 status) external;
    function getAppeal(uint256 appealId) external view returns (Appeal memory);
    function getAppealsByDispute(uint256 disputeId) external view returns (uint256[] memory);
    function getAppealPeriod() external view returns (uint256);
    function getAppealBond() external view returns (uint256);
}
