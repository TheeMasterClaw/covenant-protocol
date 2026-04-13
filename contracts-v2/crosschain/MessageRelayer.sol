// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMessageRelayer} from "../interfaces/IMessageRelayer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MessageRelayer
 * @notice Message relaying for cross-chain communication
 */
contract MessageRelayer is IMessageRelayer, Ownable, ReentrancyGuard {
    uint256 private _nextJobId;
    mapping(uint256 => RelayJob) public relayJobs;
    mapping(address => bool) public authorizedRelayers;

    modifier onlyRelayer() {
        require(authorizedRelayers[msg.sender], "Unauthorized relayer");
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IMessageRelayer
    function requestRelay(uint16 targetChain, bytes calldata payload) external payable nonReentrant returns (uint256 messageId) {
        if (msg.value == 0) revert InsufficientFee();
        if (payload.length == 0) revert RelayNotFound();

        messageId = _nextJobId++;
        relayJobs[messageId] = RelayJob({
            messageId: messageId,
            targetChain: targetChain,
            payload: payload,
            fee: msg.value,
            relayer: address(0),
            completed: false
        });

        emit RelayRequested(messageId, msg.value);
    }

    /// @inheritdoc IMessageRelayer
    function completeRelay(uint256 messageId) external onlyRelayer {
        RelayJob storage job = relayJobs[messageId];
        if (job.messageId == 0) revert RelayNotFound();
        if (job.completed) revert RelayAlreadyCompleted();

        job.completed = true;
        job.relayer = msg.sender;

        emit RelayCompleted(messageId, msg.sender);
    }

    /// @inheritdoc IMessageRelayer
    function claimFee(uint256 messageId) external nonReentrant {
        RelayJob storage job = relayJobs[messageId];
        if (job.messageId == 0) revert RelayNotFound();
        if (!job.completed) revert RelayAlreadyCompleted();
        if (job.relayer != msg.sender) revert RelayNotFound();

        uint256 fee = job.fee;
        job.fee = 0;

        (bool success, ) = payable(msg.sender).call{value: fee}("");
        if (!success) revert RelayNotFound();
    }

    /// @inheritdoc IMessageRelayer
    function getRelayJob(uint256 messageId) external view returns (RelayJob memory) {
        return relayJobs[messageId];
    }

    function authorizeRelayer(address relayer) external onlyOwner {
        authorizedRelayers[relayer] = true;
    }

    function revokeRelayer(address relayer) external onlyOwner {
        authorizedRelayers[relayer] = false;
    }

    receive() external payable {}
}
