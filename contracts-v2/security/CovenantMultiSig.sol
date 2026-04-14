// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantMultiSig} from "../interfaces/ICovenantMultiSig.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CovenantMultiSig
 * @notice Multi-signature wallet for covenant security
 */
contract CovenantMultiSig is ICovenantMultiSig, ReentrancyGuard {
    mapping(address => bool) public signers;
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    address[] public signerList;
    uint256 public requiredConfirmations;
    uint256 public transactionCount;

    modifier onlySigner() {
        if (!signers[msg.sender]) revert UnauthorizedSigner();
        _;
    }

    modifier txExists(uint256 txIndex) {
        if (txIndex == 0 || txIndex > transactionCount) revert TransactionFailed();
        _;
    }

    constructor(address[] memory _signers, uint256 _requiredConfirmations) {
        if (_signers.length == 0 || _requiredConfirmations == 0 || _requiredConfirmations > _signers.length) {
            revert InvalidSignerCount();
        }

        for (uint256 i = 0; i < _signers.length; ) {
            address s = _signers[i];
            if (s == address(0)) revert InvalidSignerCount();
            if (signers[s]) revert InvalidSignerCount();
            signers[s] = true;
            signerList.push(s);
            unchecked { ++i; }
        }

        requiredConfirmations = _requiredConfirmations;
    }

    /// @inheritdoc ICovenantMultiSig
    function submitTransaction(address to, uint256 value, bytes calldata data) external onlySigner returns (uint256 txIndex) {
        txIndex = ++transactionCount;
        transactions[txIndex] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmationCount: 0
        });

        emit TransactionSubmitted(txIndex, msg.sender);
        confirmTransaction(txIndex);
    }

    /// @inheritdoc ICovenantMultiSig
    function confirmTransaction(uint256 txIndex) public onlySigner {
        if (confirmations[txIndex][msg.sender]) revert AlreadyConfirmed();
        confirmations[txIndex][msg.sender] = true;
        transactions[txIndex].confirmationCount++;

        emit TransactionConfirmed(txIndex, msg.sender);
    }

    /// @inheritdoc ICovenantMultiSig
    function revokeConfirmation(uint256 txIndex) external onlySigner {
        if (!confirmations[txIndex][msg.sender]) revert NotConfirmed();
        confirmations[txIndex][msg.sender] = false;
        transactions[txIndex].confirmationCount--;

        emit TransactionRevoked(txIndex, msg.sender);
    }

    /// @inheritdoc ICovenantMultiSig
    function executeTransaction(uint256 txIndex) external nonReentrant {
        Transaction storage txn = transactions[txIndex];
        if (txn.executed) revert AlreadyExecuted();
        if (txn.confirmationCount < requiredConfirmations) revert TransactionFailed();

        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        if (!success) revert TransactionFailed();

        emit TransactionExecuted(txIndex);
    }

    /// @inheritdoc ICovenantMultiSig
    function addSigner(address _signer) external onlySigner {
        if (_signer == address(0) || signers[_signer]) revert InvalidSignerCount();
        signers[_signer] = true;
        signerList.push(_signer);
        emit SignerAdded(_signer);
    }

    /// @inheritdoc ICovenantMultiSig
    function removeSigner(address _signer) external onlySigner {
        if (!signers[_signer]) revert InvalidSignerCount();
        signers[_signer] = false;
        emit SignerRemoved(_signer);
    }

    /// @inheritdoc ICovenantMultiSig
    function changeRequiredConfirmations(uint256 required) external onlySigner {
        if (required == 0 || required > signerList.length) revert InvalidSignerCount();
        requiredConfirmations = required;
        emit RequiredConfirmationsChanged(required);
    }

    /// @inheritdoc ICovenantMultiSig
    function isSigner(address account) external view returns (bool) {
        return signers[account];
    }

    /// @inheritdoc ICovenantMultiSig
    function getTransaction(uint256 txIndex) external view returns (Transaction memory) {
        return transactions[txIndex];
    }

    /// @inheritdoc ICovenantMultiSig
    function getTransactionCount() external view returns (uint256) {
        return transactionCount;
    }

    receive() external payable {}
}