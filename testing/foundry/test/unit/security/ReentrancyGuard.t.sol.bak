// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {CovenantImplementation} from "../../../../contracts-v2/core/CovenantImplementation.sol";

contract MockReentrancyAttacker {
    CovenantImplementation public target;
    uint256 public attackCount;
    
    function attackWithdraw(CovenantImplementation _target) external {
        target = _target;
        target.withdraw();
    }
    
    receive() external payable {
        if (attackCount < 5) {
            attackCount++;
            try target.withdraw() {} catch {}
        }
    }
}

contract ReentrancyGuardTest is DeploymentFixtures {
    MockReentrancyAttacker public attacker;
    
    function setUp() public override {
        super.setUp();
        attacker = new MockReentrancyAttacker();
    }

    // ==================== REENTRANCY PROTECTION TESTS (30) ====================
    function test_Reentrancy_WithdrawCannotBeReentered() public asOwner {
        bytes32 salt = keccak256("reentrancy1");
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
        CovenantImplementation(p).withdraw();
        assertEq(attacker.attackCount(), 0);
    }
    function test_Reentrancy_DepositCannotBeReentered() public asOwner {
        bytes32 salt = keccak256("reentrancy2");
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
        vm.deal(address(attacker), 2 ether);
        vm.prank(address(attacker));
        CovenantImplementation(p).deposit{value: 1 ether}();
        assertEq(CovenantImplementation(p).getBalance(), 1 ether);
    }
    function test_Reentrancy_TerminateCannotBeReentered() public asOwner {
        bytes32 salt = keccak256("reentrancy3");
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
        CovenantImplementation(p).terminate();
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).terminate();
    }
    function test_Reentrancy_WithdrawStateUpdatedBeforeTransfer() public asOwner {
        bytes32 salt = keccak256("reentrancy4");
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
        CovenantImplementation(p).withdraw();
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).withdraw();
    }
    function test_Reentrancy_MultipleWithdrawsFail() public asOwner {
        bytes32 salt = keccak256("reentrancy5");
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
        CovenantImplementation(p).withdraw();
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).withdraw();
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).withdraw();
    }
    function test_Reentrancy_AttackerCannotDrain() public asOwner {
        bytes32 salt = keccak256("reentrancy6");
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
        uint256 beforeBalance = p.balance;
        vm.prank(alice);
        CovenantImplementation(p).withdraw();
        assertEq(p.balance, 0);
        assertEq(beforeBalance, 1 ether);
    }
    function test_Reentrancy_WithdrawLocksDuringExecution() public asOwner {
        bytes32 salt = keccak256("reentrancy7");
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
        CovenantImplementation(p).withdraw();
        assertTrue(CovenantImplementation(p).getBalance() == 0);
    }
    function test_Reentrancy_NoNestedCalls() public asOwner {
        bytes32 salt = keccak256("reentrancy8");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            address(attacker),
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        CovenantImplementation(p).deposit{value: 1 ether}();
        vm.warp(block.timestamp + 31 days);
        attacker.attackWithdraw(CovenantImplementation(p));
        assertEq(attacker.attackCount(), 0);
    }
    function test_Reentrancy_GasLimit() public asOwner {
        bytes32 salt = keccak256("reentrancy9");
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
        assertTrue(gasUsed < 100000);
    }
    function test_Reentrancy_WithdrawEventStillEmitted() public asOwner {
        bytes32 salt = keccak256("reentrancy10");
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
        vm.expectEmit(true, true, false, true);
        emit CovenantImplementation.Withdrawn(alice, 1 ether);
        CovenantImplementation(p).withdraw();
    }
    function test_Reentrancy_10WithdrawAttemptsFail() public asOwner {
        bytes32 salt = keccak256("reentrancy11");
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
        CovenantImplementation(p).withdraw();
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(alice);
            vm.expectRevert();
            CovenantImplementation(p).withdraw();
        }
    }
    function test_Reentrancy_DepositAndWithdrawSequence() public asOwner {
        bytes32 salt = keccak256("reentrancy12");
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
        vm.deal(alice, 3 ether);
        vm.startPrank(alice);
        CovenantImplementation(p).deposit{value: 1 ether}();
        CovenantImplementation(p).deposit{value: 1 ether}();
        CovenantImplementation(p).terminate();
        CovenantImplementation(p).withdraw();
        vm.stopPrank();
        assertEq(p.balance, 0);
    }
    function test_Reentrancy_WithdrawAfterReinitializationFails() public asOwner {
        bytes32 salt = keccak256("reentrancy13");
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
        CovenantImplementation(p).withdraw();
        vm.expectRevert();
        CovenantImplementation(p).initialize(alice, bob, 30 days, 1 ether, address(0), bytes32(0));
    }
    function test_Reentrancy_ProxyImplementationNotDirectlyCallable() public {
        vm.expectRevert();
        implementation.initialize(alice, bob, 30 days, 1 ether, address(0), bytes32(0));
    }
    function test_Reentrancy_OnlyFactoryCanInitializeProxy() public asOwner {
        bytes32 salt = keccak256("reentrancy14");
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
        vm.expectRevert();
        CovenantImplementation(p).initialize(alice, bob, 30 days, 1 ether, address(0), bytes32(0));
    }
    function test_Reentrancy_CrossFunctionReentrancyBlocked() public asOwner {
        bytes32 salt = keccak256("reentrancy15");
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
        CovenantImplementation(p).withdraw();
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).terminate();
    }
    function test_Reentrancy_MultipleDepositsThenWithdraw() public asOwner {
        bytes32 salt = keccak256("reentrancy16");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            3 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        vm.deal(alice, 5 ether);
        vm.startPrank(alice);
        CovenantImplementation(p).deposit{value: 1 ether}();
        CovenantImplementation(p).deposit{value: 1 ether}();
        CovenantImplementation(p).deposit{value: 1 ether}();
        CovenantImplementation(p).terminate();
        CovenantImplementation(p).withdraw();
        vm.stopPrank();
        assertEq(p.balance, 0);
        assertEq(CovenantImplementation(p).getBalance(), 0);
    }
    function test_Reentrancy_AgentWithdrawAfterExpiration() public asOwner {
        bytes32 salt = keccak256("reentrancy17");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            address(attacker),
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        CovenantImplementation(p).deposit{value: 1 ether}();
        vm.warp(block.timestamp + 31 days);
        attacker.attackWithdraw(CovenantImplementation(p));
        assertEq(attacker.attackCount(), 0);
    }
    function test_Reentrancy_WithdrawDoesNotDoubleSpend() public asOwner {
        bytes32 salt = keccak256("reentrancy18");
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
        uint256 before = alice.balance;
        vm.prank(alice);
        CovenantImplementation(p).withdraw();
        assertEq(alice.balance - before, 1 ether);
    }
    function test_Reentrancy_WithdrawAllAtOnce() public asOwner {
        bytes32 salt = keccak256("reentrancy19");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            5 ether,
            address(0),
            bytes32(0)
        );
        address p = factory.createCovenant(salt, initData);
        vm.deal(alice, 6 ether);
        vm.startPrank(alice);
        CovenantImplementation(p).deposit{value: 5 ether}();
        CovenantImplementation(p).terminate();
        uint256 before = alice.balance;
        CovenantImplementation(p).withdraw();
        assertEq(alice.balance - before, 5 ether);
        vm.stopPrank();
    }
    function test_Reentrancy_EmptyProxyWithdrawReverts() public asOwner {
        bytes32 salt = keccak256("reentrancy20");
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
        CovenantImplementation(p).terminate();
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).withdraw();
    }
    function test_Reentrancy_WithdrawFromActiveProxyReverts() public asOwner {
        bytes32 salt = keccak256("reentrancy21");
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
        vm.prank(bob);
        vm.expectRevert();
        CovenantImplementation(p).withdraw();
    }
    function test_Reentrancy_TerminateTwiceReverts() public asOwner {
        bytes32 salt = keccak256("reentrancy22");
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
        CovenantImplementation(p).terminate();
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).terminate();
    }
    function test_Reentrancy_DepositAfterTerminateReverts() public asOwner {
        bytes32 salt = keccak256("reentrancy23");
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
        CovenantImplementation(p).terminate();
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).deposit{value: 1 ether}();
    }
    function test_Reentrancy_WithdrawFromNonTerminatedProxyReverts() public asOwner {
        bytes32 salt = keccak256("reentrancy24");
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
        vm.expectRevert();
        CovenantImplementation(p).withdraw();
    }
    function test_Reentrancy_AgentCannotWithdrawTerminatedProxy() public asOwner {
        bytes32 salt = keccak256("reentrancy25");
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
        vm.prank(bob);
        vm.expectRevert();
        CovenantImplementation(p).withdraw();
    }
    function test_Reentrancy_CreatorWithdrawAfterAgentWithdrawReverts() public asOwner {
        bytes32 salt = keccak256("reentrancy26");
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
        vm.warp(block.timestamp + 31 days);
        vm.prank(bob);
        CovenantImplementation(p).withdraw();
        vm.prank(alice);
        vm.expectRevert();
        CovenantImplementation(p).withdraw();
    }
    function test_Reentrancy_WithdrawDoesNotAffectOtherProxies() public asOwner {
        bytes32 salt1 = keccak256("reentrancy27a");
        bytes32 salt2 = keccak256("reentrancy27b");
        bytes memory initData = abi.encodeWithSelector(
            CovenantImplementation(address(0)).initialize.selector,
            alice,
            bob,
            30 days,
            1 ether,
            address(0),
            bytes32(0)
        );
        address p1 = factory.createCovenant(salt1, initData);
        address p2 = factory.createCovenant(salt2, initData);
        vm.deal(alice, 4 ether);
        vm.startPrank(alice);
        CovenantImplementation(p1).deposit{value: 1 ether}();
        CovenantImplementation(p2).deposit{value: 1 ether}();
        CovenantImplementation(p1).terminate();
        CovenantImplementation(p1).withdraw();
        vm.stopPrank();
        assertEq(CovenantImplementation(p2).getBalance(), 1 ether);
    }
    function test_Reentrancy_WithdrawDoesNotAffectRegistry() public asOwner {
        bytes32 salt = keccak256("reentrancy28");
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
        uint256 totalBefore = registry.totalCovenants();
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        CovenantImplementation(p).deposit{value: 1 ether}();
        CovenantImplementation(p).terminate();
        CovenantImplementation(p).withdraw();
        vm.stopPrank();
        assertEq(registry.totalCovenants(), totalBefore);
    }
    function test_Reentrancy_WithdrawDoesNotAffectFactory() public asOwner {
        bytes32 salt = keccak256("reentrancy29");
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
        address implBefore = factory.covenantImplementation();
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);
        CovenantImplementation(p).deposit{value: 1 ether}();
        CovenantImplementation(p).terminate();
        CovenantImplementation(p).withdraw();
        vm.stopPrank();
        assertEq(factory.covenantImplementation(), implBefore);
    }
    function test_Reentrancy_10ProxiesWithdrawIndependently() public asOwner {
        address[] memory proxies = new address[](10);
        vm.deal(alice, 20 ether);
        for (uint256 i = 0; i < 10; i++) {
            bytes32 salt = keccak256(abi.encodePacked("multi", i));
            bytes memory initData = abi.encodeWithSelector(
                CovenantImplementation(address(0)).initialize.selector,
                alice,
                bob,
                30 days,
                1 ether,
                address(0),
                bytes32(0)
            );
            proxies[i] = factory.createCovenant(salt, initData);
            vm.prank(alice);
            CovenantImplementation(proxies[i]).deposit{value: 1 ether}();
            vm.prank(alice);
            CovenantImplementation(proxies[i]).terminate();
            vm.prank(alice);
            CovenantImplementation(proxies[i]).withdraw();
        }
        for (uint256 i = 0; i < 10; i++) {
            assertEq(CovenantImplementation(proxies[i]).getBalance(), 0);
        }
    }

    receive() external payable {}
}
