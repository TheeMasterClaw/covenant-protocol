// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITaskEscrow} from "../interfaces/ITaskEscrow.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TaskEscrow
 * @notice Escrow management for task payments
 */
contract TaskEscrow is ITaskEscrow, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private _nextEscrowId;
    mapping(uint256 => Escrow) public escrows;
    mapping(uint256 => uint256) public escrowByTask;

    constructor() Ownable(msg.sender) {
        _nextEscrowId = 1;
    }

    /// @inheritdoc ITaskEscrow
    function createEscrow(uint256 taskId, address token, uint256 amount, address payee) external returns (uint256 escrowId) {
        if (amount == 0) revert InvalidToken();
        if (payee == address(0)) revert InvalidToken();
        if (escrowByTask[taskId] != 0) revert EscrowAlreadyFunded();

        escrowId = _nextEscrowId++;
        escrows[escrowId] = Escrow({
            taskId: taskId,
            amount: amount,
            token: token,
            payer: msg.sender,
            payee: payee,
            state: 0
        });
        escrowByTask[taskId] = escrowId;

        emit EscrowCreated(escrowId, taskId, amount);
    }

    /// @inheritdoc ITaskEscrow
    function fundEscrow(uint256 escrowId) external payable nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.taskId == 0) revert EscrowNotFound();
        if (escrow.state != 0) revert EscrowAlreadyFunded();
        if (msg.sender != escrow.payer) revert UnauthorizedRelease();

        if (escrow.token == address(0)) {
            if (msg.value != escrow.amount) revert InsufficientFunds();
        } else {
            IERC20(escrow.token).safeTransferFrom(msg.sender, address(this), escrow.amount);
        }

        escrow.state = 1;
        emit EscrowFunded(escrowId, escrow.amount);
    }

    /// @inheritdoc ITaskEscrow
    function releaseEscrow(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.taskId == 0) revert EscrowNotFound();
        if (escrow.state != 1) revert EscrowAlreadyReleased();
        if (msg.sender != escrow.payer) revert UnauthorizedRelease();

        escrow.state = 2;

        if (escrow.token == address(0)) {
            (bool success, ) = payable(escrow.payee).call{value: escrow.amount}("");
            if (!success) revert InvalidToken();
        } else {
            IERC20(escrow.token).safeTransfer(escrow.payee, escrow.amount);
        }

        emit EscrowReleased(escrowId, escrow.payee, escrow.amount);
    }

    /// @inheritdoc ITaskEscrow
    function refundEscrow(uint256 escrowId) external nonReentrant {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.taskId == 0) revert EscrowNotFound();
        if (escrow.state != 1) revert EscrowAlreadyRefunded();
        if (msg.sender != owner() && msg.sender != escrow.payer) revert UnauthorizedRelease();

        escrow.state = 3;

        if (escrow.token == address(0)) {
            (bool success, ) = payable(escrow.payer).call{value: escrow.amount}("");
            if (!success) revert InvalidToken();
        } else {
            IERC20(escrow.token).safeTransfer(escrow.payer, escrow.amount);
        }

        emit EscrowRefunded(escrowId, escrow.payer, escrow.amount);
    }

    /// @inheritdoc ITaskEscrow
    function disputeEscrow(uint256 escrowId) external {
        Escrow storage escrow = escrows[escrowId];
        if (escrow.taskId == 0) revert EscrowNotFound();
        if (escrow.state != 1) revert EscrowAlreadyReleased();
        if (msg.sender != escrow.payer && msg.sender != escrow.payee) revert UnauthorizedRelease();

        escrow.state = 4;
        emit EscrowDisputed(escrowId);
    }

    /// @inheritdoc ITaskEscrow
    function getEscrow(uint256 escrowId) external view returns (Escrow memory) {
        return escrows[escrowId];
    }

    /// @inheritdoc ITaskEscrow
    function getEscrowByTask(uint256 taskId) external view returns (uint256) {
        return escrowByTask[taskId];
    }

    receive() external payable {}
}