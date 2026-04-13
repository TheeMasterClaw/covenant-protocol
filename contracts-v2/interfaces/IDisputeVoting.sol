// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IDisputeVoting
 * @notice Interface for the DisputeVoting contract
 */
interface IDisputeVoting {
    struct Vote {
        address voter;
        uint8 choice; // 0: Abstain, 1: For Initiator, 2: For Respondent
        uint256 weight;
        uint256 timestamp;
    }

    event VoteCast(uint256 indexed disputeId, address indexed voter, uint8 choice, uint256 weight);
    event VotingClosed(uint256 indexed disputeId, uint8 outcome);

    error VotingNotOpen();
    error VotingAlreadyClosed();
    error VotingEnded();
    error VotingNotEnded();
    error AlreadyVoted();
    error InvalidChoice();
    error UnauthorizedVoter();

    function castVote(uint256 disputeId, uint8 choice) external;
    function closeVoting(uint256 disputeId) external returns (uint8 outcome);
    function getVote(uint256 disputeId, address voter) external view returns (Vote memory);
    function getVoteTally(uint256 disputeId) external view returns (uint256[3] memory tally);
    function hasVoted(uint256 disputeId, address voter) external view returns (bool);
    function getVotingEndTime(uint256 disputeId) external view returns (uint256);
}
