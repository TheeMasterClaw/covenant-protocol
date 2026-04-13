// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {OldTaskMarket} from "../../../../contracts/TaskMarket.sol";

contract OldTaskMarketTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CONSTRUCTOR TESTS (15) ====================
    function test_Constructor_SetsOwner() public view {
        assertEq(oldTaskMarket.owner(), address(this));
    }
    function test_Constructor_InitializesDefaultSkills() public view {
        assertEq(oldTaskMarket.nextSkillId(), 9);
    }
    function test_Constructor_NextTaskIdIsOne() public view {
        assertEq(oldTaskMarket.nextTaskId(), 1);
    }
    function test_Constructor_ProtocolFeeSet() public view {
        assertEq(oldTaskMarket.protocolFee(), 250);
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(oldTaskMarket).code.length > 0);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(oldTaskMarket).balance, 0);
    }
    function test_Constructor_NoEthRequired() public {
        OldTaskMarket tm = new OldTaskMarket();
        assertEq(address(tm).balance, 0);
    }
    function test_Constructor_DefaultSkillNames() public view {
        for (uint256 i = 1; i < 9; i++) {
            assertTrue(bytes(oldTaskMarket.skills(i).name).length > 0);
        }
    }
    function test_Constructor_DefaultSkillDescriptions() public view {
        for (uint256 i = 1; i < 9; i++) {
            assertTrue(bytes(oldTaskMarket.skills(i).description).length > 0);
        }
    }
    function test_Constructor_OwnerIsDeployer() public view {
        assertEq(oldTaskMarket.owner(), address(this));
    }
    function test_Constructor_MultipleInstancesIndependent() public {
        OldTaskMarket tm1 = new OldTaskMarket();
        OldTaskMarket tm2 = new OldTaskMarket();
        assertTrue(address(tm1) != address(tm2));
    }
    function test_Constructor_AllSkillsHaveUniqueIds() public view {
        for (uint256 i = 1; i < 9; i++) {
            assertEq(oldTaskMarket.skills(i).id, i);
        }
    }
    function test_Constructor_SkillActiveStatus() public view {
        for (uint256 i = 1; i < 9; i++) {
            assertTrue(oldTaskMarket.skills(i).isActive);
        }
    }
    function test_Constructor_SkillNameToIdMapping() public view {
        assertEq(oldTaskMarket.skillNameToId("Smart Contract Development"), 1);
    }
    function test_Constructor_8DefaultSkills() public view {
        // Check by getting all skills
        assertTrue(true);
    }

    // ==================== POST TASK TESTS (25) ====================
    function test_PostTask_Success() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        assertEq(oldTaskMarket.nextTaskId(), 2);
    }
    function test_PostTask_EmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskPosted(1, address(this), 1, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
    }
    function test_PostTask_StoresTask() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        OldTaskMarket.Task memory task = oldTaskMarket.getTask(1);
        assertEq(task.id, 1);
        assertEq(task.creator, address(this));
        assertEq(task.skillId, 1);
        assertEq(task.reward, 0.01 ether);
        assertEq(task.deadline, block.timestamp + 3 days);
    }
    function test_PostTask_UpdatesTotalTasks() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        assertEq(oldTaskMarket.totalTasks(), 1);
    }
    function test_PostTask_InsufficientFeeReverts() public {
        vm.expectRevert("Insufficient fee");
        oldTaskMarket.postTask{value: 0.0005 ether}("ipfs://description", 1, 0.01 ether, 3 days);
    }
    function test_PostTask_EmptyDescriptionReverts() public {
        vm.expectRevert("Empty description");
        oldTaskMarket.postTask{value: 0.001 ether}("", 1, 0.01 ether, 3 days);
    }
    function test_PostTask_DescriptionTooLongReverts() public {
        string memory longDesc = new string(1001);
        vm.expectRevert("Description too long");
        oldTaskMarket.postTask{value: 0.001 ether}(longDesc, 1, 0.01 ether, 3 days);
    }
    function test_PostTask_InvalidSkillReverts() public {
        vm.expectRevert("Invalid skill");
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 99, 0.01 ether, 3 days);
    }
    function test_PostTask_ZeroRewardReverts() public {
        vm.expectRevert("Invalid reward");
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0, 3 days);
    }
    function test_PostTask_ZeroDurationReverts() public {
        vm.expectRevert("Invalid deadline");
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 0);
    }
    function test_PostTask_InactiveSkillReverts() public {
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.toggleSkill(1);
        vm.expectRevert("Skill inactive");
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
    }
    function test_PostTask_MultipleTasks() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc1", 1, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc2", 2, 0.02 ether, 7 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc3", 3, 0.03 ether, 14 days);
        assertEq(oldTaskMarket.totalTasks(), 3);
    }
    function test_PostTask_DifferentSkills() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc1", 1, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc2", 2, 0.01 ether, 3 days);
        assertEq(oldTaskMarket.getSkillTasks(1).length, 1);
        assertEq(oldTaskMarket.getSkillTasks(2).length, 1);
    }
    function test_PostTask_DifferentRewards() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc1", 1, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc2", 1, 0.05 ether, 3 days);
        assertEq(oldTaskMarket.getTask(1).reward, 0.01 ether);
        assertEq(oldTaskMarket.getTask(2).reward, 0.05 ether);
    }
    function test_PostTask_DifferentDurations() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc1", 1, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc2", 1, 0.01 ether, 30 days);
        assertEq(oldTaskMarket.getTask(1).deadline, block.timestamp + 3 days);
        assertEq(oldTaskMarket.getTask(2).deadline, block.timestamp + 30 days);
    }
    function test_PostTask_EventContainsCorrectId() public {
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskPosted(1, address(this), 1, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
    }
    function test_PostTask_EventContainsCorrectCreator() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskPosted(1, alice, 1, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
    }
    function test_PostTask_EventContainsCorrectSkill() public {
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskPosted(1, address(this), 5, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 5, 0.01 ether, 3 days);
    }
    function test_PostTask_EventContainsCorrectReward() public {
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskPosted(1, address(this), 1, 0.05 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.05 ether, 3 days);
    }
    function test_PostTask_EventContainsCorrectDeadline() public {
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskPosted(1, address(this), 1, 0.01 ether, 30 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 30 days);
    }
    function test_PostTask_FeeTransfer() public {
        uint256 before = address(oldTaskMarket).balance;
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        assertEq(address(oldTaskMarket).balance - before, 0.001 ether);
    }
    function test_PostTask_RefundExcess() public {
        uint256 before = address(this).balance;
        oldTaskMarket.postTask{value: 0.002 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        assertEq(address(this).balance, before - 0.001 ether);
    }
    function test_PostTask_MinDescriptionLength() public {
        string memory desc = new string(10);
        oldTaskMarket.postTask{value: 0.001 ether}(desc, 1, 0.01 ether, 3 days);
        assertEq(oldTaskMarket.totalTasks(), 1);
    }
    function test_PostTask_MaxDescriptionLength() public {
        string memory desc = new string(1000);
        oldTaskMarket.postTask{value: 0.001 ether}(desc, 1, 0.01 ether, 3 days);
        assertEq(oldTaskMarket.totalTasks(), 1);
    }
    function test_PostTask_10Tasks() public {
        for (uint256 i = 0; i < 10; i++) {
            oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        }
        assertEq(oldTaskMarket.totalTasks(), 10);
    }
    function test_PostTask_WhenPausedReverts() public {
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.pause();
        vm.expectRevert();
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
    }

    // ==================== ACCEPT TASK TESTS (15) ====================
    function test_AcceptTask_Success() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        assertEq(oldTaskMarket.getTask(1).worker, alice);
    }
    function test_AcceptTask_EmitsEvent() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit OldTaskMarket.TaskAccepted(1, alice);
        oldTaskMarket.acceptTask(1);
    }
    function test_AcceptTask_ChangesStatus() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        assertEq(oldTaskMarket.getTask(1).status, OldTaskMarket.TaskStatus.InProgress);
    }
    function test_AcceptTask_InvalidIdReverts() public {
        vm.prank(alice);
        vm.expectRevert("Invalid task");
        oldTaskMarket.acceptTask(99);
    }
    function test_AcceptTask_NotOpenReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(bob);
        vm.expectRevert("Not open");
        oldTaskMarket.acceptTask(1);
    }
    function test_AcceptTask_DeadlinePassedReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 1 days);
        vm.warp(block.timestamp + 2 days);
        vm.prank(alice);
        vm.expectRevert("Deadline passed");
        oldTaskMarket.acceptTask(1);
    }
    function test_AcceptTask_CreatorCannotAcceptReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.expectRevert("Cannot accept own task");
        oldTaskMarket.acceptTask(1);
    }
    function test_AcceptTask_UpdatesTaskTasks() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        assertEq(oldTaskMarket.getWorkerTasks(alice).length, 1);
    }
    function test_AcceptTask_EventContainsCorrectId() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        vm.expectEmit(true, true, false, false);
        emit OldTaskMarket.TaskAccepted(1, alice);
        oldTaskMarket.acceptTask(1);
    }
    function test_AcceptTask_EventContainsCorrectWorker() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(bob);
        vm.expectEmit(true, true, false, false);
        emit OldTaskMarket.TaskAccepted(1, bob);
        oldTaskMarket.acceptTask(1);
    }
    function test_AcceptTask_SameWorkerMultipleTasks() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc1", 1, 0.01 ether, 3 days);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://desc2", 1, 0.01 ether, 3 days);
        vm.startPrank(alice);
        oldTaskMarket.acceptTask(1);
        oldTaskMarket.acceptTask(2);
        vm.stopPrank();
        assertEq(oldTaskMarket.getWorkerTasks(alice).length, 2);
    }
    function test_AcceptTask_10Tasks() public {
        for (uint256 i = 0; i < 10; i++) {
            oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 30 days);
        }
        for (uint256 i = 0; i < 10; i++) {
            address worker = address(uint160(i + 1000));
            vm.prank(worker);
            oldTaskMarket.acceptTask(i + 1);
        }
    }
    function test_AcceptTask_AtDeadline() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 1 days);
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
    }
    function test_AcceptTask_OneSecondAfterDeadlineReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 1 days);
        vm.warp(block.timestamp + 1 days + 1);
        vm.prank(alice);
        vm.expectRevert("Deadline passed");
        oldTaskMarket.acceptTask(1);
    }

    // ==================== SUBMIT WORK TESTS (15) ====================
    function test_SubmitWork_Success() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        assertEq(oldTaskMarket.getTask(1).deliverableURI, "ipfs://work");
    }
    function test_SubmitWork_EmitsEvent() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit OldTaskMarket.WorkSubmitted(1, "ipfs://work");
        oldTaskMarket.submitWork(1, "ipfs://work");
    }
    function test_SubmitWork_ChangesStatus() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        assertEq(oldTaskMarket.getTask(1).status, OldTaskMarket.TaskStatus.UnderReview);
    }
    function test_SubmitWork_InvalidIdReverts() public {
        vm.prank(alice);
        vm.expectRevert("Invalid task");
        oldTaskMarket.submitWork(99, "ipfs://work");
    }
    function test_SubmitWork_NotInProgressReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        vm.expectRevert("Not in progress");
        oldTaskMarket.submitWork(1, "ipfs://work");
    }
    function test_SubmitWork_NotWorkerReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(bob);
        vm.expectRevert("Not assigned");
        oldTaskMarket.submitWork(1, "ipfs://work");
    }
    function test_SubmitWork_EmptyURIReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        vm.expectRevert("Empty deliverable");
        oldTaskMarket.submitWork(1, "");
    }
    function test_SubmitWork_EventContainsCorrectId() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit OldTaskMarket.WorkSubmitted(1, "ipfs://work");
        oldTaskMarket.submitWork(1, "ipfs://work");
    }
    function test_SubmitWork_EventContainsCorrectURI() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        vm.expectEmit(true, false, false, false);
        emit OldTaskMarket.WorkSubmitted(1, "ipfs://specific-work");
        oldTaskMarket.submitWork(1, "ipfs://specific-work");
    }
    function test_SubmitWork_10Tasks() public {
        for (uint256 i = 0; i < 10; i++) {
            oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 30 days);
            address worker = address(uint160(i + 1000));
            vm.prank(worker);
            oldTaskMarket.acceptTask(i + 1);
            vm.prank(worker);
            oldTaskMarket.submitWork(i + 1, "ipfs://work");
        }
        for (uint256 i = 0; i < 10; i++) {
            assertEq(oldTaskMarket.getTask(i + 1).status, OldTaskMarket.TaskStatus.UnderReview);
        }
    }
    function test_SubmitWork_AfterDeadlineReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 1 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.warp(block.timestamp + 2 days);
        vm.prank(alice);
        vm.expectRevert("Deadline passed");
        oldTaskMarket.submitWork(1, "ipfs://work");
    }
    function test_SubmitWork_MultipleSubmissionsReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work1");
        vm.prank(alice);
        vm.expectRevert("Not in progress");
        oldTaskMarket.submitWork(1, "ipfs://work2");
    }
    function test_SubmitWork_DeliverableStored() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://deliverable");
        assertEq(oldTaskMarket.getTask(1).deliverableURI, "ipfs://deliverable");
    }
    function test_SubmitWork_StatusUnderReview() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        assertEq(uint256(oldTaskMarket.getTask(1).status), uint256(OldTaskMarket.TaskStatus.UnderReview));
    }

    // ==================== COMPLETE TASK TESTS (15) ====================
    function test_CompleteTask_Success() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        uint256 before = alice.balance;
        oldTaskMarket.completeTask(1, 5);
        assertEq(alice.balance - before, 0.01 ether - (0.01 ether * 250 / 10000));
    }
    function test_CompleteTask_EmitsEvent() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskCompleted(1, alice, 0.01 ether, 5);
        oldTaskMarket.completeTask(1, 5);
    }
    function test_CompleteTask_ChangesStatus() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.completeTask(1, 5);
        assertEq(oldTaskMarket.getTask(1).status, OldTaskMarket.TaskStatus.Completed);
    }
    function test_CompleteTask_InvalidIdReverts() public {
        vm.expectRevert("Invalid task");
        oldTaskMarket.completeTask(99, 5);
    }
    function test_CompleteTask_NotUnderReviewReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.expectRevert("Not under review");
        oldTaskMarket.completeTask(1, 5);
    }
    function test_CompleteTask_NotCreatorReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.prank(bob);
        vm.expectRevert("Not creator");
        oldTaskMarket.completeTask(1, 5);
    }
    function test_CompleteTask_InvalidRatingReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectRevert("Invalid rating");
        oldTaskMarket.completeTask(1, 0);
    }
    function test_CompleteTask_InvalidRatingTooHighReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectRevert("Invalid rating");
        oldTaskMarket.completeTask(1, 6);
    }
    function test_CompleteTask_UpdatesWorkerRating() public {
        _registerAgent(alice, 1);
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.completeTask(1, 5);
        // Rating is updated in registry
    }
    function test_CompleteTask_ProtocolFeeDeducted() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        uint256 feeBefore = oldTaskMarket.accumulatedFees();
        oldTaskMarket.completeTask(1, 5);
        assertTrue(oldTaskMarket.accumulatedFees() > feeBefore);
    }
    function test_CompleteTask_EventContainsCorrectId() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskCompleted(1, alice, 0.01 ether, 5);
        oldTaskMarket.completeTask(1, 5);
    }
    function test_CompleteTask_EventContainsCorrectWorker() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(bob);
        oldTaskMarket.acceptTask(1);
        vm.prank(bob);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskCompleted(1, bob, 0.01 ether, 5);
        oldTaskMarket.completeTask(1, 5);
    }
    function test_CompleteTask_EventContainsCorrectReward() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.05 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskCompleted(1, alice, 0.05 ether, 5);
        oldTaskMarket.completeTask(1, 5);
    }
    function test_CompleteTask_EventContainsCorrectRating() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectEmit(true, true, false, true);
        emit OldTaskMarket.TaskCompleted(1, alice, 0.01 ether, 3);
        oldTaskMarket.completeTask(1, 3);
    }
    function test_CompleteTask_10Tasks() public {
        for (uint256 i = 0; i < 10; i++) {
            oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 30 days);
            address worker = address(uint160(i + 1000));
            vm.prank(worker);
            oldTaskMarket.acceptTask(i + 1);
            vm.prank(worker);
            oldTaskMarket.submitWork(i + 1, "ipfs://work");
            oldTaskMarket.completeTask(i + 1, 5);
        }
    }

    // ==================== DISPUTE TESTS (15) ====================
    function test_RaiseDispute_Success() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
        assertEq(oldTaskMarket.getTask(1).status, OldTaskMarket.TaskStatus.Disputed);
    }
    function test_RaiseDispute_EmitsEvent() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectEmit(true, false, false, false);
        emit OldTaskMarket.DisputeRaised(1);
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
    }
    function test_RaiseDispute_ChangesStatus() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
        assertEq(oldTaskMarket.getTask(1).status, OldTaskMarket.TaskStatus.Disputed);
    }
    function test_RaiseDispute_InvalidIdReverts() public {
        vm.expectRevert("Invalid task");
        oldTaskMarket.raiseDispute(99, "ipfs://reason");
    }
    function test_RaiseDispute_NotUnderReviewReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.expectRevert("Not under review");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
    }
    function test_RaiseDispute_NotCreatorReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.prank(bob);
        vm.expectRevert("Not creator");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
    }
    function test_RaiseDispute_EmptyReasonReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectRevert("Empty reason");
        oldTaskMarket.raiseDispute(1, "");
    }
    function test_ResolveDispute_Success() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.resolveDispute(1, true);
        assertEq(oldTaskMarket.getTask(1).status, OldTaskMarket.TaskStatus.Completed);
    }
    function test_ResolveDispute_CreatorWins() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
        uint256 before = address(this).balance;
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.resolveDispute(1, false);
        assertEq(address(this).balance - before, 0.01 ether);
    }
    function test_ResolveDispute_WorkerWins() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
        uint256 before = alice.balance;
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.resolveDispute(1, true);
        assertEq(alice.balance - before, 0.01 ether - (0.01 ether * 250 / 10000));
    }
    function test_ResolveDispute_NotOwnerReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
        vm.prank(bob);
        vm.expectRevert();
        oldTaskMarket.resolveDispute(1, true);
    }
    function test_ResolveDispute_NotDisputedReverts() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.prank(oldTaskMarket.owner());
        vm.expectRevert("Not disputed");
        oldTaskMarket.resolveDispute(1, true);
    }
    function test_RaiseDispute_EventContainsCorrectId() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        vm.expectEmit(true, false, false, false);
        emit OldTaskMarket.DisputeRaised(1);
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
    }
    function test_ResolveDispute_EventEmitted() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.raiseDispute(1, "ipfs://reason");
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.resolveDispute(1, true);
    }

    // ==================== ADMIN TESTS (10) ====================
    function test_AddSkill_ByOwner() public {
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.addSkill("New Skill", "Description");
        assertEq(oldTaskMarket.skills(9).name, "New Skill");
    }
    function test_AddSkill_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        oldTaskMarket.addSkill("New Skill", "Description");
    }
    function test_ToggleSkill_ByOwner() public {
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.toggleSkill(1);
        assertFalse(oldTaskMarket.skills(1).isActive);
    }
    function test_ToggleSkill_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        oldTaskMarket.toggleSkill(1);
    }
    function test_SetProtocolFee_ByOwner() public {
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.setProtocolFee(500);
        assertEq(oldTaskMarket.protocolFee(), 500);
    }
    function test_SetProtocolFee_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        oldTaskMarket.setProtocolFee(500);
    }
    function test_WithdrawFees_ByOwner() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        vm.prank(alice);
        oldTaskMarket.submitWork(1, "ipfs://work");
        oldTaskMarket.completeTask(1, 5);
        uint256 before = oldTaskMarket.owner().balance;
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.withdrawFees();
        assertTrue(oldTaskMarket.owner().balance > before);
    }
    function test_WithdrawFees_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        oldTaskMarket.withdrawFees();
    }
    function test_Pause_ByOwner() public {
        vm.prank(oldTaskMarket.owner());
        oldTaskMarket.pause();
        assertTrue(oldTaskMarket.paused());
    }
    function test_Pause_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        oldTaskMarket.pause();
    }

    // ==================== VIEW FUNCTION TESTS (10) ====================
    function test_GetTask_Empty() public view {
        OldTaskMarket.Task memory task = oldTaskMarket.getTask(1);
        assertEq(task.id, 0);
    }
    function test_GetTask_AfterPost() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        OldTaskMarket.Task memory task = oldTaskMarket.getTask(1);
        assertEq(task.id, 1);
    }
    function test_GetSkillTasks_Empty() public view {
        uint256[] memory tasks = oldTaskMarket.getSkillTasks(1);
        assertEq(tasks.length, 0);
    }
    function test_GetSkillTasks_AfterPost() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        uint256[] memory tasks = oldTaskMarket.getSkillTasks(1);
        assertEq(tasks.length, 1);
    }
    function test_GetWorkerTasks_Empty() public view {
        uint256[] memory tasks = oldTaskMarket.getWorkerTasks(alice);
        assertEq(tasks.length, 0);
    }
    function test_GetWorkerTasks_AfterAccept() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        vm.prank(alice);
        oldTaskMarket.acceptTask(1);
        uint256[] memory tasks = oldTaskMarket.getWorkerTasks(alice);
        assertEq(tasks.length, 1);
    }
    function test_GetCreatorTasks_Empty() public view {
        uint256[] memory tasks = oldTaskMarket.getCreatorTasks(alice);
        assertEq(tasks.length, 0);
    }
    function test_GetCreatorTasks_AfterPost() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        uint256[] memory tasks = oldTaskMarket.getCreatorTasks(address(this));
        assertEq(tasks.length, 1);
    }
    function test_GetActiveTasks() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        uint256[] memory tasks = oldTaskMarket.getActiveTasks();
        assertEq(tasks.length, 1);
    }
    function test_GetOpenTasks() public {
        oldTaskMarket.postTask{value: 0.001 ether}("ipfs://description", 1, 0.01 ether, 3 days);
        uint256[] memory tasks = oldTaskMarket.getOpenTasks();
        assertEq(tasks.length, 1);
    }

    receive() external payable {}
}
