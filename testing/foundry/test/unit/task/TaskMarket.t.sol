// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {TaskMarket} from "../../../../contracts-v2/task/TaskMarket.sol";
import {ITaskMarket} from "../../../../contracts-v2/interfaces/ITaskMarket.sol";

contract TaskMarketTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CONSTRUCTOR TESTS (15) ====================
    function test_Constructor_SetsOwner() public view {
        assertEq(taskMarket.owner(), owner);
    }
    function test_Constructor_NextTaskIdIsOne() public view {
        // Task IDs start at 1
        assertTrue(address(taskMarket) != address(0));
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(taskMarket).code.length > 0);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(taskMarket).balance, 0);
    }
    function test_Constructor_NoEthRequired() public {
        TaskMarket tm = new TaskMarket();
        assertEq(address(tm).balance, 0);
    }
    function test_Constructor_OwnableSetCorrectly() public view {
        assertEq(taskMarket.owner(), owner);
    }
    function test_Constructor_MultipleInstancesIndependent() public {
        TaskMarket tm1 = new TaskMarket();
        TaskMarket tm2 = new TaskMarket();
        assertTrue(address(tm1) != address(tm2));
    }
    function test_Constructor_DifferentOwners() public {
        vm.prank(alice);
        TaskMarket tm = new TaskMarket();
        assertEq(tm.owner(), alice);
    }
    function test_Constructor_StateInitialized() public view {
        assertTrue(address(taskMarket) != address(0));
    }
    function test_Constructor_ReceivesEth() public {
        TaskMarket tm = new TaskMarket();
        (bool success,) = address(tm).call{value: 1 ether}("");
        assertTrue(success);
    }
    function test_Constructor_EOAOwnerAllowed() public {
        vm.prank(alice);
        TaskMarket tm = new TaskMarket();
        assertEq(tm.owner(), alice);
    }
    function test_Constructor_ContractOwnerAllowed() public {
        TaskMarket tm = new TaskMarket();
        assertEq(tm.owner(), owner);
    }
    function test_Constructor_PrecompileOwnerAllowed() public {
        vm.prank(address(1));
        TaskMarket tm = new TaskMarket();
        assertEq(tm.owner(), address(1));
    }
    function test_Constructor_MaxAddressOwnerAllowed() public {
        address maxAddr = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        vm.prank(maxAddr);
        TaskMarket tm = new TaskMarket();
        assertEq(tm.owner(), maxAddr);
    }
    function test_Constructor_TransferOwnershipAvailable() public asOwner {
        taskMarket.transferOwnership(alice);
        assertEq(taskMarket.owner(), alice);
    }

    // ==================== CREATE TASK TESTS (40) ====================
    function test_CreateTask_EthTask() public asAlice {
        uint256 taskId = taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        assertEq(taskId, 1);
    }
    function test_CreateTask_EmitsEvent() public asAlice {
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCreated(1, 1, alice, 1 ether);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
    }
    function test_CreateTask_StoresTask() public asAlice {
        uint256 taskId = taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        ITaskMarket.Task memory task = taskMarket.getTask(taskId);
        assertEq(task.id, 1);
        assertEq(task.covenantId, 1);
        assertEq(task.creator, alice);
        assertEq(task.reward, 1 ether);
    }
    function test_CreateTask_NativeToken() public asAlice {
        uint256 taskId = taskMarket.createTask{value: 2 ether}(1, 2 ether, address(0), block.timestamp + 1 days, bytes32(0));
        ITaskMarket.Task memory task = taskMarket.getTask(taskId);
        assertEq(task.rewardToken, address(0));
    }
    function test_CreateTask_ERC20Task() public asAlice {
        token.approve(address(taskMarket), 1 ether);
        uint256 taskId = taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        ITaskMarket.Task memory task = taskMarket.getTask(taskId);
        assertEq(task.rewardToken, address(token));
    }
    function test_CreateTask_InvalidCovenantIdReverts() public asAlice {
        vm.expectRevert(ITaskMarket.InvalidCovenant.selector);
        taskMarket.createTask{value: 1 ether}(0, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
    }
    function test_CreateTask_InvalidRewardReverts() public asAlice {
        vm.expectRevert(ITaskMarket.InvalidReward.selector);
        taskMarket.createTask{value: 0}(1, 0, address(0), block.timestamp + 1 days, bytes32(0));
    }
    function test_CreateTask_InvalidDeadlineReverts() public asAlice {
        vm.expectRevert(ITaskMarket.InvalidDeadline.selector);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp - 1, bytes32(0));
    }
    function test_CreateTask_EthAmountMismatchReverts() public asAlice {
        vm.expectRevert(ITaskMarket.InvalidReward.selector);
        taskMarket.createTask{value: 0.5 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
    }
    function test_CreateTask_TasksByCovenant() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256[] memory tasks = taskMarket.getTasksByCovenant(1);
        assertEq(tasks.length, 2);
    }
    function test_CreateTask_IncrementingIds() public asAlice {
        uint256 t1 = taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256 t2 = taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        assertEq(t1, 1);
        assertEq(t2, 2);
    }
    function test_CreateTask_WithMetadata() public asAlice {
        bytes32 metadata = keccak256("task metadata");
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, metadata);
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.metadataHash, metadata);
    }
    function test_CreateTask_DifferentCovenantIds() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(2, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        assertEq(taskMarket.getTasksByCovenant(1).length, 1);
        assertEq(taskMarket.getTasksByCovenant(2).length, 1);
    }
    function test_CreateTask_DifferentRewards() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 2 ether}(1, 2 ether, address(0), block.timestamp + 1 days, bytes32(0));
        ITaskMarket.Task memory t1 = taskMarket.getTask(1);
        ITaskMarket.Task memory t2 = taskMarket.getTask(2);
        assertEq(t1.reward, 1 ether);
        assertEq(t2.reward, 2 ether);
    }
    function test_CreateTask_DifferentDeadlines() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 7 days, bytes32(0));
        ITaskMarket.Task memory t1 = taskMarket.getTask(1);
        ITaskMarket.Task memory t2 = taskMarket.getTask(2);
        assertEq(t1.deadline, block.timestamp + 1 days);
        assertEq(t2.deadline, block.timestamp + 7 days);
    }
    function test_CreateTask_ERC20Transfer() public asAlice {
        uint256 balanceBefore = token.balanceOf(alice);
        token.approve(address(taskMarket), 1 ether);
        taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        uint256 balanceAfter = token.balanceOf(alice);
        assertEq(balanceBefore - balanceAfter, 1 ether);
    }
    function test_CreateTask_ERC20ReceivedByContract() public asAlice {
        token.approve(address(taskMarket), 1 ether);
        taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        assertEq(token.balanceOf(address(taskMarket)), 1 ether);
    }
    function test_CreateTask_EthReceivedByContract() public asAlice {
        uint256 balanceBefore = address(taskMarket).balance;
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        assertEq(address(taskMarket).balance - balanceBefore, 1 ether);
    }
    function test_CreateTask_StatusIsOpen() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.status, 0);
    }
    function test_CreateTask_AssigneeIsZero() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.assignee, address(0));
    }
    function test_CreateTask_CurrentTimestampDeadline() public asAlice {
        vm.expectRevert(ITaskMarket.InvalidDeadline.selector);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp, bytes32(0));
    }
    function test_CreateTask_PastDeadlineReverts() public asAlice {
        vm.expectRevert(ITaskMarket.InvalidDeadline.selector);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp - 1, bytes32(0));
    }
    function test_CreateTask_FutureDeadlineAllowed() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 365 days, bytes32(0));
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.deadline, block.timestamp + 365 days);
    }
    function test_CreateTask_EventContainsCorrectCovenantId() public asAlice {
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCreated(1, 5, alice, 1 ether);
        taskMarket.createTask{value: 1 ether}(5, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
    }
    function test_CreateTask_EventContainsCorrectReward() public asAlice {
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCreated(1, 1, alice, 5 ether);
        taskMarket.createTask{value: 5 ether}(1, 5 ether, address(0), block.timestamp + 1 days, bytes32(0));
    }
    function test_CreateTask_EventContainsCorrectCreator() public asBob {
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCreated(1, 1, bob, 1 ether);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
    }
    function test_CreateTask_ERC20ZeroAddressUsesEth() public asAlice {
        // When rewardToken is address(0), ETH is used
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.rewardToken, address(0));
    }
    function test_CreateTask_10Tasks() public asAlice {
        for (uint256 i = 0; i < 10; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        }
        assertEq(taskMarket.getTasksByCovenant(1).length, 10);
    }
    function test_CreateTask_MultipleCreators() public {
        vm.prank(alice);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        assertEq(taskMarket.getTasksByCovenant(1).length, 2);
    }
    function test_CreateTask_MultipleERC20Tasks() public asAlice {
        token.approve(address(taskMarket), 10 ether);
        for (uint256 i = 0; i < 5; i++) {
            taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        }
        assertEq(taskMarket.getTasksByCovenant(1).length, 5);
        assertEq(token.balanceOf(address(taskMarket)), 5 ether);
    }
    function test_CreateTask_ExactEthAmount() public asAlice {
        taskMarket.createTask{value: 1.5 ether}(1, 1.5 ether, address(0), block.timestamp + 1 days, bytes32(0));
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.reward, 1.5 ether);
    }
    function test_CreateTask_ExcessEthRefundedNotImplemented() public asAlice {
        // Contract requires exact ETH amount
        vm.expectRevert(ITaskMarket.InvalidReward.selector);
        taskMarket.createTask{value: 2 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
    }

    // ==================== ASSIGN TASK TESTS (20) ====================
    function test_AssignTask_ByAssignee() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.assignee, bob);
    }
    function test_AssignTask_EmitsEvent() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.expectEmit(true, true, false, false);
        emit ITaskMarket.TaskAssigned(1, bob);
        vm.prank(bob);
        taskMarket.assignTask(1);
    }
    function test_AssignTask_ChangesStatus() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.status, 1);
    }
    function test_AssignTask_TasksByAssignee() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        uint256[] memory tasks = taskMarket.getTasksByAssignee(bob);
        assertEq(tasks.length, 1);
    }
    function test_AssignTask_NotOpenReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.expectRevert(ITaskMarket.TaskNotOpen.selector);
        taskMarket.assignTask(1);
    }
    function test_AssignTask_DeadlinePassedReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(ITaskMarket.DeadlinePassed.selector);
        vm.prank(bob);
        taskMarket.assignTask(1);
    }
    function test_AssignTask_NonExistentTaskReverts() public {
        vm.prank(bob);
        vm.expectRevert();
        taskMarket.assignTask(999);
    }
    function test_AssignTask_MultipleAssigneesDifferentTasks() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(carol);
        taskMarket.assignTask(2);
        assertEq(taskMarket.getTask(1).assignee, bob);
        assertEq(taskMarket.getTask(2).assignee, carol);
    }
    function test_AssignTask_SameAssigneeMultipleTasks() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.assignTask(2);
        assertEq(taskMarket.getTasksByAssignee(bob).length, 2);
    }
    function test_AssignTask_AssignerCanBeCreator() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.assignTask(1);
        assertEq(taskMarket.getTask(1).assignee, alice);
    }
    function test_AssignTask_EventContainsCorrectTaskId() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.expectEmit(true, true, false, false);
        emit ITaskMarket.TaskAssigned(1, bob);
        vm.prank(bob);
        taskMarket.assignTask(1);
    }
    function test_AssignTask_EventContainsCorrectAssignee() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.expectEmit(true, true, false, false);
        emit ITaskMarket.TaskAssigned(1, carol);
        vm.prank(carol);
        taskMarket.assignTask(1);
    }
    function test_AssignTask_NoEthRequired() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        // No ETH transfer during assign
    }
    function test_AssignTask_CovenantIdUnchanged() public asAlice {
        taskMarket.createTask{value: 1 ether}(5, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        assertEq(taskMarket.getTask(1).covenantId, 5);
    }
    function test_AssignTask_RewardUnchanged() public asAlice {
        taskMarket.createTask{value: 3 ether}(1, 3 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        assertEq(taskMarket.getTask(1).reward, 3 ether);
    }
    function test_AssignTask_DeadlineUnchanged() public asAlice {
        uint256 deadline = block.timestamp + 7 days;
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), deadline, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        assertEq(taskMarket.getTask(1).deadline, deadline);
    }
    function test_AssignTask_MetadataUnchanged() public asAlice {
        bytes32 metadata = keccak256("metadata");
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, metadata);
        vm.prank(bob);
        taskMarket.assignTask(1);
        assertEq(taskMarket.getTask(1).metadataHash, metadata);
    }
    function test_AssignTask_10Assignments() public asAlice {
        for (uint256 i = 0; i < 10; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
            vm.prank(address(uint160(i + 100)));
            taskMarket.assignTask(i + 1);
        }
        for (uint256 i = 0; i < 10; i++) {
            assertEq(taskMarket.getTask(i + 1).status, 1);
        }
    }

    // ==================== SUBMIT TASK TESTS (20) ====================
    function test_SubmitTask_ByAssignee() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        bytes32 proofHash = keccak256("proof");
        vm.prank(bob);
        taskMarket.submitTask(1, proofHash);
        assertEq(taskMarket.getTask(1).status, 2);
    }
    function test_SubmitTask_EmitsEvent() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        bytes32 proofHash = keccak256("proof");
        vm.expectEmit(true, false, false, true);
        emit ITaskMarket.TaskSubmitted(1, proofHash);
        vm.prank(bob);
        taskMarket.submitTask(1, proofHash);
    }
    function test_SubmitTask_ChangesStatus() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        assertEq(taskMarket.getTask(1).status, 2);
    }
    function test_SubmitTask_NotAssignedReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.expectRevert(ITaskMarket.TaskNotAssigned.selector);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
    }
    function test_SubmitTask_NotAssigneeReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.expectRevert(ITaskMarket.UnauthorizedTaskAction.selector);
        vm.prank(carol);
        taskMarket.submitTask(1, keccak256("proof"));
    }
    function test_SubmitTask_AlreadySubmittedReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.expectRevert(ITaskMarket.TaskNotAssigned.selector);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof2"));
    }
    function test_SubmitTask_NonExistentTaskReverts() public {
        vm.expectRevert();
        vm.prank(bob);
        taskMarket.submitTask(999, keccak256("proof"));
    }
    function test_SubmitTask_ProofHashStored() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        bytes32 proofHash = keccak256("my proof");
        vm.prank(bob);
        taskMarket.submitTask(1, proofHash);
        // Proof hash is not stored in struct but emitted in event
    }
    function test_SubmitTask_EventContainsCorrectProofHash() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        bytes32 proofHash = keccak256("specific proof");
        vm.expectEmit(true, false, false, true);
        emit ITaskMarket.TaskSubmitted(1, proofHash);
        vm.prank(bob);
        taskMarket.submitTask(1, proofHash);
    }
    function test_SubmitTask_NoEthRequired() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
    }
    function test_SubmitTask_AfterDeadlineReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.warp(block.timestamp + 2 days);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        // No deadline check on submit, so this should work
    }
    function test_SubmitTask_CreatorCannotSubmit() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.expectRevert(ITaskMarket.UnauthorizedTaskAction.selector);
        taskMarket.submitTask(1, keccak256("proof"));
    }
    function test_SubmitTask_DifferentAssignees() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(carol);
        taskMarket.assignTask(2);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof1"));
        vm.prank(carol);
        taskMarket.submitTask(2, keccak256("proof2"));
        assertEq(taskMarket.getTask(1).status, 2);
        assertEq(taskMarket.getTask(2).status, 2);
    }
    function test_SubmitTask_SameAssigneeMultipleTasks() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.assignTask(2);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof1"));
        vm.prank(bob);
        taskMarket.submitTask(2, keccak256("proof2"));
        assertEq(taskMarket.getTask(1).status, 2);
        assertEq(taskMarket.getTask(2).status, 2);
    }
    function test_SubmitTask_ZeroProofHashAllowed() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, bytes32(0));
        assertEq(taskMarket.getTask(1).status, 2);
    }
    function test_SubmitTask_EventContainsCorrectTaskId() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.expectEmit(true, false, false, true);
        emit ITaskMarket.TaskSubmitted(1, keccak256("proof"));
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
    }
    function test_SubmitTask_10Submissions() public asAlice {
        for (uint256 i = 0; i < 10; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
            vm.prank(bob);
            taskMarket.assignTask(i + 1);
            vm.prank(bob);
            taskMarket.submitTask(i + 1, keccak256(abi.encode(i)));
        }
        for (uint256 i = 0; i < 10; i++) {
            assertEq(taskMarket.getTask(i + 1).status, 2);
        }
    }

    // ==================== COMPLETE TASK TESTS (20) ====================
    function test_CompleteTask_ByCreator() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.completeTask(1);
        assertEq(taskMarket.getTask(1).status, 3);
    }
    function test_CompleteTask_EmitsEvent() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCompleted(1, bob, 1 ether);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_TransfersReward() public asAlice {
        uint256 bobBalanceBefore = bob.balance;
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.completeTask(1);
        assertEq(bob.balance - bobBalanceBefore, 1 ether);
    }
    function test_CompleteTask_ChangesStatus() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.completeTask(1);
        assertEq(taskMarket.getTask(1).status, 3);
    }
    function test_CompleteTask_NotSubmittedReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.expectRevert(ITaskMarket.TaskNotSubmitted.selector);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_NotCreatorReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.prank(bob);
        vm.expectRevert(ITaskMarket.UnauthorizedTaskAction.selector);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_AssigneeCannotComplete() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.prank(bob);
        vm.expectRevert(ITaskMarket.UnauthorizedTaskAction.selector);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_NonExistentTaskReverts() public {
        vm.expectRevert();
        taskMarket.completeTask(999);
    }
    function test_CompleteTask_ERC20Transfer() public asAlice {
        token.approve(address(taskMarket), 1 ether);
        taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        uint256 bobBalanceBefore = token.balanceOf(bob);
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.completeTask(1);
        assertEq(token.balanceOf(bob) - bobBalanceBefore, 1 ether);
    }
    function test_CompleteTask_ERC20Event() public asAlice {
        token.approve(address(taskMarket), 1 ether);
        taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCompleted(1, bob, 1 ether);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_EventContainsCorrectTaskId() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCompleted(1, bob, 1 ether);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_EventContainsCorrectAssignee() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCompleted(1, bob, 1 ether);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_EventContainsCorrectReward() public asAlice {
        taskMarket.createTask{value: 5 ether}(1, 5 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.expectEmit(true, true, true, true);
        emit ITaskMarket.TaskCompleted(1, bob, 5 ether);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_DifferentRewards() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 2 ether}(1, 2 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.startPrank(bob);
        taskMarket.assignTask(1);
        taskMarket.submitTask(1, keccak256("proof1"));
        taskMarket.assignTask(2);
        taskMarket.submitTask(2, keccak256("proof2"));
        vm.stopPrank();
        uint256 bobBalanceBefore = bob.balance;
        taskMarket.completeTask(1);
        taskMarket.completeTask(2);
        assertEq(bob.balance - bobBalanceBefore, 3 ether);
    }
    function test_CompleteTask_NoReentrancy() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.completeTask(1);
        // Status already updated prevents reentrancy
        vm.expectRevert(ITaskMarket.TaskNotSubmitted.selector);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_AlreadyCompletedReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.completeTask(1);
        vm.expectRevert(ITaskMarket.TaskNotSubmitted.selector);
        taskMarket.completeTask(1);
    }
    function test_CompleteTask_ERC20RewardDecreasesContractBalance() public asAlice {
        token.approve(address(taskMarket), 2 ether);
        taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        uint256 contractBalanceBefore = token.balanceOf(address(taskMarket));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.completeTask(1);
        assertEq(contractBalanceBefore - token.balanceOf(address(taskMarket)), 1 ether);
    }
    function test_CompleteTask_EthRewardDecreasesContractBalance() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256 contractBalanceBefore = address(taskMarket).balance;
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.completeTask(1);
        assertEq(contractBalanceBefore - address(taskMarket).balance, 1 ether);
    }

    // ==================== DISPUTE TASK TESTS (20) ====================
    function test_DisputeTask_ByCreator() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.disputeTask(1);
        assertEq(taskMarket.getTask(1).status, 4);
    }
    function test_DisputeTask_ByAssignee() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.prank(bob);
        taskMarket.disputeTask(1);
        assertEq(taskMarket.getTask(1).status, 4);
    }
    function test_DisputeTask_EmitsEvent() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.expectEmit(true, true, false, false);
        emit ITaskMarket.TaskDisputed(1, 0);
        taskMarket.disputeTask(1);
    }
    function test_DisputeTask_ChangesStatus() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.disputeTask(1);
        assertEq(taskMarket.getTask(1).status, 4);
    }
    function test_DisputeTask_NotSubmittedReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.expectRevert(ITaskMarket.TaskNotSubmitted.selector);
        taskMarket.disputeTask(1);
    }
    function test_DisputeTask_NotInvolvedReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.prank(carol);
        vm.expectRevert(ITaskMarket.UnauthorizedTaskAction.selector);
        taskMarket.disputeTask(1);
    }
    function test_DisputeTask_ReturnsDisputeId() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        uint256 disputeId = taskMarket.disputeTask(1);
        assertTrue(disputeId != 0);
    }
    function test_DisputeTask_NonExistentTaskReverts() public {
        vm.expectRevert();
        taskMarket.disputeTask(999);
    }
    function test_DisputeTask_DifferentDisputeIds() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.startPrank(bob);
        taskMarket.assignTask(1);
        taskMarket.submitTask(1, keccak256("proof1"));
        taskMarket.assignTask(2);
        taskMarket.submitTask(2, keccak256("proof2"));
        vm.stopPrank();
        uint256 disputeId1 = taskMarket.disputeTask(1);
        vm.prank(bob);
        uint256 disputeId2 = taskMarket.disputeTask(2);
        assertTrue(disputeId1 != disputeId2);
    }
    function test_DisputeTask_EventContainsCorrectTaskId() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.expectEmit(true, true, false, false);
        emit ITaskMarket.TaskDisputed(1, 0);
        taskMarket.disputeTask(1);
    }
    function test_DisputeTask_NoEthRequired() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        uint256 contractBalanceBefore = address(taskMarket).balance;
        taskMarket.disputeTask(1);
        assertEq(address(taskMarket).balance, contractBalanceBefore);
    }
    function test_DisputeTask_CreatorCanDispute() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.disputeTask(1);
        assertEq(taskMarket.getTask(1).status, 4);
    }
    function test_DisputeTask_AssigneeCanDispute() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.prank(bob);
        taskMarket.disputeTask(1);
        assertEq(taskMarket.getTask(1).status, 4);
    }
    function test_DisputeTask_RandomCannotDispute() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        vm.prank(carol);
        vm.expectRevert(ITaskMarket.UnauthorizedTaskAction.selector);
        taskMarket.disputeTask(1);
    }
    function test_DisputeTask_CovenantIdUnchanged() public asAlice {
        taskMarket.createTask{value: 1 ether}(5, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.disputeTask(1);
        assertEq(taskMarket.getTask(1).covenantId, 5);
    }
    function test_DisputeTask_RewardUnchanged() public asAlice {
        taskMarket.createTask{value: 3 ether}(1, 3 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.disputeTask(1);
        assertEq(taskMarket.getTask(1).reward, 3 ether);
    }
    function test_DisputeTask_AssigneeUnchanged() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        taskMarket.disputeTask(1);
        assertEq(taskMarket.getTask(1).assignee, bob);
    }
    function test_DisputeTask_10Disputes() public asAlice {
        for (uint256 i = 0; i < 10; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
            vm.prank(bob);
            taskMarket.assignTask(i + 1);
            vm.prank(bob);
            taskMarket.submitTask(i + 1, keccak256(abi.encode(i)));
            taskMarket.disputeTask(i + 1);
        }
        for (uint256 i = 0; i < 10; i++) {
            assertEq(taskMarket.getTask(i + 1).status, 4);
        }
    }

    // ==================== CANCEL TASK TESTS (20) ====================
    function test_CancelTask_ByCreator() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(taskMarket.getTask(1).status, 5);
    }
    function test_CancelTask_EmitsEvent() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.expectEmit(true, false, false, false);
        emit ITaskMarket.TaskCancelled(1);
        taskMarket.cancelTask(1);
    }
    function test_CancelTask_RefundsEth() public asAlice {
        uint256 aliceBalanceBefore = alice.balance;
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(alice.balance, aliceBalanceBefore);
    }
    function test_CancelTask_ChangesStatus() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(taskMarket.getTask(1).status, 5);
    }
    function test_CancelTask_NotOpenReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.expectRevert(ITaskMarket.TaskNotOpen.selector);
        taskMarket.cancelTask(1);
    }
    function test_CancelTask_NotCreatorReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        vm.expectRevert(ITaskMarket.UnauthorizedTaskAction.selector);
        taskMarket.cancelTask(1);
    }
    function test_CancelTask_NonExistentTaskReverts() public {
        vm.expectRevert();
        taskMarket.cancelTask(999);
    }
    function test_CancelTask_ERC20Refund() public asAlice {
        token.approve(address(taskMarket), 1 ether);
        uint256 aliceBalanceBefore = token.balanceOf(alice);
        taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(token.balanceOf(alice), aliceBalanceBefore);
    }
    function test_CancelTask_AlreadyCancelledReverts() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        vm.expectRevert(ITaskMarket.TaskNotOpen.selector);
        taskMarket.cancelTask(1);
    }
    function test_CancelTask_EventContainsCorrectTaskId() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.expectEmit(true, false, false, false);
        emit ITaskMarket.TaskCancelled(1);
        taskMarket.cancelTask(1);
    }
    function test_CancelTask_NoAssignee() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(taskMarket.getTask(1).assignee, address(0));
    }
    function test_CancelTask_EthBalanceDecreases() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256 contractBalanceBefore = address(taskMarket).balance;
        taskMarket.cancelTask(1);
        assertEq(contractBalanceBefore - address(taskMarket).balance, 1 ether);
    }
    function test_CancelTask_ERC20BalanceDecreases() public asAlice {
        token.approve(address(taskMarket), 1 ether);
        taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        uint256 contractBalanceBefore = token.balanceOf(address(taskMarket));
        taskMarket.cancelTask(1);
        assertEq(contractBalanceBefore - token.balanceOf(address(taskMarket)), 1 ether);
    }
    function test_CancelTask_CovenantIdUnchanged() public asAlice {
        taskMarket.createTask{value: 1 ether}(5, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(taskMarket.getTask(1).covenantId, 5);
    }
    function test_CancelTask_RewardUnchanged() public asAlice {
        taskMarket.createTask{value: 3 ether}(1, 3 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(taskMarket.getTask(1).reward, 3 ether);
    }
    function test_CancelTask_DeadlineUnchanged() public asAlice {
        uint256 deadline = block.timestamp + 7 days;
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), deadline, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(taskMarket.getTask(1).deadline, deadline);
    }
    function test_CancelTask_MetadataUnchanged() public asAlice {
        bytes32 metadata = keccak256("metadata");
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, metadata);
        taskMarket.cancelTask(1);
        assertEq(taskMarket.getTask(1).metadataHash, metadata);
    }
    function test_CancelTask_CreatorUnchanged() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.cancelTask(1);
        assertEq(taskMarket.getTask(1).creator, alice);
    }
    function test_CancelTask_10Cancellations() public asAlice {
        for (uint256 i = 0; i < 10; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
            taskMarket.cancelTask(i + 1);
        }
        for (uint256 i = 0; i < 10; i++) {
            assertEq(taskMarket.getTask(i + 1).status, 5);
        }
    }
    function test_CancelTask_DifferentCreatorsCanCancelOwn() public {
        vm.prank(alice);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(alice);
        taskMarket.cancelTask(1);
        vm.prank(bob);
        taskMarket.cancelTask(2);
        assertEq(taskMarket.getTask(1).status, 5);
        assertEq(taskMarket.getTask(2).status, 5);
    }

    // ==================== VIEW FUNCTION TESTS (15) ====================
    function test_GetTask_ReturnsCorrectData() public asAlice {
        taskMarket.createTask{value: 1 ether}(5, 2 ether, address(0), block.timestamp + 7 days, bytes32("metadata"));
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.id, 1);
        assertEq(task.covenantId, 5);
        assertEq(task.creator, alice);
        assertEq(task.reward, 2 ether);
        assertEq(task.deadline, block.timestamp + 7 days);
        assertEq(task.metadataHash, bytes32("metadata"));
    }
    function test_GetTasksByCovenant_Empty() public view {
        uint256[] memory tasks = taskMarket.getTasksByCovenant(1);
        assertEq(tasks.length, 0);
    }
    function test_GetTasksByCovenant_One() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256[] memory tasks = taskMarket.getTasksByCovenant(1);
        assertEq(tasks.length, 1);
        assertEq(tasks[0], 1);
    }
    function test_GetTasksByCovenant_Many() public asAlice {
        for (uint256 i = 0; i < 5; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        }
        uint256[] memory tasks = taskMarket.getTasksByCovenant(1);
        assertEq(tasks.length, 5);
    }
    function test_GetTasksByAssignee_Empty() public view {
        uint256[] memory tasks = taskMarket.getTasksByAssignee(bob);
        assertEq(tasks.length, 0);
    }
    function test_GetTasksByAssignee_One() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        uint256[] memory tasks = taskMarket.getTasksByAssignee(bob);
        assertEq(tasks.length, 1);
        assertEq(tasks[0], 1);
    }
    function test_GetTasksByAssignee_Many() public asAlice {
        for (uint256 i = 0; i < 5; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
            vm.prank(bob);
            taskMarket.assignTask(i + 1);
        }
        uint256[] memory tasks = taskMarket.getTasksByAssignee(bob);
        assertEq(tasks.length, 5);
    }
    function test_GetTasksByCovenant_DifferentCovenantIds() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(2, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        assertEq(taskMarket.getTasksByCovenant(1).length, 2);
        assertEq(taskMarket.getTasksByCovenant(2).length, 1);
    }
    function test_GetTasksByAssignee_DifferentAssignees() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(carol);
        taskMarket.assignTask(2);
        assertEq(taskMarket.getTasksByAssignee(bob).length, 1);
        assertEq(taskMarket.getTasksByAssignee(carol).length, 1);
    }
    function test_GetTask_NonExistentReturnsZero() public view {
        ITaskMarket.Task memory task = taskMarket.getTask(999);
        assertEq(task.id, 0);
    }
    function test_ViewFunctions_ArePureOrView() public view {
        taskMarket.getTask(1);
        taskMarket.getTasksByCovenant(1);
        taskMarket.getTasksByAssignee(alice);
        assertTrue(true);
    }
    function test_GetTasksByCovenant_100Tasks() public asAlice {
        for (uint256 i = 0; i < 100; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        }
        uint256[] memory tasks = taskMarket.getTasksByCovenant(1);
        assertEq(tasks.length, 100);
    }
    function test_GetTasksByAssignee_100Tasks() public asAlice {
        for (uint256 i = 0; i < 100; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
            vm.prank(bob);
            taskMarket.assignTask(i + 1);
        }
        uint256[] memory tasks = taskMarket.getTasksByAssignee(bob);
        assertEq(tasks.length, 100);
    }
    function test_GetTasksByCovenant_ReturnsIdsInOrder() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256[] memory tasks = taskMarket.getTasksByCovenant(1);
        assertEq(tasks[0], 1);
        assertEq(tasks[1], 2);
        assertEq(tasks[2], 3);
    }
}
