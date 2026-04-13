// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IMessageVerifier
 * @notice Interface for the MessageVerifier contract
 */
interface IMessageVerifier {
    struct VerifiedMessage {
        bytes32 messageHash;
        bytes signature;
        address signer;
        uint256 verifiedAt;
        bool valid;
    }

    event MessageVerified(bytes32 indexed messageHash, address indexed signer);
    event SignerAuthorized(address indexed signer);
    event SignerRevoked(address indexed signer);

    error InvalidSignature();
    error SignerNotAuthorized();
    error MessageAlreadyVerified();

    function verifyMessage(bytes32 messageHash, bytes calldata signature) external returns (bool);
    function authorizeSigner(address signer) external;
    function revokeSigner(address signer) external;
    function isAuthorizedSigner(address signer) external view returns (bool);
    function getVerification(bytes32 messageHash) external view returns (VerifiedMessage memory);
}
