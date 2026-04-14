// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IMessageVerifier } from "../interfaces/IMessageVerifier.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title AgentAttestationVerifier
 * @notice Multi-source verification for agent attestations across chains
 * @dev Implements threshold-based verification using bridge validator/DVN signatures
 * 
 * This contract verifies that agent reputation attestations are signed by
 * sufficient validators from the source chain, preventing malicious reputation
 * manipulation across the COVENANT cross-chain network.
 */
contract AgentAttestationVerifier is IMessageVerifier, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    
    struct Attestation {
        address agent;
        uint256 reputationScore;
        bytes32 metadataHash;
        uint256 timestamp;
        uint256 sourceChain;
        bytes[] signatures;
    }
    
    struct ChainVerificationConfig {
        mapping(address => bool) validators;
        uint8 requiredSignatures;
        bool active;
    }
    
    // Source chain => config
    mapping(uint256 => ChainVerificationConfig) public chainConfigs;
    
    // Reputation thresholds
    uint256 public constant ATTESTATION_VALIDITY_PERIOD = 7 days;
    uint256 public constant MIN_REPUTATION_SCORE = 100;
    
    // Verification tracking
    mapping(bytes32 => VerifiedMessage) public verifications;
    mapping(address => bool) public authorizedSigners;
    
    // Events
    event ChainConfigUpdated(uint256 indexed chainId, uint8 requiredSignatures, bool active);
    event ValidatorAdded(uint256 indexed chainId, address indexed validator);
    event ValidatorRemoved(uint256 indexed chainId, address indexed validator);
    event AttestationVerified(bytes32 indexed messageHash, address indexed agent, uint256 sourceChain);
    
    constructor(address _owner) Ownable(_owner) {}
    
    /**
     * @notice Verify an agent attestation with threshold signatures
     * @param messageHash Hash of the attestation message
     * @param signature Packed signature data containing encoded Attestation
     * @return valid True if attestation is valid
     */
    function verifyMessage(bytes32 messageHash, bytes calldata signature) 
        external 
        override 
        returns (bool valid) 
    {
        if (verifications[messageHash].verifiedAt != 0) revert MessageAlreadyVerified();
        
        // Decode attestation from signature field (used as packed data)
        Attestation memory attestation = abi.decode(signature, (Attestation));
        
        valid = _verifyAttestation(attestation, messageHash);
        
        if (valid) {
            verifications[messageHash] = VerifiedMessage({
                messageHash: messageHash,
                signature: signature,
                signer: attestation.agent,
                verifiedAt: block.timestamp,
                valid: true
            });
            
            emit MessageVerified(messageHash, attestation.agent);
            emit AttestationVerified(messageHash, attestation.agent, attestation.sourceChain);
        }
        
        return valid;
    }
    
    /**
     * @notice Verify attestation data (can be called directly or via bridge adapters)
     * @param attestation Agent attestation struct
     * @return valid True if attestation is valid
     */
    function verifyAgentAttestation(Attestation memory attestation) 
        external 
        view 
        returns (bool valid) 
    {
        bytes32 messageHash = keccak256(abi.encodePacked(
            attestation.agent,
            attestation.reputationScore,
            attestation.metadataHash,
            attestation.timestamp,
            attestation.sourceChain
        ));
        
        return _verifyAttestation(attestation, messageHash);
    }
    
    /**
     * @notice Internal verification logic
     */
    function _verifyAttestation(Attestation memory attestation, bytes32 messageHash) 
        internal 
        view 
        returns (bool) 
    {
        // Check attestation freshness
        if (block.timestamp > attestation.timestamp + ATTESTATION_VALIDITY_PERIOD) {
            return false;
        }
        
        // Check minimum reputation
        if (attestation.reputationScore < MIN_REPUTATION_SCORE) {
            return false;
        }
        
        // Check chain is active
        ChainVerificationConfig storage config = chainConfigs[attestation.sourceChain];
        if (!config.active) {
            return false;
        }
        
        // Verify threshold signatures from source chain validators
        bytes32 ethSignedHash = messageHash.toEthSignedMessageHash();
        uint8 validSignatures = 0;
        
        for (uint i = 0; i < attestation.signatures.length; i++) {
            address signer = ethSignedHash.recover(attestation.signatures[i]);
            if (config.validators[signer]) {
                validSignatures++;
            }
        }
        
        return validSignatures >= config.requiredSignatures;
    }
    
    /**
     * @notice Set chain verification configuration
     * @param chainId Source chain ID
     * @param requiredSignatures Number of validator signatures required
     * @param active Whether this chain is active for attestations
     */
    function setChainConfig(
        uint256 chainId,
        uint8 requiredSignatures,
        bool active
    ) external onlyOwner {
        chainConfigs[chainId].requiredSignatures = requiredSignatures;
        chainConfigs[chainId].active = active;
        emit ChainConfigUpdated(chainId, requiredSignatures, active);
    }
    
    /**
     * @notice Add validator for a chain
     */
    function addValidator(uint256 chainId, address validator) external onlyOwner {
        require(validator != address(0), "Invalid validator");
        chainConfigs[chainId].validators[validator] = true;
        emit ValidatorAdded(chainId, validator);
    }
    
    /**
     * @notice Remove validator for a chain
     */
    function removeValidator(uint256 chainId, address validator) external onlyOwner {
        chainConfigs[chainId].validators[validator] = false;
        emit ValidatorRemoved(chainId, validator);
    }
    
    /**
     * @notice Batch add validators
     */
    function addValidators(uint256 chainId, address[] calldata validators) external onlyOwner {
        for (uint i = 0; i < validators.length; i++) {
            require(validators[i] != address(0), "Invalid validator");
            chainConfigs[chainId].validators[validators[i]] = true;
            emit ValidatorAdded(chainId, validators[i]);
        }
    }
    
    /**
     * @notice Check if address is a validator for a chain
     */
    function isValidator(uint256 chainId, address validator) external view returns (bool) {
        return chainConfigs[chainId].validators[validator];
    }
    
    /**
     * @notice Get chain config
     */
    function getChainConfig(uint256 chainId) 
        external 
        view 
        returns (uint8 requiredSignatures, bool active) 
    {
        ChainVerificationConfig storage config = chainConfigs[chainId];
        return (config.requiredSignatures, config.active);
    }
    
    // Required interface stubs
    function authorizeSigner(address signer) external override onlyOwner {
        if (signer == address(0)) revert InvalidSignature();
        authorizedSigners[signer] = true;
        emit SignerAuthorized(signer);
    }
    
    function revokeSigner(address signer) external override onlyOwner {
        authorizedSigners[signer] = false;
        emit SignerRevoked(signer);
    }
    
    function isAuthorizedSigner(address signer) external view override returns (bool) {
        return authorizedSigners[signer];
    }
    
    function getVerification(bytes32 messageHash) external view override returns (VerifiedMessage memory) {
        return verifications[messageHash];
    }
}