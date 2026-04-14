// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDisputeAppeal} from "../interfaces/IDisputeAppeal.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DisputeAppeal
 * @notice Appeals process for disputes
 */
contract DisputeAppeal is IDisputeAppeal, Ownable, ReentrancyGuard {
    uint256 private _nextAppealId;
    mapping(uint256 => Appeal) public appeals;
    mapping(uint256 => uint256[]) public appealsByDispute;
    mapping(uint256 => uint256) public disputeResolvedAt;
    mapping(uint256 => bool) public disputeAppealable;

    uint256 public appealPeriod = 2 days;
    uint256 public appealBond = 0.5 ether;

    constructor() Ownable(msg.sender) {
        _nextAppealId = 1;
    }

    function setDisputeResolved(uint256 disputeId) external onlyOwner {
        disputeResolvedAt[disputeId] = block.timestamp;
        disputeAppealable[disputeId] = true;
    }

    /// @inheritdoc IDisputeAppeal
    function fileAppeal(uint256 disputeId) external payable nonReentrant returns (uint256 appealId) {
        if (!disputeAppealable[disputeId]) revert AppealNotAllowed();
        if (block.timestamp > disputeResolvedAt[disputeId] + appealPeriod) revert AppealPeriodExpired();
        if (msg.value < appealBond) revert InsufficientAppealBond();

        appealId = _nextAppealId++;
        appeals[appealId] = Appeal({
            appealId: appealId,
            disputeId: disputeId,
            appellant: msg.sender,
            bond: msg.value,
            appealedAt: block.timestamp,
            status: 0
        });
        appealsByDispute[disputeId].push(appealId);

        emit AppealFiled(appealId, disputeId, msg.sender, msg.value);
    }

    /// @inheritdoc IDisputeAppeal
    function resolveAppeal(uint256 appealId, uint8 status) external onlyOwner {
        Appeal storage appeal = appeals[appealId];
        if (appeal.appealId == 0) revert AppealNotAllowed();
        if (appeal.status != 0) revert AppealAlreadyResolved();
        if (status == 0 || status > 3) revert AppealNotAllowed();

        appeal.status = status;

        // Refund bond on upheld or overturned, keep on rejected
        if (status != 3) {
            (bool success, ) = payable(appeal.appellant).call{value: appeal.bond}("");
            if (!success) revert AppealNotAllowed();
        }

        emit AppealResolved(appealId, status);
    }

    /// @inheritdoc IDisputeAppeal
    function getAppeal(uint256 appealId) external view returns (Appeal memory) {
        return appeals[appealId];
    }

    /// @inheritdoc IDisputeAppeal
    function getAppealsByDispute(uint256 disputeId) external view returns (uint256[] memory) {
        return appealsByDispute[disputeId];
    }

    /// @inheritdoc IDisputeAppeal
    function getAppealPeriod() external view returns (uint256) {
        return appealPeriod;
    }

    /// @inheritdoc IDisputeAppeal
    function getAppealBond() external view returns (uint256) {
        return appealBond;
    }

    function setAppealPeriod(uint256 period) external onlyOwner {
        appealPeriod = period;
    }

    function setAppealBond(uint256 bond) external onlyOwner {
        appealBond = bond;
    }

    receive() external payable {}
}