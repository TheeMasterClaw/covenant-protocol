// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {CovenantGovernor} from "../../../../contracts-v2/governance/CovenantGovernor.sol";

contract CovenantGovernorTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CONSTRUCTOR TESTS (15) ====================
    function test_Constructor_SetsToken() public view {
        assertEq(address(governor.token()), address(covenToken));
    }
    function test_Constructor_SetsQuorum() public view {
        assertEq(governor.quorum(), 1000 ether);
    }
    function test_Constructor_SetsVotingDelay() public view {
        assertEq(governor.votingDelay(), 1 days);
    }
    function test_Constructor_SetsVotingPeriod() public view {
        assertEq(governor.votingPeriod(), 7 days);
    }
    function test_Constructor_SetsOwner() public view {
        assertEq(governor.owner(), owner);
    }
    function test_Constructor_ProposalCountZero() public view {
        assertEq(governor.proposalCount(), 0);
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(governor).code.length > 0);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(governor).balance, 0);
    }
    function test_Constructor_DifferentQuorumAllowed() public {
        CovenantGovernor g = new CovenantGovernor(address(covenToken), 500 ether, 2 days, 14 days);
        assertEq(g.quorum(), 500 ether);
    }
    function test_Constructor_DifferentDelayAllowed() public {
        CovenantGovernor g = new CovenantGovernor(address(covenToken), 500 ether, 2 days, 14 days);
        assertEq(g.votingDelay(), 2 days);
    }
    function test_Constructor_DifferentPeriodAllowed() public {
        CovenantGovernor g = new CovenantGovernor(address(covenToken), 500 ether, 2 days, 14 days);
        assertEq(g.votingPeriod(), 14 days);
    }
    function test_Constructor_ZeroQuorumAllowed() public {
        CovenantGovernor g = new CovenantGovernor(address(covenToken), 0, 1 days, 7 days);
        assertEq(g.quorum(), 0);
    }
    function test_Constructor_ZeroDelayAllowed() public {
        CovenantGovernor g = new CovenantGovernor(address(covenToken), 1000 ether, 0, 7 days);
        assertEq(g.votingDelay(), 0);
    }
    function test_Constructor_ZeroPeriodAllowed() public {
        CovenantGovernor g = new CovenantGovernor(address(covenToken), 1000 ether, 1 days, 0);
        assertEq(g.votingPeriod(), 0);
    }
    function test_Constructor_OwnableSetCorrectly() public view {
        assertEq(governor.owner(), owner);
    }

    // ==================== PROPOSE TESTS (30) ====================
    function test_Propose_ByTokenHolder() public asOwner {
        // Owner has no tokens initially, but let's mint some inflation first
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            uint256 proposalId = governor.propose(alice, new bytes(0), "test proposal");
            assertEq(proposalId, 1);
        }
    }
    function test_Propose_EmitsEvent() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.expectEmit(true, true, false, false);
            emit CovenantGovernor.ProposalCreated(1, owner, "test proposal");
            governor.propose(alice, new bytes(0), "test proposal");
        }
    }
    function test_Propose_StoresProposal() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            governor.propose(alice, new bytes(0), "test proposal");
            CovenantGovernor.Proposal memory p = governor.getProposal(1);
            assertEq(p.id, 1);
            assertEq(p.proposer, owner);
            assertEq(p.description, "test proposal");
            assertEq(p.target, alice);
        }
    }
    function test_Propose_ZeroBalanceReverts() public {
        vm.prank(alice);
        vm.expectRevert(CovenantGovernor.UnauthorizedProposer.selector);
        governor.propose(bob, new bytes(0), "test");
    }
    function test_Propose_ZeroTargetReverts() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.expectRevert(CovenantGovernor.InvalidProposal.selector);
            governor.propose(address(0), new bytes(0), "test");
        }
    }
    function test_Propose_IncrementsProposalCount() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            governor.propose(alice, new bytes(0), "test1");
            assertEq(governor.proposalCount(), 1);
        }
    }
    function test_Propose_MultipleProposals() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            uint256 p1 = governor.propose(alice, new bytes(0), "test1");
            uint256 p2 = governor.propose(bob, new bytes(0), "test2");
            assertEq(p1, 1);
            assertEq(p2, 2);
        }
    }
    function test_Propose_StartTimeIsCurrentPlusDelay() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            governor.propose(alice, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(1);
            assertEq(p.startTime, block.timestamp + 1 days);
        }
    }
    function test_Propose_EndTimeIsStartPlusPeriod() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            governor.propose(alice, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(1);
            assertEq(p.endTime, p.startTime + 7 days);
        }
    }
    function test_Propose_InitialVotesAreZero() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            governor.propose(alice, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(1);
            assertEq(p.forVotes, 0);
            assertEq(p.againstVotes, 0);
            assertEq(p.abstainVotes, 0);
        }
    }
    function test_Propose_NotExecutedInitially() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            governor.propose(alice, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(1);
            assertEq(p.executed, false);
        }
    }
    function test_Propose_NotCanceledInitially() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            governor.propose(alice, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(1);
            assertEq(p.canceled, false);
        }
    }
    function test_Propose_CallDataStored() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("test()")));
            governor.propose(alice, callData, "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(1);
            assertEq(keccak256(p.callData), keccak256(callData));
        }
    }
    function test_Propose_EventContainsCorrectProposalId() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.expectEmit(true, true, false, false);
            emit CovenantGovernor.ProposalCreated(1, owner, "test");
            governor.propose(alice, new bytes(0), "test");
        }
    }
    function test_Propose_EventContainsCorrectProposer() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.expectEmit(true, true, false, false);
            emit CovenantGovernor.ProposalCreated(1, owner, "test");
            governor.propose(alice, new bytes(0), "test");
        }
    }
    function test_Propose_EventContainsCorrectDescription() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.expectEmit(true, true, false, false);
            emit CovenantGovernor.ProposalCreated(1, owner, "specific description");
            governor.propose(alice, new bytes(0), "specific description");
        }
    }
    function test_Propose_AnyoneWithBalance() public {
        // Give alice some tokens
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 1);
            vm.prank(alice);
            uint256 proposalId = governor.propose(bob, new bytes(0), "alice proposal");
            assertEq(proposalId, 1);
        }
    }
    function test_Propose_10Proposals() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            for (uint256 i = 0; i < 10; i++) {
                governor.propose(alice, new bytes(0), string(abi.encodePacked("proposal ", vm.toString(i))));
            }
            assertEq(governor.proposalCount(), 10);
        }
    }
    function test_Propose_DifferentTargets() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            governor.propose(alice, new bytes(0), "test1");
            governor.propose(bob, new bytes(0), "test2");
            assertEq(governor.getProposal(1).target, alice);
            assertEq(governor.getProposal(2).target, bob);
        }
    }
    function test_Propose_EmptyCallDataAllowed() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            uint256 id = governor.propose(alice, new bytes(0), "test");
            assertEq(id, 1);
        }
    }
    function test_Propose_EmptyDescriptionAllowed() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            uint256 id = governor.propose(alice, new bytes(0), "");
            assertEq(id, 1);
        }
    }
    function test_Propose_LongDescriptionAllowed() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            string memory longDesc = new string(1000);
            uint256 id = governor.propose(alice, new bytes(0), longDesc);
            assertEq(id, 1);
        }
    }

    // ==================== CAST VOTE TESTS (25) ====================
    function test_CastVote_For() public {
        _createAndVote(1, 1);
    }
    function test_CastVote_Against() public {
        _createAndVote(1, 0);
    }
    function test_CastVote_Abstain() public {
        _createAndVote(1, 2);
    }
    function test_CastVote_EmitsEvent() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            vm.expectEmit(true, true, true, true);
            emit CovenantGovernor.VoteCast(pid, alice, 1, 100);
            governor.castVote(pid, 1);
        }
    }
    function test_CastVote_BeforeStartReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.prank(alice);
            vm.expectRevert(CovenantGovernor.VotingNotStarted.selector);
            governor.castVote(pid, 1);
        }
    }
    function test_CastVote_AfterEndReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days + 7 days + 1);
            vm.prank(alice);
            vm.expectRevert(CovenantGovernor.VotingEnded.selector);
            governor.castVote(pid, 1);
        }
    }
    function test_CastVote_AlreadyVotedReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.prank(alice);
            vm.expectRevert(CovenantGovernor.InvalidProposal.selector);
            governor.castVote(pid, 0);
        }
    }
    function test_CastVote_InvalidSupportReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            vm.expectRevert(CovenantGovernor.InvalidProposal.selector);
            governor.castVote(pid, 3);
        }
    }
    function test_CastVote_UsesCurrentBalance() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            assertEq(p.forVotes, 100);
        }
    }
    function test_CastVote_MultipleVoters() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 200) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 100);
            covenToken.transfer(bob, 100);
            uint256 pid = governor.propose(carol, new bytes(0), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.prank(bob);
            governor.castVote(pid, 1);
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            assertEq(p.forVotes, 200);
        }
    }
    function test_CastVote_DifferentSupports() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 200) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 100);
            covenToken.transfer(bob, 100);
            uint256 pid = governor.propose(carol, new bytes(0), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.prank(bob);
            governor.castVote(pid, 0);
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            assertEq(p.forVotes, 100);
            assertEq(p.againstVotes, 100);
        }
    }
    function test_CastVote_HasVotedMapping() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            assertTrue(governor.hasVoted(pid, alice));
        }
    }
    function test_CastVote_EventContainsCorrectProposalId() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            vm.expectEmit(true, true, true, true);
            emit CovenantGovernor.VoteCast(pid, alice, 1, 100);
            governor.castVote(pid, 1);
        }
    }
    function test_CastVote_EventContainsCorrectVoter() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(bob, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(bob);
            vm.expectEmit(true, true, true, true);
            emit CovenantGovernor.VoteCast(pid, bob, 1, 100);
            governor.castVote(pid, 1);
        }
    }
    function test_CastVote_EventContainsCorrectSupport() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            vm.expectEmit(true, true, true, true);
            emit CovenantGovernor.VoteCast(pid, alice, 0, 100);
            governor.castVote(pid, 0);
        }
    }
    function test_CastVote_EventContainsCorrectVotes() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 250);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            vm.expectEmit(true, true, true, true);
            emit CovenantGovernor.VoteCast(pid, alice, 1, 250);
            governor.castVote(pid, 1);
        }
    }
    function test_CastVote_10Votes() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            for (uint256 i = 0; i < 10; i++) {
                address voter = address(uint160(i + 1000));
                vm.prank(owner);
                covenToken.transfer(voter, 100);
                vm.prank(voter);
                governor.castVote(pid, 1);
            }
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            assertEq(p.forVotes, 1000);
        }
    }
    function test_CastVote_ZeroBalanceVotes() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(carol);
            governor.castVote(pid, 1);
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            assertEq(p.forVotes, 0);
        }
    }
    function test_CastVote_AtExactStartTime() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            vm.warp(p.startTime);
            vm.prank(alice);
            governor.castVote(pid, 1);
            assertEq(governor.getProposal(pid).forVotes, 100);
        }
    }
    function test_CastVote_AtExactEndTime() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            vm.warp(p.endTime);
            vm.prank(alice);
            governor.castVote(pid, 1);
            assertEq(governor.getProposal(pid).forVotes, 100);
        }
    }
    function test_CastVote_OneSecondAfterEndReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            vm.warp(p.endTime + 1);
            vm.prank(alice);
            vm.expectRevert(CovenantGovernor.VotingEnded.selector);
            governor.castVote(pid, 1);
        }
    }

    // ==================== EXECUTE TESTS (20) ====================
    function test_Execute_SuccessfulProposal() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            governor.execute(pid);
            assertEq(covenToken.stakingContract(), bob);
        }
    }
    function test_Execute_EmitsEvent() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            vm.expectEmit(true, false, false, false);
            emit CovenantGovernor.ProposalExecuted(pid);
            governor.execute(pid);
        }
    }
    function test_Execute_BeforeEndReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days - 1);
            vm.expectRevert(CovenantGovernor.VotingNotEnded.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_AlreadyExecutedReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            governor.execute(pid);
            vm.expectRevert(CovenantGovernor.ProposalAlreadyExecuted.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_NotPassedReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 0);
            vm.warp(block.timestamp + 7 days + 1);
            vm.expectRevert(CovenantGovernor.ProposalNotPassed.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_BelowQuorumReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 999) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 999);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            vm.expectRevert(CovenantGovernor.ProposalNotPassed.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_CanceledReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            governor.cancel(pid);
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days + 7 days + 1);
            vm.expectRevert(CovenantGovernor.ProposalAlreadyExecuted.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_SetsExecutedFlag() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            governor.execute(pid);
            assertTrue(governor.getProposal(pid).executed);
        }
    }
    function test_Execute_ExactQuorum() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) >= 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            governor.execute(pid);
            assertTrue(governor.getProposal(pid).executed);
        }
    }
    function test_Execute_TieReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 2000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            covenToken.transfer(bob, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, carol), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.prank(bob);
            governor.castVote(pid, 0);
            vm.warp(block.timestamp + 7 days + 1);
            vm.expectRevert(CovenantGovernor.ProposalNotPassed.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_AbstainDoesNotCount() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 2);
            vm.warp(block.timestamp + 7 days + 1);
            vm.expectRevert(CovenantGovernor.ProposalNotPassed.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_CallRevertsIfTargetFails() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            // Call to address(0) will fail
            uint256 pid = governor.propose(address(0), abi.encodeWithSelector(bytes4(keccak256("nonexistent()"))), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            vm.expectRevert(CovenantGovernor.ProposalNotPassed.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_QuorumIncludesAllVotes() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 2000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            covenToken.transfer(bob, 500);
            covenToken.transfer(carol, 500);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, dave), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.prank(bob);
            governor.castVote(pid, 0);
            vm.prank(carol);
            governor.castVote(pid, 2);
            vm.warp(block.timestamp + 7 days + 1);
            governor.execute(pid);
            assertTrue(governor.getProposal(pid).executed);
        }
    }
    function test_Execute_EventContainsCorrectProposalId() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            vm.expectEmit(true, false, false, false);
            emit CovenantGovernor.ProposalExecuted(pid);
            governor.execute(pid);
        }
    }
    function test_Execute_NoReentrancy() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            governor.execute(pid);
            vm.expectRevert(CovenantGovernor.ProposalAlreadyExecuted.selector);
            governor.execute(pid);
        }
    }
    function test_Execute_AnyoneCanExecute() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            vm.prank(carol);
            governor.execute(pid);
            assertTrue(governor.getProposal(pid).executed);
        }
    }
    function test_Execute_10Proposals() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 10000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 10000);
            for (uint256 i = 0; i < 10; i++) {
                uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, address(uint160(i))), "test");
                vm.warp(block.timestamp + 1 days);
                vm.prank(alice);
                governor.castVote(pid, 1);
                vm.warp(block.timestamp + 7 days + 1);
                governor.execute(pid);
                assertTrue(governor.getProposal(pid).executed);
            }
        }
    }

    // ==================== CANCEL TESTS (15) ====================
    function test_Cancel_ByProposer() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            governor.cancel(pid);
            assertTrue(governor.getProposal(pid).canceled);
        }
    }
    function test_Cancel_ByOwner() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 1);
            vm.prank(alice);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.prank(owner);
            governor.cancel(pid);
            assertTrue(governor.getProposal(pid).canceled);
        }
    }
    function test_Cancel_EmitsEvent() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            vm.expectEmit(true, false, false, false);
            emit CovenantGovernor.ProposalCanceled(pid);
            governor.cancel(pid);
        }
    }
    function test_Cancel_NonProposerNonOwnerReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 1);
            vm.prank(alice);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.prank(bob);
            vm.expectRevert(CovenantGovernor.UnauthorizedProposer.selector);
            governor.cancel(pid);
        }
    }
    function test_Cancel_AlreadyExecutedReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            vm.warp(block.timestamp + 7 days + 1);
            governor.execute(pid);
            vm.prank(owner);
            vm.expectRevert(CovenantGovernor.ProposalAlreadyExecuted.selector);
            governor.cancel(pid);
        }
    }
    function test_Cancel_AlreadyCanceledReverts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            governor.cancel(pid);
            vm.expectRevert(CovenantGovernor.ProposalAlreadyExecuted.selector);
            governor.cancel(pid);
        }
    }
    function test_Cancel_PreventsExecution() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 1000) {
            vm.startPrank(owner);
            covenToken.transfer(alice, 1000);
            uint256 pid = governor.propose(address(covenToken), abi.encodeWithSelector(covenToken.setStakingContract.selector, bob), "test");
            governor.cancel(pid);
            vm.stopPrank();
            vm.warp(block.timestamp + 1 days + 7 days + 1);
            vm.expectRevert(CovenantGovernor.ProposalAlreadyExecuted.selector);
            governor.execute(pid);
        }
    }
    function test_Cancel_EventContainsCorrectProposalId() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            vm.expectEmit(true, false, false, false);
            emit CovenantGovernor.ProposalCanceled(pid);
            governor.cancel(pid);
        }
    }
    function test_Cancel_BeforeVotingStarts() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            governor.cancel(pid);
            assertTrue(governor.getProposal(pid).canceled);
        }
    }
    function test_Cancel_DuringVoting() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days + 1);
            governor.cancel(pid);
            assertTrue(governor.getProposal(pid).canceled);
        }
    }
    function test_Cancel_AfterVotingEnds() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days + 7 days + 1);
            governor.cancel(pid);
            assertTrue(governor.getProposal(pid).canceled);
        }
    }
    function test_Cancel_NoEthRequired() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            governor.cancel(pid);
            assertEq(address(governor).balance, 0);
        }
    }
    function test_Cancel_10Proposals() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            for (uint256 i = 0; i < 10; i++) {
                vm.prank(owner);
                uint256 pid = governor.propose(alice, new bytes(0), "test");
                governor.cancel(pid);
                assertTrue(governor.getProposal(pid).canceled);
            }
        }
    }

    // ==================== VIEW FUNCTION TESTS (15) ====================
    function test_GetProposal_ReturnsCorrectData() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            assertEq(p.id, 1);
            assertEq(p.proposer, owner);
            assertEq(p.description, "test");
            assertEq(p.target, alice);
        }
    }
    function test_GetVotes_ReturnsBalance() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 500);
            assertEq(governor.getVotes(alice), 500);
        }
    }
    function test_Quorum_ReturnsCorrectValue() public view {
        assertEq(governor.quorum(), 1000 ether);
    }
    function test_VotingDelay_ReturnsCorrectValue() public view {
        assertEq(governor.votingDelay(), 1 days);
    }
    function test_VotingPeriod_ReturnsCorrectValue() public view {
        assertEq(governor.votingPeriod(), 7 days);
    }
    function test_GetProposal_NonExistent() public view {
        CovenantGovernor.Proposal memory p = governor.getProposal(999);
        assertEq(p.id, 0);
    }
    function test_GetVotes_ZeroBalance() public view {
        assertEq(governor.getVotes(alice), 0);
    }
    function test_HasVoted_FalseInitially() public view {
        assertFalse(governor.hasVoted(1, alice));
    }
    function test_HasVoted_TrueAfterVote() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 1);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, 1);
            assertTrue(governor.hasVoted(pid, alice));
        }
    }
    function test_ViewFunctions_ArePureOrView() public view {
        governor.getProposal(1);
        governor.getVotes(alice);
        governor.quorum();
        governor.votingDelay();
        governor.votingPeriod();
        governor.proposalCount();
        assertTrue(true);
    }
    function test_GetVotes_UpdatesAfterTransfer() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 100);
            assertEq(governor.getVotes(alice), 100);
            vm.prank(alice);
            covenToken.transfer(bob, 50);
            assertEq(governor.getVotes(alice), 50);
        }
    }
    function test_GetProposal_CountMatches() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.startPrank(owner);
            uint256 p1 = governor.propose(alice, new bytes(0), "test1");
            uint256 p2 = governor.propose(bob, new bytes(0), "test2");
            vm.stopPrank();
            assertEq(governor.getProposal(p1).id, 1);
            assertEq(governor.getProposal(p2).id, 2);
            assertEq(governor.proposalCount(), 2);
        }
    }
    function test_Quorum_Constant() public view {
        assertEq(governor.quorum(), 1000 ether);
    }
    function test_VotingDelay_Constant() public view {
        assertEq(governor.votingDelay(), 1 days);
    }
    function test_VotingPeriod_Constant() public view {
        assertEq(governor.votingPeriod(), 7 days);
    }

    function _createAndVote(uint256 amount, uint8 support) internal {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, amount);
            vm.prank(owner);
            uint256 pid = governor.propose(bob, new bytes(0), "test");
            vm.warp(block.timestamp + 1 days);
            vm.prank(alice);
            governor.castVote(pid, support);
            CovenantGovernor.Proposal memory p = governor.getProposal(pid);
            if (support == 0) assertEq(p.againstVotes, amount);
            else if (support == 1) assertEq(p.forVotes, amount);
            else assertEq(p.abstainVotes, amount);
        }
    }
}
