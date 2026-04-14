// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IZKVerifier} from "../../contracts-v2/interfaces/IZKVerifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ZKVerifierV2
 * @notice Multi-proof verification hub supporting Groth16, PLONK, RISC0, and SP1
 * @dev Circuit IDs:
 *   - bytes32(uint256(1)) => Groth16 (Circom/Noir UltraPlonk)
 *   - bytes32(uint256(2)) => RISC0 STARK-to-SNARK seal
 *   - bytes32(uint256(3)) => SP1 PLONK proof
 */
contract ZKVerifierV2 is IZKVerifier, Ownable {
    enum ProofType { Unknown, Groth16, Risc0Receipt, SP1Proof }

    struct VerifierConfig {
        address verifierContract;
        ProofType proofType;
        bool active;
    }

    mapping(bytes32 => VerifierConfig) public verifierConfigs;

    // RISC0-specific: journal digest => verified
    mapping(bytes32 => bool) public verifiedRisc0Journals;
    // SP1-specific: public values hash => verified
    mapping(bytes32 => bool) public verifiedSP1PublicValues;

    event VerifierSet(bytes32 indexed circuitId, address indexed verifier, ProofType proofType);
    event Groth16Verified(bytes32 indexed circuitId, bytes32 proofHash);
    event Risc0Verified(bytes32 indexed journalDigest);
    event SP1Verified(bytes32 indexed publicValuesHash);

    error VerifierNotSet();
    error VerificationFailed();
    error InvalidProofType();
    error ProofAlreadyUsed();

    constructor() Ownable(msg.sender) {}

    /// @inheritdoc IZKVerifier
    function verifyProof(
        bytes32 circuitId,
        uint256[] calldata publicInputs,
        Proof calldata proof
    ) external returns (bool) {
        VerifierConfig memory config = verifierConfigs[circuitId];
        if (config.verifierContract == address(0) || !config.active) revert VerifierNotSet();
        if (config.proofType != ProofType.Groth16) revert InvalidProofType();

        bytes memory callData = abi.encodeWithSignature(
            "verifyProof(uint256[],uint256[2],uint256[2][2],uint256[2])",
            publicInputs,
            proof.a,
            proof.b,
            proof.c
        );
        (bool success, bytes memory result) = config.verifierContract.call(callData);
        if (!success) revert VerificationFailed();

        bool valid = abi.decode(result, (bool));
        bytes32 proofHash = hashProof(proof);
        emit Groth16Verified(circuitId, proofHash);
        return valid;
    }

    /**
     * @notice Verify a RISC0 receipt (STARK-to-SNARK seal)
     * @param journalDigest keccak256(journal bytes)
     * @param seal Groth16 seal from RISC0 prover
     */
    function verifyRisc0Receipt(
        bytes32 circuitId,
        bytes32 journalDigest,
        bytes calldata seal
    ) external returns (bool) {
        VerifierConfig memory config = verifierConfigs[circuitId];
        if (config.verifierContract == address(0) || !config.active) revert VerifierNotSet();
        if (config.proofType != ProofType.Risc0Receipt) revert InvalidProofType();
        if (verifiedRisc0Journals[journalDigest]) revert ProofAlreadyUsed();

        bytes memory callData = abi.encodeWithSignature(
            "verify(bytes32,bytes32,bytes calldata)",
            bytes32(0), // imageId handled by verifier contract mapping or passed differently
            journalDigest,
            seal
        );
        (bool success, bytes memory result) = config.verifierContract.call(callData);
        if (!success) revert VerificationFailed();

        bool valid = abi.decode(result, (bool));
        if (valid) {
            verifiedRisc0Journals[journalDigest] = true;
            emit Risc0Verified(journalDigest);
        }
        return valid;
    }

    /**
     * @notice Verify an SP1 zkVM proof
     * @param publicValuesHash keccak256(public values)
     * @param proofBytes SP1 compressed proof
     */
    function verifySP1Proof(
        bytes32 circuitId,
        bytes32 publicValuesHash,
        bytes calldata proofBytes
    ) external returns (bool) {
        VerifierConfig memory config = verifierConfigs[circuitId];
        if (config.verifierContract == address(0) || !config.active) revert VerifierNotSet();
        if (config.proofType != ProofType.SP1Proof) revert InvalidProofType();
        if (verifiedSP1PublicValues[publicValuesHash]) revert ProofAlreadyUsed();

        bytes memory callData = abi.encodeWithSignature(
            "verifyProof(bytes32,bytes calldata,bytes calldata)",
            bytes32(0), // vkey hash
            abi.encodePacked(publicValuesHash),
            proofBytes
        );
        (bool success, bytes memory result) = config.verifierContract.call(callData);
        if (!success) revert VerificationFailed();

        bool valid = abi.decode(result, (bool));
        if (valid) {
            verifiedSP1PublicValues[publicValuesHash] = true;
            emit SP1Verified(publicValuesHash);
        }
        return valid;
    }

    function setVerifier(bytes32 circuitId, address verifier, ProofType proofType) external onlyOwner {
        if (verifier == address(0)) revert VerifierNotSet();
        verifierConfigs[circuitId] = VerifierConfig({
            verifierContract: verifier,
            proofType: proofType,
            active: true
        });
        emit VerifierSet(circuitId, verifier, proofType);
    }

    function deactivateVerifier(bytes32 circuitId) external onlyOwner {
        verifierConfigs[circuitId].active = false;
    }

    /// @inheritdoc IZKVerifier
    function setVerifier(bytes32 circuitId, address verifier) external onlyOwner {
        setVerifier(circuitId, verifier, ProofType.Groth16);
    }

    /// @inheritdoc IZKVerifier
    function getVerifier(bytes32 circuitId) external view returns (address) {
        return verifierConfigs[circuitId].verifierContract;
    }

    /// @inheritdoc IZKVerifier
    function hashProof(Proof calldata proof) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(proof.a, proof.b, proof.c));
    }
}
