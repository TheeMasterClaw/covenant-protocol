// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMessageVerifier} from "../interfaces/IMessageVerifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title MessageVerifier
 * @notice Message validation for cross-chain communication
 */
contract MessageVerifier is IMessageVerifier, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    mapping(address => bool) public authorizedSigners;
    mapping(bytes32 => VerifiedMessage) public verifications;

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IMessageVerifier
    function verifyMessage(bytes32 messageHash, bytes calldata signature) external returns (bool) {
        if (verifications[messageHash].verifiedAt != 0) revert MessageAlreadyVerified();

        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedHash.recover(signature);

        if (!authorizedSigners[signer]) revert SignerNotAuthorized();

        verifications[messageHash] = VerifiedMessage({
            messageHash: messageHash,
            signature: signature,
            signer: signer,
            verifiedAt: block.timestamp,
            valid: true
        });

        emit MessageVerified(messageHash, signer);
        return true;
    }

    /// @inheritdoc IMessageVerifier
    function authorizeSigner(address signer) external onlyOwner {
        if (signer == address(0)) revert InvalidSignature();
        authorizedSigners[signer] = true;
        emit SignerAuthorized(signer);
    }

    /// @inheritdoc IMessageVerifier
    function revokeSigner(address signer) external onlyOwner {
        authorizedSigners[signer] = false;
        emit SignerRevoked(signer);
    }

    /// @inheritdoc IMessageVerifier
    function isAuthorizedSigner(address signer) external view returns (bool) {
        return authorizedSigners[signer];
    }

    /// @inheritdoc IMessageVerifier
    function getVerification(bytes32 messageHash) external view returns (VerifiedMessage memory) {
        return verifications[messageHash];
    }
}