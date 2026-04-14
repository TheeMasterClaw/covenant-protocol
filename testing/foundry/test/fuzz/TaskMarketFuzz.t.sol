// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../fixtures/DeploymentFixtures.sol";
import {ITaskMarket} from "../../../../contracts-v2/interfaces/ITaskMarket.sol";
import {ICovenantGovernor} from "../../../../contracts-v2/interfaces/ICovenantGovernor.sol";
import {CovenantImplementation} from "../../../../contracts-v2/core/CovenantImplementation.sol";

contract TaskMarketFuzzTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CREATE TASK FUZZ TESTS (15) ====================
    function testFuzz_CreateTask(uint256 covenantId, uint256 reward, uint256 deadlineOffset, bytes32 metadata) public asAlice {
        vm.assume(covenantId > 0);
        vm.assume(reward > 0 && reward <= 1000 ether);
        vm.assume(deadlineOffset > 1 && deadlineOffset < 365 days);
        
        uint256 deadline = block.timestamp + deadlineOffset;
        vm.deal(alice, reward);
        taskMarket.createTask{value: reward}(covenantId, reward, address(0), deadline, metadata);
        
        ITaskMarket.Task memory task = taskMarket.getTask(1);
        assertEq(task.covenantId, covenantId);
        assertEq(task.reward, reward);
        assertEq(task.deadline, deadline);
        assertEq(task.metadataHash, metadata);
    }
    function testFuzz_CreateTask_DifferentCreators(uint256 seed) public {
        address creator = address(uint160(uint256(keccak256(abi.encode(seed)))));
        vm.assume(creator != address(0));
        vm.deal(creator, 2 ether);
        
        vm.prank(creator);
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(seed));
        
        assertEq(taskMarket.getTask(1).creator, creator);
    }
    function testFuzz_CreateTask_SequentialIds(uint256 count) public asAlice {
        vm.assume(count > 0 && count <= 100);
        vm.deal(alice, count * 1 ether);
        
        for (uint256 i = 0; i < count; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(i));
        }
        
        assertEq(taskMarket.getTasksByCovenant(1).length, count);
    }
    function testFuzz_CreateTask_VariedRewards(uint256[] calldata rewards) public asAlice {
        vm.assume(rewards.length > 0 && rewards.length <= 50);
        uint256 total = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            vm.assume(rewards[i] > 0 && rewards[i] <= 10 ether);
            total += rewards[i];
        }
        vm.deal(alice, total);
        
        for (uint256 i = 0; i < rewards.length; i++) {
            taskMarket.createTask{value: rewards[i]}(1, rewards[i], address(0), block.timestamp + 1 days, bytes32(i));
        }
        
        assertEq(taskMarket.getTasksByCovenant(1).length, rewards.length);
    }
    function testFuzz_CreateTask_ERC20(uint256 reward) public asAlice {
        vm.assume(reward > 0 && reward <= 100000 ether);
        token.approve(address(taskMarket), reward);
        token.mint(alice, reward);
        
        taskMarket.createTask(1, reward, address(token), block.timestamp + 1 days, bytes32(0));
        
        assertEq(taskMarket.getTask(1).reward, reward);
        assertEq(taskMarket.getTask(1).rewardToken, address(token));
    }
    function testFuzz_CreateTask_MultipleCovenants(uint256 covenantCount) public asAlice {
        vm.assume(covenantCount > 0 && covenantCount <= 50);
        vm.deal(alice, covenantCount * 1 ether);
        
        for (uint256 i = 0; i < covenantCount; i++) {
            taskMarket.createTask{value: 1 ether}(i + 1, 1 ether, address(0), block.timestamp + 1 days, bytes32(i));
        }
        
        for (uint256 i = 0; i < covenantCount; i++) {
            assertEq(taskMarket.getTasksByCovenant(i + 1).length, 1);
        }
    }

    // ==================== ASSIGN TASK FUZZ TESTS (10) ====================
    function testFuzz_AssignTask(uint256 seed) public asAlice {
        address assignee = address(uint160(uint256(keccak256(abi.encode(seed, "assignee")))));
        vm.assume(assignee != address(0) && assignee != alice);
        
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        
        vm.prank(assignee);
        taskMarket.assignTask(1);
        
        assertEq(taskMarket.getTask(1).assignee, assignee);
        assertEq(taskMarket.getTask(1).status, 1);
    }
    function testFuzz_AssignTask_Multiple(uint256 count) public asAlice {
        vm.assume(count > 0 && count <= 50);
        vm.deal(alice, count * 1 ether);
        
        for (uint256 i = 0; i < count; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(i));
            address assignee = address(uint160(i + 1000));
            vm.prank(assignee);
            taskMarket.assignTask(i + 1);
        }
        
        assertEq(taskMarket.getTasksByAssignee(address(1000)).length, 1);
    }

    // ==================== COMPLETE TASK FUZZ TESTS (10) ====================
    function testFuzz_CompleteTask(uint256 reward) public asAlice {
        vm.assume(reward > 0 && reward <= 100 ether);
        vm.deal(alice, reward);
        
        taskMarket.createTask{value: reward}(1, reward, address(0), block.timestamp + 1 days, bytes32(0));
        
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        
        uint256 before = bob.balance;
        taskMarket.completeTask(1);
        
        assertEq(bob.balance - before, reward);
    }
    function testFuzz_CompleteTask_ERC20(uint256 reward) public asAlice {
        vm.assume(reward > 0 && reward <= 100000 ether);
        token.mint(alice, reward);
        token.approve(address(taskMarket), reward);
        
        taskMarket.createTask(1, reward, address(token), block.timestamp + 1 days, bytes32(0));
        
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        
        uint256 before = token.balanceOf(bob);
        taskMarket.completeTask(1);
        
        assertEq(token.balanceOf(bob) - before, reward);
    }

    // ==================== CANCEL TASK FUZZ TESTS (10) ====================
    function testFuzz_CancelTask(uint256 reward) public asAlice {
        vm.assume(reward > 0 && reward <= 100 ether);
        vm.deal(alice, reward);
        
        taskMarket.createTask{value: reward}(1, reward, address(0), block.timestamp + 1 days, bytes32(0));
        
        uint256 before = alice.balance;
        taskMarket.cancelTask(1);
        
        assertEq(alice.balance - before, reward);
    }
    function testFuzz_CancelTask_ERC20(uint256 reward) public asAlice {
        vm.assume(reward > 0 && reward <= 100000 ether);
        token.mint(alice, reward);
        token.approve(address(taskMarket), reward);
        
        taskMarket.createTask(1, reward, address(token), block.timestamp + 1 days, bytes32(0));
        
        uint256 before = token.balanceOf(alice);
        taskMarket.cancelTask(1);
        
        assertEq(token.balanceOf(alice) - before, reward);
    }

    // ==================== DISPUTE TASK FUZZ TESTS (10) ====================
    function testFuzz_DisputeTask(uint256 seed) public asAlice {
        address assignee = address(uint160(uint256(keccak256(abi.encode(seed)))));
        vm.assume(assignee != address(0) && assignee != alice);
        
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        
        vm.prank(assignee);
        taskMarket.assignTask(1);
        vm.prank(assignee);
        taskMarket.submitTask(1, keccak256("proof"));
        
        // Either creator or assignee can dispute
        bool creatorDisputes = seed % 2 == 0;
        if (creatorDisputes) {
            taskMarket.disputeTask(1);
        } else {
            vm.prank(assignee);
            taskMarket.disputeTask(1);
        }
        
        assertEq(taskMarket.getTask(1).status, 4);
    }

    // ==================== STAKING FUZZ TESTS (15) ====================
    function testFuzz_Stake(uint256 amount, uint256 lockDuration) public asAlice {
        vm.assume(amount > 0 && amount <= 1000000 ether);
        vm.assume(lockDuration <= 365 days);
        
        token.mint(alice, amount);
        token.approve(address(reputationStake), amount);
        
        reputationStake.stake(amount, lockDuration);
        
        assertEq(reputationStake.getStakeInfo(alice).amount, amount);
        if (lockDuration > 0) {
            assertTrue(reputationStake.getStakeInfo(alice).locked);
        }
    }
    function testFuzz_Stake_Multiple(uint256[] calldata amounts) public asAlice {
        vm.assume(amounts.length > 0 && amounts.length <= 50);
        uint256 total = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            vm.assume(amounts[i] > 0 && amounts[i] <= 1000 ether);
            total += amounts[i];
        }
        
        token.mint(alice, total);
        token.approve(address(reputationStake), total);
        
        for (uint256 i = 0; i < amounts.length; i++) {
            reputationStake.stake(amounts[i], 0);
        }
        
        assertEq(reputationStake.getStakeInfo(alice).amount, total);
    }
    function testFuzz_Unstake(uint256 amount) public asAlice {
        vm.assume(amount > 0 && amount <= 100000 ether);
        
        token.mint(alice, amount);
        token.approve(address(reputationStake), amount);
        reputationStake.stake(amount, 0);
        
        uint256 before = token.balanceOf(alice);
        reputationStake.unstake(amount);
        
        assertEq(token.balanceOf(alice) - before, amount);
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function testFuzz_PartialUnstake(uint256 stakeAmount, uint256 unstakeAmount) public asAlice {
        vm.assume(stakeAmount > 0 && stakeAmount <= 100000 ether);
        vm.assume(unstakeAmount > 0 && unstakeAmount <= stakeAmount);
        
        token.mint(alice, stakeAmount);
        token.approve(address(reputationStake), stakeAmount);
        reputationStake.stake(stakeAmount, 0);
        
        reputationStake.unstake(unstakeAmount);
        
        assertEq(reputationStake.getStakeInfo(alice).amount, stakeAmount - unstakeAmount);
    }
    function testFuzz_StakeDifferentUsers(uint256 userCount) public {
        vm.assume(userCount > 0 && userCount <= 50);
        
        for (uint256 i = 0; i < userCount; i++) {
            address user = address(uint160(i + 1000));
            token.mint(user, 1 ether);
            vm.startPrank(user);
            token.approve(address(reputationStake), 1 ether);
            reputationStake.stake(1 ether, 0);
            vm.stopPrank();
        }
        
        assertEq(reputationStake.totalStaked(), userCount * 1 ether);
    }

    // ==================== TOKEN FUZZ TESTS (10) ====================
    function testFuzz_Transfer(uint256 amount) public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0 && amount <= covenToken.balanceOf(owner)) {
            uint256 before = covenToken.balanceOf(alice);
            covenToken.transfer(alice, amount);
            assertEq(covenToken.balanceOf(alice) - before, amount);
        }
    }
    function testFuzz_Approve(uint256 amount) public asOwner {
        covenToken.approve(alice, amount);
        assertEq(covenToken.allowance(owner, alice), amount);
    }
    function testFuzz_TransferFrom(uint256 amount) public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0 && amount <= covenToken.balanceOf(owner)) {
            covenToken.approve(alice, amount);
            vm.prank(alice);
            covenToken.transferFrom(owner, bob, amount);
            assertEq(covenToken.balanceOf(bob), amount);
        }
    }
    function testFuzz_Burn(uint256 amount) public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0 && amount <= covenToken.balanceOf(owner)) {
            uint256 before = covenToken.totalSupply();
            covenToken.burn(amount);
            assertEq(before - covenToken.totalSupply(), amount);
        }
    }
    function testFuzz_BurnFrom(uint256 amount) public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0 && amount <= covenToken.balanceOf(owner)) {
            covenToken.approve(alice, amount);
            uint256 before = covenToken.totalSupply();
            vm.prank(alice);
            covenToken.burnFrom(owner, amount);
            assertEq(before - covenToken.totalSupply(), amount);
        }
    }

    // ==================== COVENANT FUZZ TESTS (10) ====================
    function testFuzz_CreateCovenant(bytes32 salt, address creator, address agent, uint256 duration, uint256 depositAmount) public asOwner {
        vm.assume(creator != address(0) && agent != address(0) && creator != agent);
        vm.assume(duration > 0 && duration <= 365 days);
        vm.assume(depositAmount <= 100 ether);
        
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(payable(address(0))).initialize.selector,
            creator,
            agent,
            duration,
            depositAmount,
            address(0),
            bytes32(uint256(salt))
        );
        
        address proxy = factory.createCovenant(salt, initData);
        
        assertTrue(proxy != address(0));
        assertEq(registry.getCovenantId(proxy), registry.totalCovenants());
    }
    function testFuzz_CreateCovenantMultiple(uint256 count) public asOwner {
        vm.assume(count > 0 && count <= 50);
        
        for (uint256 i = 0; i < count; i++) {
            bytes32 salt = keccak256(abi.encode(i));
            bytes memory initData = abi.encodeWithSelector(
                CovenantImplementation(payable(address(0))).initialize.selector,
                alice,
                bob,
                30 days,
                1 ether,
                address(0),
                bytes32(i)
            );
            factory.createCovenant(salt, initData);
        }
        
        assertEq(registry.totalCovenants(), count);
    }

    // ==================== GOVERNANCE FUZZ TESTS (10) ====================
    function testFuzz_Propose(string memory description) public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), description);
            assertEq(pid, 1);
        }
    }
    function testFuzz_CastVote(uint8 support) public {
        vm.assume(support <= 2);
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
            governor.castVote(pid, support);
            
            ICovenantGovernor.Proposal memory p = governor.getProposal(pid);
            if (support == 0) assertEq(p.againstVotes, 100);
            else if (support == 1) assertEq(p.forVotes, 100);
            else assertEq(p.abstainVotes, 100);
        }
    }

    receive() external payable {}
}
