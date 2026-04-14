// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IZKVerifierV2 {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }
    function verifyProof(bytes32 circuitId, uint256[] calldata publicInputs, Proof calldata proof) external returns (bool);
}

/**
 * @title ZKMLJuror
 * @notice Verifiable AI inference registry and submission gate for AI jurors
 * @dev Integrates EZKL-style proofs where public inputs bind model, evidence, and output.
 * Public inputs layout:
 *   [0] modelHash (as uint256)
 *   [1] evidenceCommitment
 *   [2] outputCommitment
 *   [3] minConfidence (scaled by 1e6)
 *   [4] disputeId
 */
contract ZKMLJuror is Ownable {
    IZKVerifierV2 public zkVerifier;
    bytes32 public zkmlCircuitId;

    mapping(bytes32 => bool) public approvedModels;
    mapping(uint256 => mapping(bytes32 => bool)) public evidenceSubmitted;

    enum Verdict { UNDECIDED, PLAINTIFF, DEFENDANT, SETTLEMENT }

    struct ModelCommitment {
        bytes32 modelHash;
        string modelURI;
        uint256 registeredAt;
        bool active;
    }

    mapping(bytes32 => ModelCommitment) public models;
    bytes32[] public modelList;

    event ModelRegistered(bytes32 indexed modelHash, string modelURI);
    event ModelRevoked(bytes32 indexed modelHash);
    event ZKMLInferenceSubmitted(uint256 indexed disputeId, bytes32 indexed modelHash, bytes32 outputCommitment, Verdict verdict);

    error InvalidProof();
    error ModelNotApproved();
    error EvidenceAlreadyUsed();

    constructor(address _zkVerifier, bytes32 _circuitId) Ownable(msg.sender) {
        zkVerifier = IZKVerifierV2(_zkVerifier);
        zkmlCircuitId = _circuitId;
    }

    function registerModel(bytes32 modelHash, string calldata modelURI) external onlyOwner {
        models[modelHash] = ModelCommitment(modelHash, modelURI, block.timestamp, true);
        approvedModels[modelHash] = true;
        modelList.push(modelHash);
        emit ModelRegistered(modelHash, modelURI);
    }

    function revokeModel(bytes32 modelHash) external onlyOwner {
        models[modelHash].active = false;
        approvedModels[modelHash] = false;
        emit ModelRevoked(modelHash);
    }

    /**
     * @notice Submit an AI juror verdict backed by a zkML proof
     * @param publicInputs [modelHash, evidenceCommitment, outputCommitment, minConfidence, disputeId]
     */
    function submitZKMLInference(
        uint256 disputeId,
        bytes32 evidenceCommitment,
        bytes32 outputCommitment,
        Verdict verdict,
        uint256[] calldata publicInputs,
        IZKVerifierV2.Proof calldata proof
    ) external {
        if (publicInputs.length < 5) revert InvalidProof();
        bytes32 modelHash = bytes32(publicInputs[0]);
        if (!approvedModels[modelHash]) revert ModelNotApproved();
        if (evidenceCommitment != bytes32(publicInputs[1])) revert InvalidProof();
        if (outputCommitment != bytes32(publicInputs[2])) revert InvalidProof();
        if (uint256(disputeId) != publicInputs[4]) revert InvalidProof();
        if (evidenceSubmitted[disputeId][evidenceCommitment]) revert EvidenceAlreadyUsed();

        bool valid = zkVerifier.verifyProof(zkmlCircuitId, publicInputs, proof);
        if (!valid) revert InvalidProof();

        evidenceSubmitted[disputeId][evidenceCommitment] = true;
        emit ZKMLInferenceSubmitted(disputeId, modelHash, outputCommitment, verdict);
    }

    function setCircuitId(bytes32 _circuitId) external onlyOwner {
        zkmlCircuitId = _circuitId;
    }

    function getApprovedModels() external view returns (bytes32[] memory) {
        uint256 count = 0;
        for (uint i = 0; i < modelList.length; i++) {
            if (approvedModels[modelList[i]]) count++;
        }
        bytes32[] memory result = new bytes32[](count);
        uint256 idx = 0;
        for (uint i = 0; i < modelList.length; i++) {
            if (approvedModels[modelList[i]]) {
                result[idx] = modelList[i];
                idx++;
            }
        }
        return result;
    }
}
