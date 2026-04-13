// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantTimelock} from "../interfaces/ICovenantTimelock.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CovenantTimelock
 * @notice Timelock controller for governance actions
 */
contract CovenantTimelock is ICovenantTimelock, Ownable, ReentrancyGuard {
    mapping(bytes32 => Operation) public operations;
    uint256 public minDelay;

    modifier onlySelf() {
        if (msg.sender != address(this)) revert UnauthorizedCaller();
        _;
    }

    constructor(uint256 delay) Ownable(msg.sender) {
        if (delay == 0) revert InvalidDelay();
        minDelay = delay;
    }

    /// @inheritdoc ICovenantTimelock
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        uint256 delay
    ) external onlyOwner returns (bytes32 operationId) {
        if (delay < minDelay) revert InvalidDelay();
        operationId = keccak256(abi.encode(target, value, data));
        if (operations[operationId].scheduledAt != 0) revert OperationAlreadyScheduled();

        operations[operationId] = Operation({
            target: target,
            value: value,
            data: data,
            scheduledAt: block.timestamp,
            delay: delay,
            executed: false
        });

        emit OperationScheduled(operationId, target, value, data, block.timestamp);
    }

    /// @inheritdoc ICovenantTimelock
    function execute(address target, uint256 value, bytes calldata data) external nonReentrant {
        bytes32 operationId = keccak256(abi.encode(target, value, data));
        Operation storage op = operations[operationId];
        if (op.scheduledAt == 0) revert OperationNotScheduled();
        if (op.executed) revert OperationAlreadyExecuted();
        if (block.timestamp < op.scheduledAt + op.delay) revert OperationNotReady();

        op.executed = true;

        (bool success, ) = target.call{value: value}(data);
        if (!success) revert OperationAlreadyExecuted();

        emit OperationExecuted(operationId);
    }

    /// @inheritdoc ICovenantTimelock
    function cancel(bytes32 operationId) external onlyOwner {
        Operation storage op = operations[operationId];
        if (op.scheduledAt == 0) revert OperationNotScheduled();
        if (op.executed) revert OperationAlreadyExecuted();

        delete operations[operationId];
        emit OperationCancelled(operationId);
    }

    /// @inheritdoc ICovenantTimelock
    function setDelay(uint256 newDelay) external onlySelf {
        if (newDelay == 0) revert InvalidDelay();
        minDelay = newDelay;
        emit DelayUpdated(newDelay);
    }

    /// @inheritdoc ICovenantTimelock
    function getOperation(bytes32 operationId) external view returns (Operation memory) {
        return operations[operationId];
    }

    /// @inheritdoc ICovenantTimelock
    function isOperationReady(bytes32 operationId) external view returns (bool) {
        Operation storage op = operations[operationId];
        if (op.scheduledAt == 0 || op.executed) return false;
        return block.timestamp >= op.scheduledAt + op.delay;
    }

    /// @inheritdoc ICovenantTimelock
    function getMinDelay() external view returns (uint256) {
        return minDelay;
    }

    receive() external payable {}
}
