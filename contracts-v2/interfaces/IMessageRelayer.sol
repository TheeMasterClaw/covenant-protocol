// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMessageRelayer
 * @notice Interface for the MessageRelayer contract
 */
interface IMessageRelayer {
    struct RelayJob {
        uint256 messageId;
        uint16 targetChain;
        bytes payload;
        uint256 fee;
        address relayer;
        bool completed;
    }

    event RelayRequested(uint256 indexed messageId, uint256 fee);
    event RelayCompleted(uint256 indexed messageId, address indexed relayer);

    error RelayNotFound();
    error RelayAlreadyCompleted();
    error InsufficientFee();

    function requestRelay(uint16 targetChain, bytes calldata payload) external payable returns (uint256 messageId);
    function completeRelay(uint256 messageId) external;
    function claimFee(uint256 messageId) external;
    function getRelayJob(uint256 messageId) external view returns (RelayJob memory);
}
