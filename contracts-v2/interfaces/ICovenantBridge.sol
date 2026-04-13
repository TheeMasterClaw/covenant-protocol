// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantBridge
 * @notice Interface for the CovenantBridge contract
 */
interface ICovenantBridge {
    struct BridgeMessage {
        uint16 targetChain;
        address targetContract;
        bytes payload;
        uint256 nonce;
    }

    event MessageSent(uint256 indexed messageId, uint16 indexed targetChain, bytes payload);
    event MessageReceived(uint256 indexed messageId, uint16 indexed sourceChain, bytes payload);
    event ChainSupported(uint16 indexed chainId, address indexed adapter);

    error InvalidChain();
    error InvalidTarget();
    error MessageTooLarge();
    error UnauthorizedRelayer();

    function sendMessage(uint16 targetChain, bytes calldata payload) external payable returns (uint256 messageId);
    function receiveMessage(uint16 sourceChain, bytes calldata payload) external;
    function addSupportedChain(uint16 chainId, address adapter) external;
    function getMessageStatus(uint256 messageId) external view returns (uint8);
}
