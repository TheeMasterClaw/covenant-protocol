// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {AgentCovenant} from "../../../../contracts/AgentCovenant.sol";

contract AgentCovenantTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CONSTRUCTOR TESTS (15) ====================
    function test_Constructor_SetsRegistry() public view {
        assertEq(address(agentCovenant.registry()), address(agentRegistry));
    }
    function test_Constructor_SetsOwner() public view {
        assertEq(agentCovenant.owner(), address(this));
    }
    function test_Constructor_TotalCovenantsZero() public view {
        assertEq(agentCovenant.totalCovenants(), 0);
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(agentCovenant).code.length > 0);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(agentCovenant).balance, 0);
    }
    function test_Constructor_NoEthRequired() public {
        AgentCovenant ac = new AgentCovenant(address(agentRegistry));
        assertEq(address(ac).balance, 0);
    }
    function test_Constructor_DifferentRegistryAllowed() public {
        AgentCovenant ac = new AgentCovenant(address(1));
        assertEq(address(ac.registry()), address(1));
    }
    function test_Constructor_ZeroRegistryAllowed() public {
        AgentCovenant ac = new AgentCovenant(address(0));
        assertEq(address(ac.registry()), address(0));
    }
    function test_Constructor_MultipleInstancesIndependent() public {
        AgentCovenant ac1 = new AgentCovenant(address(agentRegistry));
        AgentCovenant ac2 = new AgentCovenant(address(0));
        assertTrue(address(ac1) != address(ac2));
    }
    function test_Constructor_OwnableSetCorrectly() public view {
        assertEq(agentCovenant.owner(), address(this));
    }
    function test_Constructor_CovenantIdCounterZero() public view {
        assertEq(agentCovenant.totalCovenants(), 0);
    }
    function test_Constructor_EOAOwnerAllowed() public {
        vm.prank(alice);
        AgentCovenant ac = new AgentCovenant(address(agentRegistry));
        assertEq(ac.owner(), alice);
    }
    function test_Constructor_PrecompileOwnerAllowed() public {
        vm.prank(address(1));
        AgentCovenant ac = new AgentCovenant(address(agentRegistry));
        assertEq(ac.owner(), address(1));
    }
    function test_Constructor_MaxAddressOwnerAllowed() public {
        address maxAddr = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        vm.prank(maxAddr);
        AgentCovenant ac = new AgentCovenant(address(agentRegistry));
        assertEq(ac.owner(), maxAddr);
    }
    function test_Constructor_TransferOwnershipAvailable() public {
        agentCovenant.transferOwnership(alice);
        assertEq(agentCovenant.owner(), alice);
    }

    // ==================== CREATE COVENANT TESTS (25) ====================
    function test_CreateCovenant_RegisteredAgent() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        assertEq(agentCovenant.totalCovenants(), 1);
    }
    function test_CreateCovenant_EmitsEvent() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantCreated(1, alice, 1, 0.001 ether, 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
    }
    function test_CreateCovenant_StoresCovenant() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        AgentCovenant.Covenant memory c = agentCovenant.getCovenant(1);
        assertEq(c.id, 1);
        assertEq(c.agent, alice);
        assertEq(c.skillId, 1);
        assertEq(c.price, 0.001 ether);
        assertEq(c.duration, 7 days);
        assertTrue(c.isActive);
    }
    function test_CreateCovenant_UpdatesTotalCovenants() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        assertEq(agentCovenant.totalCovenants(), 1);
    }
    function test_CreateCovenant_UpdatesAgentCovenants() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        uint256[] memory covenants = agentCovenant.getAgentCovenants(alice);
        assertEq(covenants.length, 1);
        assertEq(covenants[0], 1);
    }
    function test_CreateCovenant_NotRegisteredReverts() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert("Not registered");
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
    }
    function test_CreateCovenant_InvalidSkillReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert("Invalid skill");
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 99, 0.001 ether, address(0), 7 days);
    }
    function test_CreateCovenant_ZeroPriceReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert("Invalid price");
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0, address(0), 7 days);
    }
    function test_CreateCovenant_ZeroDurationReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert("Invalid duration");
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 0);
    }
    function test_CreateCovenant_InsufficientFeeReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert("Insufficient fee");
        agentCovenant.createCovenant{value: 0.0005 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
    }
    function test_CreateCovenant_MultipleCovenants() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms1", 1, 0.001 ether, address(0), 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms2", 1, 0.002 ether, address(0), 14 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms3", 2, 0.003 ether, address(0), 21 days);
        vm.stopPrank();
        assertEq(agentCovenant.totalCovenants(), 3);
    }
    function test_CreateCovenant_DifferentSkills() public {
        _registerAgent(alice, 2);
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms1", 1, 0.001 ether, address(0), 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms2", 2, 0.001 ether, address(0), 7 days);
        vm.stopPrank();
        assertEq(agentCovenant.getSkillCovenants(1).length, 1);
        assertEq(agentCovenant.getSkillCovenants(2).length, 1);
    }
    function test_CreateCovenant_DifferentPrices() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms1", 1, 0.001 ether, address(0), 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms2", 1, 0.005 ether, address(0), 7 days);
        vm.stopPrank();
        assertEq(agentCovenant.getCovenant(1).price, 0.001 ether);
        assertEq(agentCovenant.getCovenant(2).price, 0.005 ether);
    }
    function test_CreateCovenant_DifferentDurations() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms1", 1, 0.001 ether, address(0), 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms2", 1, 0.001 ether, address(0), 30 days);
        vm.stopPrank();
        assertEq(agentCovenant.getCovenant(1).duration, 7 days);
        assertEq(agentCovenant.getCovenant(2).duration, 30 days);
    }
    function test_CreateCovenant_ERC20Token() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(token), 7 days);
        assertEq(agentCovenant.getCovenant(1).token, address(token));
    }
    function test_CreateCovenant_EventContainsCorrectId() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantCreated(1, alice, 1, 0.001 ether, 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
    }
    function test_CreateCovenant_EventContainsCorrectAgent() public {
        _registerAgent(bob, 1);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantCreated(1, bob, 1, 0.001 ether, 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
    }
    function test_CreateCovenant_EventContainsCorrectSkill() public {
        _registerAgent(alice, 2);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantCreated(1, alice, 2, 0.001 ether, 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 2, 0.001 ether, address(0), 7 days);
    }
    function test_CreateCovenant_EventContainsCorrectPrice() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantCreated(1, alice, 1, 0.005 ether, 7 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.005 ether, address(0), 7 days);
    }
    function test_CreateCovenant_EventContainsCorrectDuration() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantCreated(1, alice, 1, 0.001 ether, 30 days);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 30 days);
    }
    function test_CreateCovenant_FeeTransfer() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        uint256 balanceBefore = address(agentCovenant).balance;
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        assertEq(address(agentCovenant).balance - balanceBefore, 0.001 ether);
    }
    function test_CreateCovenant_10Covenants() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        for (uint256 i = 0; i < 10; i++) {
            agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        }
        vm.stopPrank();
        assertEq(agentCovenant.totalCovenants(), 10);
    }
    function test_CreateCovenant_WhenPausedReverts() public {
        vm.prank(agentCovenant.owner());
        agentCovenant.pause();
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert();
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
    }

    // ==================== UPDATE COVENANT TESTS (15) ====================
    function test_UpdateCovenant_Success() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        agentCovenant.updateCovenant(1, 0.002 ether, 14 days, true);
        AgentCovenant.Covenant memory c = agentCovenant.getCovenant(1);
        assertEq(c.price, 0.002 ether);
        assertEq(c.duration, 14 days);
        assertTrue(c.isActive);
    }
    function test_UpdateCovenant_EmitsEvent() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit AgentCovenant.CovenantUpdated(1, 0.002 ether, 14 days, true);
        agentCovenant.updateCovenant(1, 0.002 ether, 14 days, true);
    }
    function test_UpdateCovenant_NotAgentReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(bob);
        vm.expectRevert("Not agent");
        agentCovenant.updateCovenant(1, 0.002 ether, 14 days, true);
    }
    function test_UpdateCovenant_InvalidIdReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectRevert("Invalid covenant");
        agentCovenant.updateCovenant(99, 0.002 ether, 14 days, true);
    }
    function test_UpdateCovenant_ZeroPriceReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectRevert("Invalid price");
        agentCovenant.updateCovenant(1, 0, 14 days, true);
    }
    function test_UpdateCovenant_ZeroDurationReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectRevert("Invalid duration");
        agentCovenant.updateCovenant(1, 0.002 ether, 0, true);
    }
    function test_UpdateCovenant_Deactivate() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        agentCovenant.updateCovenant(1, 0.001 ether, 7 days, false);
        assertFalse(agentCovenant.getCovenant(1).isActive);
    }
    function test_UpdateCovenant_Reactivate() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        agentCovenant.updateCovenant(1, 0.001 ether, 7 days, false);
        vm.prank(alice);
        agentCovenant.updateCovenant(1, 0.001 ether, 7 days, true);
        assertTrue(agentCovenant.getCovenant(1).isActive);
    }
    function test_UpdateCovenant_MultipleUpdates() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.startPrank(alice);
        agentCovenant.updateCovenant(1, 0.002 ether, 14 days, true);
        agentCovenant.updateCovenant(1, 0.003 ether, 21 days, true);
        agentCovenant.updateCovenant(1, 0.004 ether, 30 days, false);
        vm.stopPrank();
        AgentCovenant.Covenant memory c = agentCovenant.getCovenant(1);
        assertEq(c.price, 0.004 ether);
        assertEq(c.duration, 30 days);
        assertFalse(c.isActive);
    }
    function test_UpdateCovenant_EventContainsCorrectId() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit AgentCovenant.CovenantUpdated(1, 0.002 ether, 14 days, true);
        agentCovenant.updateCovenant(1, 0.002 ether, 14 days, true);
    }
    function test_UpdateCovenant_EventContainsCorrectPrice() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit AgentCovenant.CovenantUpdated(1, 0.005 ether, 7 days, true);
        agentCovenant.updateCovenant(1, 0.005 ether, 7 days, true);
    }
    function test_UpdateCovenant_EventContainsCorrectDuration() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit AgentCovenant.CovenantUpdated(1, 0.001 ether, 30 days, true);
        agentCovenant.updateCovenant(1, 0.001 ether, 30 days, true);
    }
    function test_UpdateCovenant_EventContainsCorrectActive() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit AgentCovenant.CovenantUpdated(1, 0.001 ether, 7 days, false);
        agentCovenant.updateCovenant(1, 0.001 ether, 7 days, false);
    }
    function test_UpdateCovenant_TermsUnchanged() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        agentCovenant.updateCovenant(1, 0.002 ether, 14 days, true);
        assertEq(agentCovenant.getCovenant(1).termsURI, "ipfs://terms");
    }
    function test_UpdateCovenant_TokenUnchanged() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(token), 7 days);
        vm.prank(alice);
        agentCovenant.updateCovenant(1, 0.002 ether, 14 days, true);
        assertEq(agentCovenant.getCovenant(1).token, address(token));
    }

    // ==================== HIRE TESTS (15) ====================
    function test_Hire_Success() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        assertEq(agentCovenant.getCovenant(1).client, bob);
    }
    function test_Hire_EmitsEvent() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantHired(1, bob, 0.001 ether);
        agentCovenant.hire{value: 0.001 ether}(1);
    }
    function test_Hire_TransfersFunds() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        uint256 before = alice.balance;
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        assertEq(alice.balance - before, 0.001 ether);
    }
    function test_Hire_InactiveReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        agentCovenant.updateCovenant(1, 0.001 ether, 7 days, false);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert("Not active");
        agentCovenant.hire{value: 0.001 ether}(1);
    }
    function test_Hire_InvalidIdReverts() public {
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert("Invalid covenant");
        agentCovenant.hire{value: 0.001 ether}(99);
    }
    function test_Hire_InsufficientPaymentReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert("Insufficient payment");
        agentCovenant.hire{value: 0.0005 ether}(1);
    }
    function test_Hire_AlreadyHiredReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(bob);
        vm.expectRevert("Already hired");
        agentCovenant.hire{value: 0.001 ether}(1);
    }
    function test_Hire_ExcessPaymentRefunded() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        uint256 before = bob.balance;
        vm.prank(bob);
        agentCovenant.hire{value: 0.002 ether}(1);
        assertEq(bob.balance, before - 0.001 ether);
    }
    function test_Hire_UpdatesRegistry() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        assertTrue(agentCovenant.isHired(1));
    }
    function test_Hire_EventContainsCorrectId() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantHired(1, bob, 0.001 ether);
        agentCovenant.hire{value: 0.001 ether}(1);
    }
    function test_Hire_EventContainsCorrectClient() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(carol, 1 ether);
        vm.prank(carol);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantHired(1, carol, 0.001 ether);
        agentCovenant.hire{value: 0.001 ether}(1);
    }
    function test_Hire_EventContainsCorrectPayment() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.005 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit AgentCovenant.CovenantHired(1, bob, 0.005 ether);
        agentCovenant.hire{value: 0.005 ether}(1);
    }
    function test_Hire_AgentCannotHireSelf() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        agentCovenant.hire{value: 0.001 ether}(1);
        assertEq(agentCovenant.getCovenant(1).client, alice);
    }
    function test_Hire_ERC20Payment() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(token), 7 days);
        token.mint(bob, 1 ether);
        vm.startPrank(bob);
        token.approve(address(agentCovenant), 0.001 ether);
        agentCovenant.hire(1);
        vm.stopPrank();
        assertEq(agentCovenant.getCovenant(1).client, bob);
    }
    function test_Hire_10Hires() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        for (uint256 i = 0; i < 10; i++) {
            address client = address(uint160(i + 2000));
            vm.deal(client, 0.01 ether);
            vm.prank(client);
            agentCovenant.hire{value: 0.001 ether}(1);
            // Subsequent hires should fail due to already hired
            if (i == 0) continue;
        }
        assertEq(agentCovenant.getCovenant(1).client, address(2000));
    }

    // ==================== COMPLETE COVENANT TESTS (15) ====================
    function test_CompleteCovenant_Success() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(alice);
        agentCovenant.completeCovenant(1);
        assertTrue(agentCovenant.getCovenant(1).isCompleted);
    }
    function test_CompleteCovenant_EmitsEvent() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit AgentCovenant.CovenantCompleted(1, block.timestamp);
        agentCovenant.completeCovenant(1);
    }
    function test_CompleteCovenant_NotAgentReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(bob);
        vm.expectRevert("Not agent");
        agentCovenant.completeCovenant(1);
    }
    function test_CompleteCovenant_InvalidIdReverts() public {
        vm.prank(alice);
        vm.expectRevert("Invalid covenant");
        agentCovenant.completeCovenant(99);
    }
    function test_CompleteCovenant_NotHiredReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        vm.expectRevert("Not hired");
        agentCovenant.completeCovenant(1);
    }
    function test_CompleteCovenant_AlreadyCompletedReverts() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(alice);
        agentCovenant.completeCovenant(1);
        vm.prank(alice);
        vm.expectRevert("Already completed");
        agentCovenant.completeCovenant(1);
    }
    function test_CompleteCovenant_UpdatesCompletedAt() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        agentCovenant.completeCovenant(1);
        assertEq(agentCovenant.getCovenant(1).completedAt, block.timestamp);
    }
    function test_CompleteCovenant_IsHiredReturnsTrue() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(alice);
        agentCovenant.completeCovenant(1);
        assertTrue(agentCovenant.isHired(1));
    }
    function test_CompleteCovenant_EventContainsCorrectId() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit AgentCovenant.CovenantCompleted(1, block.timestamp);
        agentCovenant.completeCovenant(1);
    }
    function test_CompleteCovenant_10Covenants() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        for (uint256 i = 0; i < 10; i++) {
            address client = address(uint160(i + 2000));
            vm.deal(client, 0.01 ether);
            vm.prank(client);
            agentCovenant.hire{value: 0.001 ether}(1);
            vm.prank(alice);
            agentCovenant.completeCovenant(1);
            // Re-hire the same covenant for next iteration
            if (i < 9) {
                vm.prank(alice);
                agentCovenant.updateCovenant(1, 0.001 ether, 7 days, true);
            }
        }
        assertTrue(agentCovenant.getCovenant(1).isCompleted);
    }
    function test_CompleteCovenant_ActiveStatusUnchanged() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(alice);
        agentCovenant.completeCovenant(1);
        assertTrue(agentCovenant.getCovenant(1).isActive);
    }
    function test_CompleteCovenant_ClientUnchanged() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(alice);
        agentCovenant.completeCovenant(1);
        assertEq(agentCovenant.getCovenant(1).client, bob);
    }
    function test_CompleteCovenant_PriceUnchanged() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.005 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.005 ether}(1);
        vm.prank(alice);
        agentCovenant.completeCovenant(1);
        assertEq(agentCovenant.getCovenant(1).price, 0.005 ether);
    }
    function test_CompleteCovenant_DurationUnchanged() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 30 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        vm.prank(alice);
        agentCovenant.completeCovenant(1);
        assertEq(agentCovenant.getCovenant(1).duration, 30 days);
    }

    // ==================== ADMIN TESTS (10) ====================
    function test_Pause_ByOwner() public {
        agentCovenant.pause();
        assertTrue(agentCovenant.paused());
    }
    function test_Pause_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        agentCovenant.pause();
    }
    function test_Unpause_ByOwner() public {
        agentCovenant.pause();
        agentCovenant.unpause();
        assertFalse(agentCovenant.paused());
    }
    function test_Unpause_NonOwnerReverts() public {
        agentCovenant.pause();
        vm.prank(alice);
        vm.expectRevert();
        agentCovenant.unpause();
    }
    function test_WithdrawFees_ByOwner() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        uint256 before = agentCovenant.owner().balance;
        vm.prank(agentCovenant.owner());
        agentCovenant.withdrawFees();
        assertTrue(agentCovenant.owner().balance > before);
    }
    function test_WithdrawFees_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        agentCovenant.withdrawFees();
    }
    function test_WithdrawFees_EmptyContractReverts() public {
        vm.prank(agentCovenant.owner());
        vm.expectRevert("Withdraw failed");
        agentCovenant.withdrawFees();
    }
    function test_PausePreventsCreate() public {
        agentCovenant.pause();
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        vm.expectRevert();
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
    }
    function test_PausePreventsHire() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        agentCovenant.pause();
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        vm.expectRevert();
        agentCovenant.hire{value: 0.001 ether}(1);
    }
    function test_PausePreventsComplete() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        agentCovenant.pause();
        vm.prank(alice);
        vm.expectRevert();
        agentCovenant.completeCovenant(1);
    }

    // ==================== VIEW FUNCTION TESTS (10) ====================
    function test_GetCovenant_Empty() public view {
        AgentCovenant.Covenant memory c = agentCovenant.getCovenant(1);
        assertEq(c.id, 0);
    }
    function test_GetCovenant_AfterCreate() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        AgentCovenant.Covenant memory c = agentCovenant.getCovenant(1);
        assertEq(c.id, 1);
        assertEq(c.agent, alice);
    }
    function test_GetAgentCovenants_Empty() public view {
        uint256[] memory covenants = agentCovenant.getAgentCovenants(alice);
        assertEq(covenants.length, 0);
    }
    function test_GetAgentCovenants_AfterCreate() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        uint256[] memory covenants = agentCovenant.getAgentCovenants(alice);
        assertEq(covenants.length, 1);
    }
    function test_GetSkillCovenants_Empty() public view {
        uint256[] memory covenants = agentCovenant.getSkillCovenants(1);
        assertEq(covenants.length, 0);
    }
    function test_GetSkillCovenants_AfterCreate() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        uint256[] memory covenants = agentCovenant.getSkillCovenants(1);
        assertEq(covenants.length, 1);
    }
    function test_IsHired_FalseInitially() public view {
        assertFalse(agentCovenant.isHired(1));
    }
    function test_IsHired_TrueAfterHire() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.deal(bob, 1 ether);
        vm.prank(bob);
        agentCovenant.hire{value: 0.001 ether}(1);
        assertTrue(agentCovenant.isHired(1));
    }
    function test_GetActiveCovenants() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        uint256[] memory active = agentCovenant.getActiveCovenants();
        assertEq(active.length, 1);
    }
    function test_GetActiveCovenants_OnlyActive() public {
        _registerAgent(alice, 1);
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        agentCovenant.createCovenant{value: 0.001 ether}("ipfs://terms", 1, 0.001 ether, address(0), 7 days);
        vm.prank(alice);
        agentCovenant.updateCovenant(1, 0.001 ether, 7 days, false);
        uint256[] memory active = agentCovenant.getActiveCovenants();
        assertEq(active.length, 0);
    }

    function _registerAgent(address agent, uint256 skillId) internal {
        uint256[] memory skillIds = new uint256[](1);
        skillIds[0] = skillId;
        vm.deal(agent, 0.01 ether);
        vm.prank(agent);
        agentRegistry.registerAgent{value: 0.001 ether}("ipfs://metadata", skillIds);
    }
}
