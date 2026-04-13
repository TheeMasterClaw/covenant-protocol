// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICovenantGovernor} from "../interfaces/ICovenantGovernor.sol";
import {ICovenantToken} from "../interfaces/ICovenantToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CovenantGovernor
 * @notice DAO governance contract for the COVENANT protocol
 */
contract CovenantGovernor is ICovenantGovernor, Ownable, ReentrancyGuard {
    ICovenantToken public token;
    uint256 public proposalCount;
    uint256 public quorumVotes;
    uint256 public _votingDelay;
    uint256 public _votingPeriod;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => uint256) public delegatedVotes;

    constructor(address _token, uint256 _quorum, uint256 delay, uint256 period) Ownable(msg.sender) {
        token = ICovenantToken(_token);
        quorumVotes = _quorum;
        _votingDelay = delay;
        _votingPeriod = period;
    }

    /// @inheritdoc ICovenantGovernor
    function propose(
        address target,
        bytes calldata callData,
        string calldata description
    ) external returns (uint256 proposalId) {
        if (token.balanceOf(msg.sender) == 0) revert UnauthorizedProposer();
        if (target == address(0)) revert InvalidProposal();

        proposalId = ++proposalCount;
        uint256 start = block.timestamp + _votingDelay;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            callData: callData,
            target: target,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            startTime: start,
            endTime: start + _votingPeriod,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /// @inheritdoc ICovenantGovernor
    function castVote(uint256 proposalId, uint8 support) external {
        Proposal storage p = proposals[proposalId];
        if (block.timestamp < p.startTime) revert VotingNotStarted();
        if (block.timestamp > p.endTime) revert VotingEnded();
        if (hasVoted[proposalId][msg.sender]) revert InvalidProposal();
        if (support > 2) revert InvalidProposal();

        uint256 votes = token.balanceOf(msg.sender);
        hasVoted[proposalId][msg.sender] = true;

        if (support == 0) p.againstVotes += votes;
        else if (support == 1) p.forVotes += votes;
        else p.abstainVotes += votes;

        emit VoteCast(proposalId, msg.sender, support, votes);
    }

    /// @inheritdoc ICovenantGovernor
    function execute(uint256 proposalId) external nonReentrant {
        Proposal storage p = proposals[proposalId];
        if (block.timestamp <= p.endTime) revert VotingNotEnded();
        if (p.executed || p.canceled) revert ProposalAlreadyExecuted();
        if (p.forVotes <= p.againstVotes) revert ProposalNotPassed();
        if (p.forVotes + p.againstVotes + p.abstainVotes < quorumVotes) revert ProposalNotPassed();

        p.executed = true;

        (bool success, ) = p.target.call(p.callData);
        if (!success) revert ProposalNotPassed();

        emit ProposalExecuted(proposalId);
    }

    /// @inheritdoc ICovenantGovernor
    function cancel(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        if (p.proposer != msg.sender && msg.sender != owner()) revert UnauthorizedProposer();
        if (p.executed || p.canceled) revert ProposalAlreadyExecuted();

        p.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    /// @inheritdoc ICovenantGovernor
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return proposals[proposalId];
    }

    /// @inheritdoc ICovenantGovernor
    function getVotes(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    /// @inheritdoc ICovenantGovernor
    function quorum() external view returns (uint256) {
        return quorumVotes;
    }

    /// @inheritdoc ICovenantGovernor
    function votingDelay() external view returns (uint256) {
        return _votingDelay;
    }

    /// @inheritdoc ICovenantGovernor
    function votingPeriod() external view returns (uint256) {
        return _votingPeriod;
    }
}
