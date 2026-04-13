// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITaskEscrow
 * @notice Interface for the TaskEscrow contract
 */
interface ITaskEscrow {
    struct Escrow {
        uint256 taskId;
        uint256 amount;
        address token;
        address payer;
        address payee;
        uint8 state; // 0: Pending, 1: Funded, 2: Released, 3: Refunded, 4: Disputed
    }

    event EscrowCreated(uint256 indexed escrowId, uint256 indexed taskId, uint256 amount);
    event EscrowFunded(uint256 indexed escrowId, uint256 amount);
    event EscrowReleased(uint256 indexed escrowId, address indexed payee, uint256 amount);
    event EscrowRefunded(uint256 indexed escrowId, address indexed payer, uint256 amount);
    event EscrowDisputed(uint256 indexed escrowId);

    error EscrowNotFound();
    error EscrowAlreadyFunded();
    error EscrowAlreadyReleased();
    error EscrowAlreadyRefunded();
    error InsufficientFunds();
    error UnauthorizedRelease();
    error InvalidToken();

    function createEscrow(uint256 taskId, address token, uint256 amount, address payee) external returns (uint256 escrowId);
    function fundEscrow(uint256 escrowId) external payable;
    function releaseEscrow(uint256 escrowId) external;
    function refundEscrow(uint256 escrowId) external;
    function disputeEscrow(uint256 escrowId) external;
    function getEscrow(uint256 escrowId) external view returns (Escrow memory);
    function getEscrowByTask(uint256 taskId) external view returns (uint256);
}
