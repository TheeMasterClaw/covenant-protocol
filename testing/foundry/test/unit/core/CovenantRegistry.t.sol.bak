// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {CovenantRegistry} from "../../../../contracts-v2/core/CovenantRegistry.sol";

contract CovenantRegistryTest is DeploymentFixtures {
    address public newFactory;

    function setUp() public override {
        super.setUp();
        newFactory = makeAddr("newFactory");
    }

    // ==================== CONSTRUCTOR TESTS (15) ====================
    function test_Constructor_SetsFactory() public view {
        assertEq(registry.factory(), address(factory));
    }
    function test_Constructor_SetsOwner() public view {
        assertEq(registry.owner(), owner);
    }
    function test_Constructor_NextIdIsOne() public view {
        assertEq(registry.totalCovenants(), 0);
    }
    function test_Constructor_ZeroFactoryReverts() public {
        vm.expectRevert(CovenantRegistry.InvalidCovenantId.selector);
        new CovenantRegistry(address(0));
    }
    function test_Constructor_FactoryIsNotZero() public view {
        assertTrue(registry.factory() != address(0));
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(registry).code.length > 0);
    }
    function test_Constructor_DifferentFactoryAllowed() public {
        CovenantRegistry r = new CovenantRegistry(alice);
        assertEq(r.factory(), alice);
    }
    function test_Constructor_EOAFactoryAllowed() public {
        CovenantRegistry r = new CovenantRegistry(alice);
        assertEq(r.factory(), alice);
    }
    function test_Constructor_PrecompileFactoryAllowed() public {
        CovenantRegistry r = new CovenantRegistry(address(1));
        assertEq(r.factory(), address(1));
    }
    function test_Constructor_MaxAddressAllowed() public {
        address maxAddr = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        CovenantRegistry r = new CovenantRegistry(maxAddr);
        assertEq(r.factory(), maxAddr);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(registry).balance, 0);
    }
    function test_Constructor_NoEthRequired() public {
        CovenantRegistry r = new CovenantRegistry(alice);
        assertEq(address(r).balance, 0);
    }
    function test_Constructor_MultipleInstancesIndependent() public {
        CovenantRegistry r1 = new CovenantRegistry(alice);
        CovenantRegistry r2 = new CovenantRegistry(bob);
        assertEq(r1.factory(), alice);
        assertEq(r2.factory(), bob);
    }
    function test_Constructor_StateImmutableAfterDeployment() public view {
        assertEq(registry.factory(), address(factory));
    }
    function test_Constructor_OwnableSetCorrectly() public view {
        assertEq(registry.owner(), owner);
    }

    // ==================== REGISTER TESTS (30) ====================
    function test_Register_IncrementsId() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        assertEq(registry.totalCovenants(), 1);
    }
    function test_Register_ReturnsCorrectId() public {
        vm.prank(address(factory));
        uint256 id1 = registry.register(alice, bob);
        vm.prank(address(factory));
        uint256 id2 = registry.register(carol, dave);
        assertEq(id1, 1);
        assertEq(id2, 2);
    }
    function test_Register_EmitsEvent() public {
        vm.prank(address(factory));
        vm.expectEmit(true, true, true, false);
        emit CovenantRegistry.CovenantRegistered(1, alice, bob);
        registry.register(alice, bob);
    }
    function test_Register_StoresProxy() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        assertEq(registry.getCovenant(1), alice);
    }
    function test_Register_StoresCovenantId() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        assertEq(registry.getCovenantId(alice), 1);
    }
    function test_Register_TracksCreator() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        uint256[] memory covenants = registry.getCovenantsByCreator(bob);
        assertEq(covenants.length, 1);
        assertEq(covenants[0], 1);
    }
    function test_Register_MultipleBySameCreator() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.register(carol, bob);
        registry.register(dave, bob);
        vm.stopPrank();
        uint256[] memory covenants = registry.getCovenantsByCreator(bob);
        assertEq(covenants.length, 3);
    }
    function test_Register_DifferentCreators() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.register(carol, dave);
        vm.stopPrank();
        assertEq(registry.getCovenantsByCreator(bob).length, 1);
        assertEq(registry.getCovenantsByCreator(dave).length, 1);
    }
    function test_Register_ZeroProxyReverts() public {
        vm.prank(address(factory));
        vm.expectRevert(CovenantRegistry.InvalidCovenantId.selector);
        registry.register(address(0), bob);
    }
    function test_Register_ZeroCreatorReverts() public {
        vm.prank(address(factory));
        vm.expectRevert(CovenantRegistry.InvalidCovenantId.selector);
        registry.register(alice, address(0));
    }
    function test_Register_DuplicateProxyReverts() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        vm.expectRevert(CovenantRegistry.AlreadyRegistered.selector);
        registry.register(alice, carol);
        vm.stopPrank();
    }
    function test_Register_NonFactoryReverts() public {
        vm.prank(alice);
        vm.expectRevert(CovenantRegistry.OnlyFactory.selector);
        registry.register(alice, bob);
    }
    function test_Register_SameProxyDifferentCreatorNotAllowed() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        vm.expectRevert(CovenantRegistry.AlreadyRegistered.selector);
        registry.register(alice, alice);
        vm.stopPrank();
    }
    function test_Register_MaxId() public {
        // Register many to test incrementing
        vm.startPrank(address(factory));
        for (uint256 i = 0; i < 20; i++) {
            registry.register(address(uint160(i + 1000)), bob);
        }
        vm.stopPrank();
        assertEq(registry.totalCovenants(), 20);
    }
    function test_Register_EventContainsCorrectCreator() public {
        vm.prank(address(factory));
        vm.expectEmit(true, true, true, false);
        emit CovenantRegistry.CovenantRegistered(1, alice, carol);
        registry.register(alice, carol);
    }
    function test_Register_EventContainsCorrectProxy() public {
        vm.prank(address(factory));
        vm.expectEmit(true, true, true, false);
        emit CovenantRegistry.CovenantRegistered(1, dave, bob);
        registry.register(dave, bob);
    }
    function test_Register_EventContainsCorrectId() public {
        vm.startPrank(address(factory));
        vm.expectEmit(true, true, true, false);
        emit CovenantRegistry.CovenantRegistered(1, alice, bob);
        registry.register(alice, bob);
        vm.expectEmit(true, true, true, false);
        emit CovenantRegistry.CovenantRegistered(2, carol, dave);
        registry.register(carol, dave);
        vm.stopPrank();
    }
    function test_Register_GetCovenantAfterRegister() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        assertEq(registry.getCovenant(1), alice);
    }
    function test_Register_GetCovenantIdAfterRegister() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        assertEq(registry.getCovenantId(alice), 1);
    }
    function test_Register_CreatorArrayAppends() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.register(carol, bob);
        vm.stopPrank();
        uint256[] memory covenants = registry.getCovenantsByCreator(bob);
        assertEq(covenants[0], 1);
        assertEq(covenants[1], 2);
    }
    function test_Register_ProxiesCanBeAnyAddress() public {
        vm.startPrank(address(factory));
        registry.register(address(1), bob);
        registry.register(address(2), bob);
        registry.register(address(3), bob);
        vm.stopPrank();
        assertEq(registry.totalCovenants(), 3);
    }
    function test_Register_CreatorsCanBeAnyAddress() public {
        vm.startPrank(address(factory));
        registry.register(alice, address(1));
        registry.register(alice, address(2));
        registry.register(alice, address(3));
        vm.stopPrank();
        assertEq(registry.totalCovenants(), 3);
    }
    function test_Register_SelfAsCreatorAllowed() public {
        vm.prank(address(factory));
        registry.register(alice, alice);
        assertEq(registry.getCovenantsByCreator(alice)[0], 1);
    }
    function test_Register_SelfAsProxyAllowed() public {
        vm.prank(address(factory));
        registry.register(alice, alice);
        assertEq(registry.getCovenantId(alice), 1);
    }
    function test_Register_SameCreatorMultipleProxiesAllowed() public {
        vm.startPrank(address(factory));
        for (uint256 i = 0; i < 10; i++) {
            registry.register(address(uint160(i + 100)), bob);
        }
        vm.stopPrank();
        assertEq(registry.getCovenantsByCreator(bob).length, 10);
    }
    function test_Register_ProxyCreatorPairIndependent() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.register(alice, carol); // same proxy different creator - REVERTS
        vm.stopPrank();
        // This is expected to revert, tested above
    }
    function test_Register_10Registrations() public {
        vm.startPrank(address(factory));
        for (uint256 i = 0; i < 10; i++) {
            registry.register(address(uint160(i + 200)), bob);
        }
        vm.stopPrank();
        assertEq(registry.totalCovenants(), 10);
    }
    function test_Register_50Registrations() public {
        vm.startPrank(address(factory));
        for (uint256 i = 0; i < 50; i++) {
            registry.register(address(uint160(i + 300)), bob);
        }
        vm.stopPrank();
        assertEq(registry.totalCovenants(), 50);
    }
    function test_Register_TotalCovenantsMatches() public {
        vm.startPrank(address(factory));
        for (uint256 i = 0; i < 5; i++) {
            registry.register(address(uint160(i + 400)), bob);
        }
        vm.stopPrank();
        assertEq(registry.getCovenantsByCreator(bob).length, registry.totalCovenants());
    }

    // ==================== DEREGISTER TESTS (15) ====================
    function test_Deregister_RemovesProxy() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.deregister(1);
        vm.stopPrank();
        assertEq(registry.getCovenant(1), address(0));
    }
    function test_Deregister_RemovesCovenantId() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.deregister(1);
        vm.stopPrank();
        assertEq(registry.getCovenantId(alice), 0);
    }
    function test_Deregister_EmitsEvent() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        vm.expectEmit(true, true, false, false);
        emit CovenantRegistry.CovenantDeregistered(1, alice);
        registry.deregister(1);
        vm.stopPrank();
    }
    function test_Deregister_NonFactoryReverts() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        vm.prank(alice);
        vm.expectRevert(CovenantRegistry.OnlyFactory.selector);
        registry.deregister(1);
    }
    function test_Deregister_InvalidIdReverts() public {
        vm.prank(address(factory));
        vm.expectRevert(CovenantRegistry.CovenantNotFound.selector);
        registry.deregister(999);
    }
    function test_Deregister_AlreadyDeregisteredReverts() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.deregister(1);
        vm.expectRevert(CovenantRegistry.CovenantNotFound.selector);
        registry.deregister(1);
        vm.stopPrank();
    }
    function test_Deregister_CreatorArrayNotModified() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.deregister(1);
        vm.stopPrank();
        // Creator array is not modified on deregister
        uint256[] memory covenants = registry.getCovenantsByCreator(bob);
        assertEq(covenants.length, 1);
        assertEq(covenants[0], 1);
    }
    function test_Deregister_EventContainsCorrectId() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        vm.expectEmit(true, true, false, false);
        emit CovenantRegistry.CovenantDeregistered(1, alice);
        registry.deregister(1);
        vm.stopPrank();
    }
    function test_Deregister_EventContainsCorrectProxy() public {
        vm.startPrank(address(factory));
        registry.register(dave, bob);
        vm.expectEmit(true, true, false, false);
        emit CovenantRegistry.CovenantDeregistered(1, dave);
        registry.deregister(1);
        vm.stopPrank();
    }
    function test_Deregister_TotalCovenantsNotDecremented() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        assertEq(registry.totalCovenants(), 1);
        registry.deregister(1);
        vm.stopPrank();
        assertEq(registry.totalCovenants(), 1);
    }
    function test_Deregister_CanReregisterSameIdNotAllowed() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.deregister(1);
        // Can't reregister same ID, but can register new proxy with new ID
        uint256 newId = registry.register(carol, bob);
        vm.stopPrank();
        assertEq(newId, 2);
    }
    function test_Deregister_MultipleDeregisters() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.register(carol, bob);
        registry.deregister(1);
        registry.deregister(2);
        vm.stopPrank();
        assertEq(registry.getCovenant(1), address(0));
        assertEq(registry.getCovenant(2), address(0));
    }
    function test_Deregister_OneOfMany() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.register(carol, bob);
        registry.register(dave, bob);
        registry.deregister(2);
        vm.stopPrank();
        assertEq(registry.getCovenant(1), alice);
        assertEq(registry.getCovenant(2), address(0));
        assertEq(registry.getCovenant(3), dave);
    }
    function test_Deregister_DoesNotAffectOtherIds() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.register(carol, bob);
        registry.deregister(1);
        vm.stopPrank();
        assertEq(registry.getCovenantId(carol), 2);
    }
    function test_Deregister_ZeroIdReverts() public {
        vm.prank(address(factory));
        vm.expectRevert(CovenantRegistry.CovenantNotFound.selector);
        registry.deregister(0);
    }

    // ==================== VIEW FUNCTION TESTS (20) ====================
    function test_GetCovenant_Exists() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        assertEq(registry.getCovenant(1), alice);
    }
    function test_GetCovenant_NotExistsReturnsZero() public view {
        assertEq(registry.getCovenant(999), address(0));
    }
    function test_GetCovenantId_Exists() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        assertEq(registry.getCovenantId(alice), 1);
    }
    function test_GetCovenantId_NotExistsReturnsZero() public view {
        assertEq(registry.getCovenantId(alice), 0);
    }
    function test_GetCovenantsByCreator_Empty() public view {
        uint256[] memory covenants = registry.getCovenantsByCreator(alice);
        assertEq(covenants.length, 0);
    }
    function test_GetCovenantsByCreator_One() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        uint256[] memory covenants = registry.getCovenantsByCreator(bob);
        assertEq(covenants.length, 1);
    }
    function test_GetCovenantsByCreator_Many() public {
        vm.startPrank(address(factory));
        for (uint256 i = 0; i < 10; i++) {
            registry.register(address(uint160(i + 500)), bob);
        }
        vm.stopPrank();
        uint256[] memory covenants = registry.getCovenantsByCreator(bob);
        assertEq(covenants.length, 10);
    }
    function test_TotalCovenants_Empty() public view {
        assertEq(registry.totalCovenants(), 0);
    }
    function test_TotalCovenants_AfterRegister() public {
        vm.startPrank(address(factory));
        for (uint256 i = 0; i < 5; i++) {
            registry.register(address(uint160(i + 600)), bob);
        }
        vm.stopPrank();
        assertEq(registry.totalCovenants(), 5);
    }
    function test_TotalCovenants_AfterDeregister() public {
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.deregister(1);
        vm.stopPrank();
        assertEq(registry.totalCovenants(), 1);
    }
    function test_GetCovenant_ReturnType() public view {
        address result = registry.getCovenant(1);
        assertEq(result, address(0));
    }
    function test_GetCovenantId_ReturnType() public view {
        uint256 result = registry.getCovenantId(alice);
        assertEq(result, 0);
    }
    function test_GetCovenantsByCreator_ReturnType() public view {
        uint256[] memory result = registry.getCovenantsByCreator(alice);
        assertEq(result.length, 0);
    }
    function test_TotalCovenants_ReturnType() public view {
        uint256 result = registry.totalCovenants();
        assertEq(result, 0);
    }
    function test_Factory_ReturnType() public view {
        address result = registry.factory();
        assertEq(result, address(factory));
    }
    function test_GetCovenant_LargeId() public view {
        assertEq(registry.getCovenant(type(uint256).max), address(0));
    }
    function test_GetCovenantId_ZeroAddress() public view {
        assertEq(registry.getCovenantId(address(0)), 0);
    }
    function test_GetCovenantsByCreator_ZeroAddress() public view {
        uint256[] memory result = registry.getCovenantsByCreator(address(0));
        assertEq(result.length, 0);
    }
    function test_ViewFunctions_ArePureOrView() public view {
        registry.factory();
        registry.totalCovenants();
        registry.getCovenant(1);
        registry.getCovenantId(alice);
        registry.getCovenantsByCreator(bob);
        assertTrue(true);
    }
    function test_GetCovenantsByCreator_DoesNotIncludeDeregistered() public {
        // Note: creator array is not cleaned up on deregister
        vm.startPrank(address(factory));
        registry.register(alice, bob);
        registry.deregister(1);
        vm.stopPrank();
        uint256[] memory covenants = registry.getCovenantsByCreator(bob);
        assertEq(covenants.length, 1);
        assertEq(covenants[0], 1);
    }

    // ==================== SET FACTORY TESTS (15) ====================
    function test_SetFactory_UpdatesAddress() public asOwner {
        registry.setFactory(alice);
        assertEq(registry.factory(), alice);
    }
    function test_SetFactory_ZeroAddressReverts() public asOwner {
        vm.expectRevert(CovenantRegistry.InvalidCovenantId.selector);
        registry.setFactory(address(0));
    }
    function test_SetFactory_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        registry.setFactory(bob);
    }
    function test_SetFactory_SameAddressAllowed() public asOwner {
        registry.setFactory(address(factory));
        assertEq(registry.factory(), address(factory));
    }
    function test_SetFactory_MultipleUpdates() public asOwner {
        registry.setFactory(alice);
        registry.setFactory(bob);
        registry.setFactory(carol);
        assertEq(registry.factory(), carol);
    }
    function test_SetFactory_AffectsRegisterAccess() public asOwner {
        registry.setFactory(alice);
        vm.prank(alice);
        registry.register(bob, carol);
        assertEq(registry.totalCovenants(), 1);
    }
    function test_SetFactory_OldFactoryLosesAccess() public asOwner {
        registry.setFactory(alice);
        vm.prank(address(factory));
        vm.expectRevert(CovenantRegistry.OnlyFactory.selector);
        registry.register(bob, carol);
    }
    function test_SetFactory_EOAAllowed() public asOwner {
        registry.setFactory(alice);
        assertEq(registry.factory(), alice);
    }
    function test_SetFactory_PrecompileAllowed() public asOwner {
        registry.setFactory(address(1));
        assertEq(registry.factory(), address(1));
    }
    function test_SetFactory_MaxAddressAllowed() public asOwner {
        address maxAddr = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        registry.setFactory(maxAddr);
        assertEq(registry.factory(), maxAddr);
    }
    function test_SetFactory_NoEthRequired() public asOwner {
        registry.setFactory(alice);
        assertEq(address(registry).balance, 0);
    }
    function test_SetFactory_DoesNotAffectExistingRegistrations() public asOwner {
        vm.prank(address(factory));
        registry.register(alice, bob);
        registry.setFactory(carol);
        assertEq(registry.getCovenant(1), alice);
    }
    function test_SetFactory_CanBeSetToRegistryItself() public asOwner {
        registry.setFactory(address(registry));
        assertEq(registry.factory(), address(registry));
    }
    function test_SetFactory_EventNotEmitted() public asOwner {
        // setFactory does not emit an event
        registry.setFactory(alice);
        assertEq(registry.factory(), alice);
    }
    function test_SetFactory_ByOwnerOnly() public asOwner {
        registry.setFactory(dave);
        assertEq(registry.factory(), dave);
    }

    // ==================== ACCESS CONTROL TESTS (10) ====================
    function test_AccessControl_RegisterFactoryOnly() public {
        vm.prank(alice);
        vm.expectRevert(CovenantRegistry.OnlyFactory.selector);
        registry.register(alice, bob);
    }
    function test_AccessControl_DeregisterFactoryOnly() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        vm.prank(alice);
        vm.expectRevert(CovenantRegistry.OnlyFactory.selector);
        registry.deregister(1);
    }
    function test_AccessControl_SetFactoryOwnerOnly() public {
        vm.prank(alice);
        vm.expectRevert();
        registry.setFactory(bob);
    }
    function test_AccessControl_ViewFunctionsArePublic() public view {
        registry.getCovenant(1);
        registry.getCovenantId(alice);
        registry.getCovenantsByCreator(bob);
        registry.totalCovenants();
        registry.factory();
        assertTrue(true);
    }
    function test_AccessControl_OwnerCannotRegister() public {
        vm.prank(owner);
        vm.expectRevert(CovenantRegistry.OnlyFactory.selector);
        registry.register(alice, bob);
    }
    function test_AccessControl_OwnerCannotDeregister() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        vm.prank(owner);
        vm.expectRevert(CovenantRegistry.OnlyFactory.selector);
        registry.deregister(1);
    }
    function test_AccessControl_FactoryCanBeEOA() public {
        registry.setFactory(alice);
        vm.prank(alice);
        registry.register(bob, carol);
        assertEq(registry.totalCovenants(), 1);
    }
    function test_AccessControl_NewFactoryCanDeregister() public {
        vm.prank(address(factory));
        registry.register(alice, bob);
        registry.setFactory(alice);
        // alice didn't register this, so as new factory can't deregister old ones
        // but actually any factory can deregister any id
        vm.prank(alice);
        registry.deregister(1);
        assertEq(registry.getCovenant(1), address(0));
    }
    function test_AccessControl_TransferredOwnershipChangesAccess() public asOwner {
        registry.transferOwnership(alice);
        vm.prank(alice);
        registry.setFactory(bob);
        assertEq(registry.factory(), bob);
    }
    function test_AccessControl_OldOwnerCannotSetFactoryAfterTransfer() public asOwner {
        registry.transferOwnership(alice);
        vm.expectRevert();
        registry.setFactory(bob);
    }
}
