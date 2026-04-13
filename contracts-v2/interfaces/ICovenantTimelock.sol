// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantTimelock
 * @notice Interface for the CovenantTimelock contract
 */
interface ICovenantTimelock {
    struct Operation {
        address target;
        uint256 value;
        bytes data;
        uint256 scheduledAt;
        uint256 delay;
        bool executed;
    }

    event OperationScheduled(bytes32 indexed operationId, address indexed target, uint256 value, bytes data, uint256 scheduledAt);
    event OperationExecuted(bytes32 indexed operationId);
    event OperationCancelled(bytes32 indexed operationId);
    event DelayUpdated(uint256 newDelay);

    error OperationAlreadyScheduled();
    error OperationNotScheduled();
    error OperationNotReady();
    error OperationAlreadyExecuted();
    error UnauthorizedCaller();
    error InvalidDelay();

    function schedule(address target, uint256 value, bytes calldata data, uint256 delay) external returns (bytes32 operationId);
    function execute(address target, uint256 value, bytes calldata data) external;
    function cancel(bytes32 operationId) external;
    function setDelay(uint256 newDelay) external;
    function getOperation(bytes32 operationId) external view returns (Operation memory);
    function isOperationReady(bytes32 operationId) external view returns (bool);
    function getMinDelay() external view returns (uint256);
}
