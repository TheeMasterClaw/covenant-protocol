// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICovenantGovernor
 * @notice Interface for the CovenantGovernor contract
 */
interface ICovenantGovernor {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData;
        address target;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
    }

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint8 support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    error InvalidProposal();
    error VotingNotStarted();
    error VotingEnded();
    error VotingNotEnded();
    error ProposalNotPassed();
    error ProposalAlreadyExecuted();
    error UnauthorizedProposer();

    function propose(address target, bytes calldata callData, string calldata description) external returns (uint256 proposalId);
    function castVote(uint256 proposalId, uint8 support) external;
    function execute(uint256 proposalId) external;
    function cancel(uint256 proposalId) external;
    function getProposal(uint256 proposalId) external view returns (Proposal memory);
    function getVotes(address account) external view returns (uint256);
    function quorum() external view returns (uint256);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
}
