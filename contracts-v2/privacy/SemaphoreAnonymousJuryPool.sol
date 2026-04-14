// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title SemaphoreAnonymousJuryPool
 * @notice Semaphore v4 integration for anonymous jury voting with ZK reputation proofs
 * @dev Replaces custom Groth16 verifier with production Semaphore protocol
 */
interface ISemaphore {
    struct SemaphoreProof {
        uint256 merkleTreeDepth;
        uint256 merkleTreeRoot;
        uint256 nullifier;
        uint256 message;
        uint256 scope;
        uint256[8] points;
    }
    function validateProof(uint256 groupId, SemaphoreProof calldata proof) external;
    function verifyProof(uint256 groupId, SemaphoreProof calldata proof) external view returns (bool);
}

interface IReputationOracle {
    function getAgentReputation(address agent) external view returns (uint256);
}

contract SemaphoreAnonymousJuryPool is Ownable, ReentrancyGuard {
    enum Verdict { UNDECIDED, PLAINTIFF, DEFENDANT, SETTLEMENT }

    struct AnonymousVote {
        bytes32 nullifierHash;
        bytes32 voteCommitment;
        Verdict verdict;
        uint256 timestamp;
    }

    struct JurySession {
        uint256 disputeId;
        uint256 semaphoreGroupId;
        uint256 minReputationThreshold;
        bool resolved;
        Verdict finalVerdict;
        uint256 resolutionTime;
        uint256 voteCount;
    }

    ISemaphore public semaphore;
    IReputationOracle public reputationOracle;
    address public juryRegistry;
    
    mapping(uint256 => JurySession) public sessions;
    mapping(uint256 => mapping(bytes32 => bool)) public nullifierHashes;
    mapping(uint256 => AnonymousVote[]) public sessionVotes;
    mapping(uint256 => bytes32) public sessionCredentialRequirements;

    uint256 public constant MIN_JURORS = 3;
    uint256 public constant MAX_JURORS = 101;
    uint256 public nextGroupId;
    uint256 public juryDepositAmount = 0.1 ether;

    event SessionCreated(uint256 indexed disputeId, uint256 indexed groupId, uint256 threshold);
    event AnonymousVoteSubmitted(uint256 indexed disputeId, bytes32 nullifierHash, Verdict verdict);
    event DisputeResolved(uint256 indexed disputeId, Verdict finalVerdict);
    event JuryDepositSlashed(bytes32 indexed nullifierHash, uint256 amount);

    error InvalidProof();
    error DoubleVoting();
    error SessionNotFound();
    error SessionAlreadyResolved();
    error InvalidVerdict();
    error MaxJurorsReached();
    error UnauthorizedJuryRegistry();
    error InvalidReputation();
    error InsufficientJurors();

    modifier onlyJuryRegistry() {
        if (msg.sender != juryRegistry) revert UnauthorizedJuryRegistry();
        _;
    }

    constructor(address _semaphore, address _reputationOracle) Ownable(msg.sender) {
        semaphore = ISemaphore(_semaphore);
        reputationOracle = IReputationOracle(_reputationOracle);
    }

    function setJuryRegistry(address _registry) external onlyOwner {
        juryRegistry = _registry;
    }

    function setJuryDeposit(uint256 amount) external onlyOwner {
        juryDepositAmount = amount;
    }

    function createSession(
        uint256 disputeId,
        uint256 minReputationThreshold,
        bytes32 credentialRequirementId
    ) external onlyOwner returns (uint256 groupId) {
        if (sessions[disputeId].disputeId != 0) revert SessionAlreadyResolved();
        
        groupId = nextGroupId++;
        
        sessions[disputeId] = JurySession({
            disputeId: disputeId,
            semaphoreGroupId: groupId,
            minReputationThreshold: minReputationThreshold,
            resolved: false,
            finalVerdict: Verdict.UNDECIDED,
            resolutionTime: 0,
            voteCount: 0
        });
        
        sessionCredentialRequirements[disputeId] = credentialRequirementId;

        emit SessionCreated(disputeId, groupId, minReputationThreshold);
    }

    /**
     * @notice Submit anonymous vote via Semaphore proof
     * @dev message encodes: (disputeId << 8) | uint256(verdict)
     * @dev scope = disputeId (prevents cross-dispute nullifier reuse)
     * @param proof Semaphore ZK proof of group membership
     * @param verdict The juror's verdict choice
     * @param voteCommitment Additional commitment for vote verification
     */
    function submitAnonymousVote(
        uint256 disputeId,
        ISemaphore.SemaphoreProof calldata proof,
        Verdict verdict,
        bytes32 voteCommitment
    ) external payable nonReentrant {
        JurySession storage session = sessions[disputeId];
        if (session.disputeId == 0) revert SessionNotFound();
        if (session.resolved) revert SessionAlreadyResolved();
        if (verdict == Verdict.UNDECIDED) revert InvalidVerdict();
        if (session.voteCount >= MAX_JURORS) revert MaxJurorsReached();

        // Verify proof message matches disputeId + verdict
        uint256 expectedMessage = (disputeId << 8) | uint256(verdict);
        if (proof.message != expectedMessage) revert InvalidProof();
        
        // Scope prevents nullifier reuse across disputes
        if (proof.scope != disputeId) revert InvalidProof();

        bytes32 nullifierHash = bytes32(proof.nullifier);
        if (nullifierHashes[disputeId][nullifierHash]) revert DoubleVoting();

        // Validate proof against Semaphore protocol
        semaphore.validateProof(session.semaphoreGroupId, proof);

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
        if (session.voteCount < MIN_JURORS) revert InsufficientJurors();

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

    function getSession(uint256 disputeId) external view returns (JurySession memory) {
        return sessions[disputeId];
    }
}
