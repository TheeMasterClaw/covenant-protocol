// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantMultiSig
 * @notice Interface for the CovenantMultiSig contract
 */
interface ICovenantMultiSig {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmationCount;
    }

    event TransactionSubmitted(uint256 indexed txIndex, address indexed submitter);
    event TransactionConfirmed(uint256 indexed txIndex, address indexed confirmer);
    event TransactionRevoked(uint256 indexed txIndex, address indexed revoker);
    event TransactionExecuted(uint256 indexed txIndex);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event RequiredConfirmationsChanged(uint256 required);

    error UnauthorizedSigner();
    error AlreadyConfirmed();
    error NotConfirmed();
    error AlreadyExecuted();
    error TransactionFailed();
    error InvalidSignerCount();

    function submitTransaction(address to, uint256 value, bytes calldata data) external returns (uint256 txIndex);
    function confirmTransaction(uint256 txIndex) external;
    function revokeConfirmation(uint256 txIndex) external;
    function executeTransaction(uint256 txIndex) external;
    function addSigner(address signer) external;
    function removeSigner(address signer) external;
    function changeRequiredConfirmations(uint256 required) external;
    function isSigner(address account) external view returns (bool);
    function getTransaction(uint256 txIndex) external view returns (Transaction memory);
    function getTransactionCount() external view returns (uint256);
}
