// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IRiscZeroVerifier {
    function verify(bytes calldata seal, bytes32 imageId, bytes32 journalDigest) external view;
}

/**
 * @title RISC0ReputationBatch
 * @notice Batch reputation score computation using RISC0 zkVM
 * @dev Off-chain guest program aggregates task completions, slashing events, stake amounts
 *      and produces a new Merkle root of reputation scores. On-chain verification is cheap.
 */
contract RISC0ReputationBatch is Ownable {
    IRiscZeroVerifier public risc0Verifier;
    bytes32 public guestImageId;

    bytes32 public currentReputationRoot;
    uint256 public lastBatchTimestamp;
    uint256 public batchCount;

    mapping(bytes32 => bool) public verifiedBatches;

    struct ReputationUpdate {
        address user;
        uint256 newScore;
        bytes32[] merkleProof;
    }

    event BatchVerified(uint256 indexed batchId, bytes32 newRoot, uint256 userCount);
    event VerifierUpdated(address newVerifier);
    event ImageIdUpdated(bytes32 newImageId);

    error InvalidProof();
    error InvalidRoot();
    error BatchAlreadyVerified();

    constructor(address _verifier, bytes32 _imageId) Ownable(msg.sender) {
        risc0Verifier = IRiscZeroVerifier(_verifier);
        guestImageId = _imageId;
    }

    /**
     * @notice Submit a verified batch update of reputation scores
     * @param seal RISC0 SNARK seal
     * @param journalDigest keccak256(batchData) where batchData includes:
     *        - previousRoot
     *        - newRoot  
     *        - userCount
     *        - timestamp
     *        - blockHeight
     */
    function submitBatch(
        bytes calldata seal,
        bytes32 journalDigest,
        bytes32 newRoot,
        uint256 userCount
    ) external {
        if (verifiedBatches[journalDigest]) revert BatchAlreadyVerified();

        // Verify RISC0 proof
        risc0Verifier.verify(seal, guestImageId, journalDigest);

        // Update state
        currentReputationRoot = newRoot;
        lastBatchTimestamp = block.timestamp;
        batchCount++;
        verifiedBatches[journalDigest] = true;

        emit BatchVerified(batchCount, newRoot, userCount);
    }

    /**
     * @notice Verify a user's reputation score is in the current root
     * @dev Used by AnonymousJuryPool to check eligibility without revealing full tree
     */
    function verifyReputationMembership(
        address user,
        uint256 score,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user, score));
        bytes32 computedRoot = computeMerkleRoot(leaf, merkleProof);
        return computedRoot == currentReputationRoot;
    }

    function computeMerkleRoot(bytes32 leaf, bytes32[] calldata proof) public pure returns (bytes32) {
        bytes32 current = leaf;
        for (uint i = 0; i < proof.length; i++) {
            current = keccak256(abi.encodePacked(current, proof[i]));
        }
        return current;
    }

    function setVerifier(address _verifier) external onlyOwner {
        risc0Verifier = IRiscZeroVerifier(_verifier);
        emit VerifierUpdated(_verifier);
    }

    function setImageId(bytes32 _imageId) external onlyOwner {
        guestImageId = _imageId;
        emit ImageIdUpdated(_imageId);
    }
}
