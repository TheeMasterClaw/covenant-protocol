// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../fixtures/DeploymentFixtures.sol";
import {CovenantImplementation} from "../../../contracts-v2/core/CovenantImplementation.sol";

contract CovenantGasTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== COVENANT FACTORY GAS (15) ====================
    function testGas_CreateCovenant() public asOwner {
        bytes32 salt = keccak256("gas1");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        uint256 gasBefore = gasleft();
        factory.createCovenant(salt, initData);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("CreateCovenant Gas", gasUsed);
        assertTrue(gasUsed < 500000);
    }
    function testGas_CreateCovenant_10() public asOwner {
        for (uint256 i = 0; i < 10; i++) {
            bytes32 salt = keccak256(abi.encodePacked("batch", i));
            bytes memory initData = abi.encodeWithSelector(
                CovenantImplementation(address(0)).initialize.selector,
                alice,
                bob,
                30 days,
                1 ether,
                address(0),
                bytes32(i)
            );
            factory.createCovenant(salt, initData);
        }
    }
    function testGas_CreateCovenant_100() public asOwner {
        for (uint256 i = 0; i < 100; i++) {
            bytes32 salt = keccak256(abi.encodePacked("batch", i));
            bytes memory initData = abi.encodeWithSelector(
                CovenantImplementation(address(0)).initialize.selector,
                alice,
                bob,
                30 days,
                1 ether,
                address(0),
                bytes32(i)
            );
            factory.createCovenant(salt, initData);
        }
    }
    function testGas_CreateCovenant_WithMetadata() public asOwner {
        bytes32 salt = keccak256("meta");
        bytes32 metadata = keccak256("large metadata hash for testing gas");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            metadata
        );
        uint256 gasBefore = gasleft();
        factory.createCovenant(salt, initData);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("CreateCovenant With Metadata Gas", gasUsed);
    }

    // ==================== COVENANT IMPLEMENTATION GAS (20) ====================
    function testGas_Deposit() public asOwner {
        bytes32 salt = keccak256("deposit");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        CovenantImplementation(p).deposit{value: 1 ether}();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Deposit Gas", gasUsed);
    }
    function testGas_Terminate() public asOwner {
        bytes32 salt = keccak256("term");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        CovenantImplementation(p).terminate();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Terminate Gas", gasUsed);
    }
    function testGas_Withdraw() public asOwner {
        bytes32 salt = keccak256("withdraw");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        CovenantImplementation(p).deposit{value: 1 ether}();
        vm.prank(alice);
        CovenantImplementation(p).terminate();
        vm.prank(alice);
        uint256 gasBefore = gasleft();
        CovenantImplementation(p).withdraw();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Withdraw Gas", gasUsed);
    }
    function testGas_GetBalance() public asOwner {
        bytes32 salt = keccak256("balance");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        uint256 gasBefore = gasleft();
        CovenantImplementation(p).getBalance();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("GetBalance Gas", gasUsed);
    }
    function testGas_CovenantStatus() public asOwner {
        bytes32 salt = keccak256("status");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        uint256 gasBefore = gasleft();
        CovenantImplementation(p).covenantStatus();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("CovenantStatus Gas", gasUsed);
    }

    // ==================== TASK MARKET GAS (20) ====================
    function testGas_CreateTask() public asAlice {
        uint256 gasBefore = gasleft();
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("CreateTask Gas", gasUsed);
    }
    function testGas_CreateTask_ERC20() public asAlice {
        token.approve(address(taskMarket), 1 ether);
        uint256 gasBefore = gasleft();
        taskMarket.createTask(1, 1 ether, address(token), block.timestamp + 1 days, bytes32(0));
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("CreateTask ERC20 Gas", gasUsed);
    }
    function testGas_CreateTask_10() public asAlice {
        for (uint256 i = 0; i < 10; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        }
    }
    function testGas_CreateTask_100() public asAlice {
        for (uint256 i = 0; i < 100; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        }
    }
    function testGas_AssignTask() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        uint256 gasBefore = gasleft();
        taskMarket.assignTask(1);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("AssignTask Gas", gasUsed);
    }
    function testGas_SubmitTask() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        uint256 gasBefore = gasleft();
        taskMarket.submitTask(1, keccak256("proof"));
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("SubmitTask Gas", gasUsed);
    }
    function testGas_CompleteTask() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        uint256 gasBefore = gasleft();
        taskMarket.completeTask(1);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("CompleteTask Gas", gasUsed);
    }
    function testGas_CancelTask() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256 gasBefore = gasleft();
        taskMarket.cancelTask(1);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("CancelTask Gas", gasUsed);
    }
    function testGas_DisputeTask() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        vm.prank(bob);
        taskMarket.assignTask(1);
        vm.prank(bob);
        taskMarket.submitTask(1, keccak256("proof"));
        uint256 gasBefore = gasleft();
        taskMarket.disputeTask(1);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("DisputeTask Gas", gasUsed);
    }
    function testGas_GetTask() public asAlice {
        taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        uint256 gasBefore = gasleft();
        taskMarket.getTask(1);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("GetTask Gas", gasUsed);
    }
    function testGas_GetTasksByCovenant_10() public asAlice {
        for (uint256 i = 0; i < 10; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        }
        uint256 gasBefore = gasleft();
        taskMarket.getTasksByCovenant(1);
        emit log_named_uint("GetTasksByCovenant 10 Gas", gasBefore - gasleft());
    }
    function testGas_GetTasksByCovenant_100() public asAlice {
        for (uint256 i = 0; i < 100; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
        }
        uint256 gasBefore = gasleft();
        taskMarket.getTasksByCovenant(1);
        emit log_named_uint("GetTasksByCovenant 100 Gas", gasBefore - gasleft());
    }
    function testGas_GetTasksByAssignee() public asAlice {
        for (uint256 i = 0; i < 10; i++) {
            taskMarket.createTask{value: 1 ether}(1, 1 ether, address(0), block.timestamp + 1 days, bytes32(0));
            vm.prank(bob);
            taskMarket.assignTask(i + 1);
        }
        uint256 gasBefore = gasleft();
        taskMarket.getTasksByAssignee(bob);
        emit log_named_uint("GetTasksByAssignee 10 Gas", gasBefore - gasleft());
    }

    // ==================== REPUTATION STAKE GAS (15) ====================
    function testGas_Stake() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        uint256 gasBefore = gasleft();
        reputationStake.stake(1 ether, 7 days);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Stake Gas", gasUsed);
    }
    function testGas_Stake_10() public asAlice {
        token.approve(address(reputationStake), 10 ether);
        for (uint256 i = 0; i < 10; i++) {
            reputationStake.stake(1 ether, 7 days);
        }
    }
    function testGas_Stake_100() public asAlice {
        token.approve(address(reputationStake), 100 ether);
        for (uint256 i = 0; i < 100; i++) {
            reputationStake.stake(1 ether, 7 days);
        }
    }
    function testGas_Unstake() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        uint256 gasBefore = gasleft();
        reputationStake.unstake(1 ether);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Unstake Gas", gasUsed);
    }
    function testGas_Slash() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        uint256 gasBefore = gasleft();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Slash Gas", gasUsed);
    }
    function testGas_GetStakeInfo() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        uint256 gasBefore = gasleft();
        reputationStake.getStakeInfo(alice);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("GetStakeInfo Gas", gasUsed);
    }
    function testGas_TotalStaked() public view {
        uint256 gasBefore = gasleft();
        reputationStake.totalStaked();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("TotalStaked Gas", gasUsed);
    }

    // ==================== COVEN TOKEN GAS (15) ====================
    function testGas_MintInflation() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        uint256 gasBefore = gasleft();
        covenToken.mintInflation();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("MintInflation Gas", gasUsed);
    }
    function testGas_Transfer() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            uint256 gasBefore = gasleft();
            covenToken.transfer(alice, 1);
            uint256 gasUsed = gasBefore - gasleft();
            emit log_named_uint("Transfer Gas", gasUsed);
        }
    }
    function testGas_Approve() public {
        uint256 gasBefore = gasleft();
        covenToken.approve(alice, 1 ether);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Approve Gas", gasUsed);
    }
    function testGas_Burn() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            uint256 gasBefore = gasleft();
            covenToken.burn(1);
            uint256 gasUsed = gasBefore - gasleft();
            emit log_named_uint("Burn Gas", gasUsed);
        }
    }
    function testGas_SetStakingContract() public asOwner {
        uint256 gasBefore = gasleft();
        covenToken.setStakingContract(alice);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("SetStakingContract Gas", gasUsed);
    }
    function testGas_GetTokenomics() public view {
        uint256 gasBefore = gasleft();
        covenToken.getTokenomics();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("GetTokenomics Gas", gasUsed);
    }

    // ==================== GOVERNANCE GAS (15) ====================
    function testGas_Propose() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 gasBefore = gasleft();
            governor.propose(alice, new bytes(0), "test");
            uint256 gasUsed = gasBefore - gasleft();
            emit log_named_uint("Propose Gas", gasUsed);
        }
    }
    function testGas_CastVote() public {
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
            uint256 gasBefore = gasleft();
            governor.castVote(pid, 1);
            uint256 gasUsed = gasBefore - gasleft();
            emit log_named_uint("CastVote Gas", gasUsed);
        }
    }
    function testGas_Execute() public {
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
            uint256 gasBefore = gasleft();
            governor.execute(pid);
            uint256 gasUsed = gasBefore - gasleft();
            emit log_named_uint("Execute Gas", gasUsed);
        }
    }
    function testGas_Cancel() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            uint256 gasBefore = gasleft();
            governor.cancel(pid);
            uint256 gasUsed = gasBefore - gasleft();
            emit log_named_uint("Cancel Gas", gasUsed);
        }
    }
    function testGas_GetProposal() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.prank(owner);
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            uint256 pid = governor.propose(alice, new bytes(0), "test");
            uint256 gasBefore = gasleft();
            governor.getProposal(pid);
            uint256 gasUsed = gasBefore - gasleft();
            emit log_named_uint("GetProposal Gas", gasUsed);
        }
    }

    // ==================== REGISTRY GAS (10) ====================
    function testGas_RegisterCovenant() public asOwner {
        bytes32 salt = keccak256("reg");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        uint256 gasBefore = gasleft();
        factory.createCovenant(salt, initData);
        emit log_named_uint("RegisterCovenant Gas", gasBefore - gasleft());
    }
    function testGas_GetMetadata() public asOwner {
        bytes32 salt = keccak256("meta");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        uint256 gasBefore = gasleft();
        registry.getMetadata(p);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("GetMetadata Gas", gasUsed);
    }
    function testGas_TotalCovenants() public view {
        uint256 gasBefore = gasleft();
        registry.totalCovenants();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("TotalCovenants Gas", gasUsed);
    }
    function testGas_CovenantById() public view {
        uint256 gasBefore = gasleft();
        registry.covenantById(1);
        emit log_named_uint("CovenantById Gas", gasBefore - gasleft());
    }
    function testGas_CovenantToId() public asOwner {
        bytes32 salt = keccak256("toid");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        uint256 gasBefore = gasleft();
        registry.covenantToId(p);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("CovenantToId Gas", gasUsed);
    }

    // ==================== AGENT REGISTRY GAS (10) ====================
    function testGas_RegisterAgent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        uint256 gasBefore = gasleft();
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("RegisterAgent Gas", gasUsed);
    }
    function testGas_UpdateProfile() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256[] memory newSkills = new uint256[](1);
        newSkills[0] = 2;
        uint256 gasBefore = gasleft();
        agentRegistry.updateProfile("ipfs://new", newSkills);
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("UpdateProfile Gas", gasUsed);
    }
    function testGas_Deactivate() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256 gasBefore = gasleft();
        agentRegistry.deactivate();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Deactivate Gas", gasUsed);
    }
    function testGas_Reactivate() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        agentRegistry.deactivate();
        uint256 gasBefore = gasleft();
        agentRegistry.reactivate();
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("Reactivate Gas", gasUsed);
    }
    function testGas_GetAgent() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        uint256 gasBefore = gasleft();
        agentRegistry.getAgent(address(this));
        uint256 gasUsed = gasBefore - gasleft();
        emit log_named_uint("GetAgent Gas", gasUsed);
    }
    function testGas_FindAgentsBySkill() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        for (uint256 i = 0; i < 10; i++) {
            address agent = address(uint160(i + 1000));
            vm.deal(agent, 0.01 ether);
            vm.prank(agent);
            agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        }
        uint256 gasBefore = gasleft();
        agentRegistry.findAgentsBySkill(1);
        emit log_named_uint("FindAgentsBySkill 10 Gas", gasBefore - gasleft());
    }
    function testGas_GetTopAgents() public {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = 1;
        for (uint256 i = 0; i < 10; i++) {
            address agent = address(uint160(i + 1000));
            vm.deal(agent, 0.01 ether);
            vm.prank(agent);
            agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
        }
        uint256 gasBefore = gasleft();
        agentRegistry.getTopAgents(5);
        emit log_named_uint("GetTopAgents Gas", gasBefore - gasleft());
    }

    receive() external payable {}
}
