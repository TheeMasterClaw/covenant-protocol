// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantTreasury} from "../interfaces/ICovenantTreasury.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title CovenantTreasury
 * @notice Protocol treasury for managing protocol funds
 */
contract CovenantTreasury is ICovenantTreasury, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public budgets;

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc ICovenantTreasury
    function deposit(address token, uint256 amount) external payable nonReentrant {
        if (token == address(0)) {
            balances[address(0)] += msg.value;
            emit Deposited(address(0), msg.sender, msg.value);
        } else {
            balances[token] += amount;
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            emit Deposited(token, msg.sender, amount);
        }
    }

    /// @inheritdoc ICovenantTreasury
    function withdraw(address token, address recipient, uint256 amount) external onlyOwner nonReentrant {
        if (recipient == address(0)) revert InvalidRecipient();
        if (balances[token] < amount) revert InsufficientBalance();

        balances[token] -= amount;

        if (token == address(0)) {
            (bool success, ) = payable(recipient).call{value: amount}("");
            if (!success) revert InvalidRecipient();
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }

        emit Withdrawn(token, recipient, amount);
    }

    /// @inheritdoc ICovenantTreasury
    function allocateBudget(address recipient, address token, uint256 amount) external onlyOwner {
        if (recipient == address(0)) revert InvalidRecipient();
        if (balances[token] < amount) revert InsufficientBalance();

        balances[token] -= amount;
        budgets[recipient][token] += amount;

        emit BudgetAllocated(recipient, token, amount);
    }

    /// @inheritdoc ICovenantTreasury
    function getBalance(address token) external view returns (uint256) {
        return balances[token];
    }

    /// @inheritdoc ICovenantTreasury
    function getBudget(address recipient, address token) external view returns (uint256) {
        return budgets[recipient][token];
    }

    receive() external payable {}
}
