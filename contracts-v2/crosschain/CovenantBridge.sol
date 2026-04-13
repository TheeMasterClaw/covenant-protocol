// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantBridge} from "../interfaces/ICovenantBridge.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CovenantBridge
 * @notice Cross-chain messaging bridge for covenants
 */
contract CovenantBridge is ICovenantBridge, Ownable, ReentrancyGuard {
    uint256 private _nextMessageId;
    mapping(uint256 => uint8) public messageStatuses; // 0: Pending, 1: Delivered, 2: Failed
    mapping(uint16 => address) public supportedChains;
    mapping(uint16 => bool) public isChainSupported;

    constructor() Ownable(msg.sender) {
        _nextMessageId = 1;
    }

    /// @inheritdoc ICovenantBridge
    function sendMessage(uint16 targetChain, bytes calldata payload) external payable nonReentrant returns (uint256 messageId) {
        if (!isChainSupported[targetChain]) revert InvalidChain();
        if (payload.length == 0 || payload.length > 10000) revert MessageTooLarge();

        messageId = _nextMessageId++;
        messageStatuses[messageId] = 0;

        emit MessageSent(messageId, targetChain, payload);
    }

    /// @inheritdoc ICovenantBridge
    function receiveMessage(uint16 sourceChain, bytes calldata payload) external {
        if (!isChainSupported[sourceChain]) revert InvalidChain();
        if (msg.sender != supportedChains[sourceChain]) revert UnauthorizedRelayer();
        if (payload.length == 0) revert MessageTooLarge();

        uint256 messageId = uint256(keccak256(abi.encodePacked(sourceChain, payload, block.timestamp)));
        messageStatuses[messageId] = 1;

        emit MessageReceived(messageId, sourceChain, payload);
    }

    /// @inheritdoc ICovenantBridge
    function addSupportedChain(uint16 chainId, address adapter) external onlyOwner {
        if (chainId == 0 || adapter == address(0)) revert InvalidChain();
        supportedChains[chainId] = adapter;
        isChainSupported[chainId] = true;
        emit ChainSupported(chainId, adapter);
    }

    /// @inheritdoc ICovenantBridge
    function getMessageStatus(uint256 messageId) external view returns (uint8) {
        return messageStatuses[messageId];
    }

    receive() external payable {}
}
