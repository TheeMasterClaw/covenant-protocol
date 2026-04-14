// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDisputeVoting} from "../interfaces/IDisputeVoting.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DisputeVoting
 * @notice Voting mechanics for disputes
 */
contract DisputeVoting is IDisputeVoting, Ownable {
    mapping(uint256 => mapping(address => Vote)) public votes;
    mapping(uint256 => uint256[3]) public voteTallies;
    mapping(uint256 => bool) public votingOpen;
    mapping(uint256 => bool) public votingClosed;
    mapping(uint256 => uint256) public votingEndTimes;
    mapping(uint256 => mapping(address => bool)) public voterRegistry;
    uint256 public votingPeriod = 5 days;

    modifier onlyRegisteredVoter(uint256 disputeId) {
        if (!voterRegistry[disputeId][msg.sender]) revert UnauthorizedVoter();
        _;
    }

    constructor() Ownable(msg.sender) {}

    function openVoting(uint256 disputeId, address[] calldata voters) external onlyOwner {
        if (votingOpen[disputeId]) revert VotingNotOpen();
        votingOpen[disputeId] = true;
        votingClosed[disputeId] = false;
        votingEndTimes[disputeId] = block.timestamp + votingPeriod;

        for (uint256 i = 0; i < voters.length; ) {
            voterRegistry[disputeId][voters[i]] = true;
            unchecked { ++i; }
        }
    }

    /// @inheritdoc IDisputeVoting
    function castVote(uint256 disputeId, uint8 choice) external onlyRegisteredVoter(disputeId) {
        if (!votingOpen[disputeId]) revert VotingNotOpen();
        if (votingClosed[disputeId]) revert VotingAlreadyClosed();
        if (block.timestamp > votingEndTimes[disputeId]) revert VotingEnded();
        if (choice > 2) revert InvalidChoice();
        if (votes[disputeId][msg.sender].timestamp != 0) revert AlreadyVoted();

        votes[disputeId][msg.sender] = Vote({
            voter: msg.sender,
            choice: choice,
            weight: 1,
            timestamp: block.timestamp
        });

        voteTallies[disputeId][choice]++;

        emit VoteCast(disputeId, msg.sender, choice, 1);
    }

    /// @inheritdoc IDisputeVoting
    function closeVoting(uint256 disputeId) external onlyOwner returns (uint8 outcome) {
        if (!votingOpen[disputeId]) revert VotingNotOpen();
        if (votingClosed[disputeId]) revert VotingAlreadyClosed();
        if (block.timestamp <= votingEndTimes[disputeId]) revert VotingNotEnded();

        votingClosed[disputeId] = true;
        votingOpen[disputeId] = false;

        uint256[3] storage tally = voteTallies[disputeId];
        uint256 maxVotes = tally[0];
        outcome = 0;

        for (uint8 i = 1; i < 3; ) {
            if (tally[i] > maxVotes) {
                maxVotes = tally[i];
                outcome = i;
            }
            unchecked { ++i; }
        }

        emit VotingClosed(disputeId, outcome);
    }

    /// @inheritdoc IDisputeVoting
    function getVote(uint256 disputeId, address voter) external view returns (Vote memory) {
        return votes[disputeId][voter];
    }

    /// @inheritdoc IDisputeVoting
    function getVoteTally(uint256 disputeId) external view returns (uint256[3] memory) {
        return voteTallies[disputeId];
    }

    /// @inheritdoc IDisputeVoting
    function hasVoted(uint256 disputeId, address voter) external view returns (bool) {
        return votes[disputeId][voter].timestamp != 0;
    }

    /// @inheritdoc IDisputeVoting
    function getVotingEndTime(uint256 disputeId) external view returns (uint256) {
        return votingEndTimes[disputeId];
    }

    function setVotingPeriod(uint256 period) external onlyOwner {
        votingPeriod = period;
    }
}