// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IZKVerifier
 * @notice Interface for the ZKVerifier contract
 */
interface IZKVerifier {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    event ProofVerified(bytes32 indexed proofHash, bool valid);
    event VerifierSet(bytes32 indexed circuitId, address indexed verifier);

    error InvalidProof();
    error VerifierNotSet();
    error VerificationFailed();

    function verifyProof(bytes32 circuitId, uint256[] calldata publicInputs, Proof calldata proof) external returns (bool);
    function setVerifier(bytes32 circuitId, address verifier) external;
    function getVerifier(bytes32 circuitId) external view returns (address);
    function hashProof(Proof calldata proof) external view returns (bytes32);
}
