// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AIJuryPool
 * @notice Multi-agent jury coordination for AI-assisted dispute resolution
 */
contract AIJuryPool is Ownable {
    enum Verdict {
        UNDECIDED,
        PLAINTIFF,
        DEFENDANT,
        SETTLEMENT
    }

    struct JurorVote {
        address juror;
        bytes32 reasoningHash;
        Verdict verdict;
        uint256 weight;
        uint256 timestamp;
    }

    struct JurySession {
        uint256 disputeId;
        address[] selectedJurors;
        mapping(address => JurorVote) votes;
        bool resolved;
        Verdict finalVerdict;
        uint256 resolutionTime;
    }

    mapping(uint256 => JurySession) public sessions;
    mapping(address => bool) public registeredJurors;
    mapping(address => uint256) public jurorWeights;

    uint256 public constant MIN_JURORS = 3;
    uint256 public constant MAX_JURORS = 11;
    uint256 public constant JURY_SELECTION_SEED = 42;

    event JurySessionCreated(uint256 indexed disputeId, address[] jurors);
    event VoteSubmitted(uint256 indexed disputeId, address indexed juror, Verdict verdict);
    event DisputeResolved(uint256 indexed disputeId, Verdict finalVerdict);
    event JurorRegistered(address indexed juror, uint256 weight);

    error UnauthorizedJuror();
    error AlreadyVoted();
    error SessionNotFound();
    error SessionAlreadyResolved();
    error InsufficientJurors();

    function registerJuror(address juror, uint256 weight) external onlyOwner {
        registeredJurors[juror] = true;
        jurorWeights[juror] = weight;
        emit JurorRegistered(juror, weight);
    }

    function createSession(uint256 disputeId, address[] calldata candidateJurors) external onlyOwner {
        if (candidateJurors.length < MIN_JURORS) revert InsufficientJurors();

        // Select jurors pseudo-randomly (in production use Chainlink VRF)
        address[] memory selected = selectJurors(candidateJurors, MIN_JURORS);

        JurySession storage session = sessions[disputeId];
        session.disputeId = disputeId;
        session.selectedJurors = selected;

        emit JurySessionCreated(disputeId, selected);
    }

    function submitVote(
        uint256 disputeId,
        bytes32 reasoningHash,
        Verdict verdict
    ) external {
        if (!registeredJurors[msg.sender]) revert UnauthorizedJuror();

        JurySession storage session = sessions[disputeId];
        if (session.disputeId == 0) revert SessionNotFound();
        if (session.resolved) revert SessionAlreadyResolved();
        if (session.votes[msg.sender].timestamp != 0) revert AlreadyVoted();

        bool isSelected = false;
        for (uint i = 0; i < session.selectedJurors.length; i++) {
            if (session.selectedJurors[i] == msg.sender) {
                isSelected = true;
                break;
            }
        }
        if (!isSelected) revert UnauthorizedJuror();

        session.votes[msg.sender] = JurorVote({
            juror: msg.sender,
            reasoningHash: reasoningHash,
            verdict: verdict,
            weight: jurorWeights[msg.sender],
            timestamp: block.timestamp
        });

        emit VoteSubmitted(disputeId, msg.sender, verdict);
    }

    function resolveDispute(uint256 disputeId) external onlyOwner returns (Verdict finalVerdict) {
        JurySession storage session = sessions[disputeId];
        if (session.disputeId == 0) revert SessionNotFound();
        if (session.resolved) revert SessionAlreadyResolved();

        // Weighted voting tally
        uint256[4] memory tallies; // Index by Verdict enum

        for (uint i = 0; i < session.selectedJurors.length; i++) {
            address juror = session.selectedJurors[i];
            JurorVote memory vote = session.votes[juror];
            if (vote.timestamp > 0) {
                tallies[uint(vote.verdict)] += vote.weight;
            }
        }

        // Find verdict with max weight
        uint256 maxWeight = 0;
        for (uint v = 1; v < 4; v++) {
            if (tallies[v] > maxWeight) {
                maxWeight = tallies[v];
                finalVerdict = Verdict(v);
            }
        }

        session.finalVerdict = finalVerdict;
        session.resolved = true;
        session.resolutionTime = block.timestamp;

        emit DisputeResolved(disputeId, finalVerdict);
    }

    function selectJurors(address[] memory candidates, uint256 count) internal pure returns (address[] memory) {
        // Simplified: take first count candidates
        // Production: use VRF for random selection
        address[] memory selected = new address[](count);
        for (uint i = 0; i < count && i < candidates.length; i++) {
            selected[i] = candidates[i];
        }
        return selected;
    }

    function getVote(uint256 disputeId, address juror) external view returns (JurorVote memory) {
        return sessions[disputeId].votes[juror];
    }

    function getSelectedJurors(uint256 disputeId) external view returns (address[] memory) {
        return sessions[disputeId].selectedJurors;
    }
}
