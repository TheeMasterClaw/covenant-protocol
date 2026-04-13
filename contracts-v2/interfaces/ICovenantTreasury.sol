// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantTreasury
 * @notice Interface for the CovenantTreasury contract
 */
interface ICovenantTreasury {
    event Deposited(address indexed token, address indexed sender, uint256 amount);
    event Withdrawn(address indexed token, address indexed recipient, uint256 amount);
    event BudgetAllocated(address indexed recipient, address indexed token, uint256 amount);

    error InsufficientBalance();
    error UnauthorizedWithdrawal();
    error InvalidRecipient();

    function deposit(address token, uint256 amount) external payable;
    function withdraw(address token, address recipient, uint256 amount) external;
    function allocateBudget(address recipient, address token, uint256 amount) external;
    function getBalance(address token) external view returns (uint256);
    function getBudget(address recipient, address token) external view returns (uint256);
}
