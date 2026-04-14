// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IZKVerifierV2 {
    struct Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }
    function verifyProof(bytes32 circuitId, uint256[] calldata publicInputs, Proof calldata proof) external returns (bool);
}

/**
 * @title AnonymousJuryPool
 * @notice Semaphore-style anonymous jury voting with ZK reputation proofs
 * @dev Public inputs layout for Groth16 proof:
 *   [0]  merkleRoot (as uint256)
 *   [1]  nullifierHash
 *   [2]  disputeId (as uint256)
 *   [3]  verdict (as uint256)
 *   [4]  voteCommitment (as uint256)
 *   [5]  minReputationThreshold
 */
contract AnonymousJuryPool is Ownable, ReentrancyGuard {
    enum Verdict { UNDECIDED, PLAINTIFF, DEFENDANT, SETTLEMENT }

    struct AnonymousVote {
        bytes32 nullifierHash;
        bytes32 voteCommitment;
        Verdict verdict;
        uint256 timestamp;
    }

    struct JurySession {
        uint256 disputeId;
        bytes32 merkleRoot;
        uint256 minReputationThreshold;
        bool resolved;
        Verdict finalVerdict;
        uint256 resolutionTime;
        uint256 voteCount;
    }

    IZKVerifierV2 public zkVerifier;
    bytes32 public juryEligibilityCircuitId;

    mapping(uint256 => JurySession) public sessions;
    mapping(uint256 => mapping(bytes32 => bool)) public nullifierHashes;
    mapping(uint256 => AnonymousVote[]) public sessionVotes;

    uint256 public constant MIN_JURORS = 3;
    uint256 public constant MAX_JURORS = 101;

    event SessionCreated(uint256 indexed disputeId, bytes32 merkleRoot, uint256 threshold);
    event AnonymousVoteSubmitted(uint256 indexed disputeId, bytes32 nullifierHash, Verdict verdict);
    event DisputeResolved(uint256 indexed disputeId, Verdict finalVerdict);

    error InvalidProof();
    error DoubleVoting();
    error SessionNotFound();
    error SessionAlreadyResolved();
    error InvalidVerdict();
    error VerifierNotSet();

    constructor(address _zkVerifier, bytes32 _circuitId) Ownable(msg.sender) {
        zkVerifier = IZKVerifierV2(_zkVerifier);
        juryEligibilityCircuitId = _circuitId;
    }

    function createSession(
        uint256 disputeId,
        bytes32 merkleRoot,
        uint256 minReputationThreshold
    ) external onlyOwner {
        JurySession storage session = sessions[disputeId];
        if (session.disputeId != 0) revert SessionAlreadyResolved();

        session.disputeId = disputeId;
        session.merkleRoot = merkleRoot;
        session.minReputationThreshold = minReputationThreshold;

        emit SessionCreated(disputeId, merkleRoot, minReputationThreshold);
    }

    /**
     * @notice Submit a vote anonymously with ZK proof of jury eligibility
     * @param publicInputs [merkleRoot, nullifierHash, disputeId, verdict, voteCommitment, minReputationThreshold]
     */
    function submitAnonymousVote(
        uint256 disputeId,
        uint256[] calldata publicInputs,
        IZKVerifierV2.Proof calldata proof,
        Verdict verdict,
        bytes32 voteCommitment
    ) external nonReentrant {
        JurySession storage session = sessions[disputeId];
        if (session.disputeId == 0) revert SessionNotFound();
        if (session.resolved) revert SessionAlreadyResolved();
        if (verdict == Verdict.UNDECIDED) revert InvalidVerdict();
        if (sessionVotes[disputeId].length >= MAX_JURORS) revert SessionAlreadyResolved();

        // Validate public inputs match expected values
        if (uint256(session.merkleRoot) != publicInputs[0]) revert InvalidProof();
        bytes32 nullifierHash = bytes32(publicInputs[1]);
        if (uint256(disputeId) != publicInputs[2]) revert InvalidProof();
        if (uint256(verdict) != publicInputs[3]) revert InvalidProof();
        if (uint256(voteCommitment) != publicInputs[4]) revert InvalidProof();
        if (session.minReputationThreshold != publicInputs[5]) revert InvalidProof();

        // Prevent double voting
        if (nullifierHashes[disputeId][nullifierHash]) revert DoubleVoting();

        // Verify ZK proof
        bool valid = zkVerifier.verifyProof(juryEligibilityCircuitId, publicInputs, proof);
        if (!valid) revert InvalidProof();

        nullifierHashes[disputeId][nullifierHash] = true;
        sessionVotes[disputeId].push(AnonymousVote({
            nullifierHash: nullifierHash,
            voteCommitment: voteCommitment,
            verdict: verdict,
            timestamp: block.timestamp
        }));
        session.voteCount++;

        emit AnonymousVoteSubmitted(disputeId, nullifierHash, verdict);
    }

    function resolveDispute(uint256 disputeId) external onlyOwner returns (Verdict finalVerdict) {
        JurySession storage session = sessions[disputeId];
        if (session.disputeId == 0) revert SessionNotFound();
        if (session.resolved) revert SessionAlreadyResolved();
        if (session.voteCount < MIN_JURORS) revert SessionNotFound();

        uint256[4] memory tallies;
        AnonymousVote[] memory votes = sessionVotes[disputeId];
        for (uint i = 0; i < votes.length; i++) {
            tallies[uint256(votes[i].verdict)] += 1;
        }

        uint256 maxVotes = 0;
        for (uint v = 1; v < 4; v++) {
            if (tallies[v] > maxVotes) {
                maxVotes = tallies[v];
                finalVerdict = Verdict(v);
            }
        }

        session.finalVerdict = finalVerdict;
        session.resolved = true;
        session.resolutionTime = block.timestamp;

        emit DisputeResolved(disputeId, finalVerdict);
    }

    function getVotes(uint256 disputeId) external view returns (AnonymousVote[] memory) {
        return sessionVotes[disputeId];
    }

    function setCircuitId(bytes32 _circuitId) external onlyOwner {
        juryEligibilityCircuitId = _circuitId;
    }

    function setZKVerifier(address _zkVerifier) external onlyOwner {
        zkVerifier = IZKVerifierV2(_zkVerifier);
    }
}
