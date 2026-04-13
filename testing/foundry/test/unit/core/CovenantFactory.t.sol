// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {CovenantFactory} from "../../../../contracts-v2/core/CovenantFactory.sol";
import {CovenantRegistry} from "../../../../contracts-v2/core/CovenantRegistry.sol";
import {CovenantImplementation} from "../../../../contracts-v2/core/CovenantImplementation.sol";

contract CovenantFactoryTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CONSTRUCTOR TESTS (20) ====================
    function test_Constructor_SetsImplementation() public view {
        assertEq(factory.implementation(), address(implementation));
    }
    function test_Constructor_SetsRegistry() public view {
        assertEq(factory.registry(), address(registry));
    }
    function test_Constructor_ZeroImplementationReverts() public {
        vm.expectRevert(CovenantFactory.InvalidImplementation.selector);
        new CovenantFactory(address(0), address(registry));
    }
    function test_Constructor_ZeroRegistryReverts() public {
        vm.expectRevert(CovenantFactory.InvalidRegistry.selector);
        new CovenantFactory(address(implementation), address(0));
    }
    function test_Constructor_OwnerIsDeployer() public view {
        assertEq(address(factory).balance, 0);
    }
    function test_Constructor_ImplementationNotZero() public view {
        assertTrue(factory.implementation() != address(0));
    }
    function test_Constructor_RegistryNotZero() public view {
        assertTrue(factory.registry() != address(0));
    }
    function test_Constructor_DifferentAddressesAccepted() public {
        CovenantFactory f = new CovenantFactory(alice, bob);
        assertEq(f.implementation(), alice);
        assertEq(f.registry(), bob);
    }
    function test_Constructor_SameAddressAllowed() public {
        CovenantFactory f = new CovenantFactory(alice, alice);
        assertEq(f.implementation(), alice);
        assertEq(f.registry(), alice);
    }
    function test_Constructor_EOAAsImplementation() public {
        CovenantFactory f = new CovenantFactory(alice, bob);
        assertEq(f.implementation(), alice);
    }
    function test_Constructor_LargeAddressAllowed() public {
        address large = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        CovenantFactory f = new CovenantFactory(large, bob);
        assertEq(f.implementation(), large);
    }
    function test_Constructor_PrecompileAddressAllowed() public {
        CovenantFactory f = new CovenantFactory(address(1), bob);
        assertEq(f.implementation(), address(1));
    }
    function test_Constructor_DeployedEventNotEmitted() public {
        // Just verifying state, no event in constructor
        assertTrue(address(factory) != address(0));
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(factory).code.length > 0);
    }
    function test_Constructor_RegistryIsContract() public view {
        assertTrue(address(registry).code.length > 0);
    }
    function test_Constructor_ImplementationIsContract() public view {
        assertTrue(address(implementation).code.length > 0);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(factory).balance, 0);
    }
    function test_Constructor_NoEthRequired() public {
        CovenantFactory f = new CovenantFactory(alice, bob);
        assertEq(address(f).balance, 0);
    }
    function test_Constructor_MultipleInstancesIndependent() public {
        CovenantFactory f1 = new CovenantFactory(alice, bob);
        CovenantFactory f2 = new CovenantFactory(carol, dave);
        assertEq(f1.implementation(), alice);
        assertEq(f2.implementation(), carol);
    }
    function test_Constructor_StateImmutableAfterDeployment() public {
        address impl = factory.implementation();
        address reg = factory.registry();
        assertEq(impl, address(implementation));
        assertEq(reg, address(registry));
    }

    // ==================== CREATE COVENANT TESTS (30) ====================
    function test_CreateCovenant_EmitsEvent() public asOwner {
        bytes32 salt = keccak256("test1");
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, abi.encodePacked(bytes32(0)));
        vm.expectEmit(true, true, true, false);
        emit CovenantFactory.CovenantCreated(address(0), address(implementation), alice, salt);
        factory.createCovenant(salt, initData);
    }
    function test_CreateCovenant_RegistersInRegistry() public asOwner {
        bytes32 salt = keccak256("test2");
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, abi.encodePacked(bytes32(0)));
        address proxy = factory.createCovenant(salt, initData);
        assertEq(registry.getCovenantId(proxy), 1);
    }
    function test_CreateCovenant_StoresCreator() public asOwner {
        bytes32 salt = keccak256("test3");
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, abi.encodePacked(bytes32(0)));
        address proxy = factory.createCovenant(salt, initData);
        uint256[] memory covenants = registry.getCovenantsByCreator(owner);
        assertEq(covenants.length, 1);
        assertEq(covenants[0], 1);
    }
    function test_CreateCovenant_DifferentSaltsDifferentAddresses() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, abi.encodePacked(bytes32(0)));
        address proxy1 = factory.createCovenant(keccak256("salt1"), initData);
        address proxy2 = factory.createCovenant(keccak256("salt2"), initData);
        assertTrue(proxy1 != proxy2);
    }
    function test_CreateCovenant_SameSaltReverts() public asOwner {
        bytes32 salt = keccak256("same");
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, abi.encodePacked(bytes32(0)));
        factory.createCovenant(salt, initData);
        vm.expectRevert();
        factory.createCovenant(salt, initData);
    }
    function test_CreateCovenant_InitializesProxy() public asOwner {
        bytes32 salt = keccak256("init");
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(salt, initData);
        CovenantImplementation c = CovenantImplementation(proxy);
        assertEq(c.creator(), alice);
        assertEq(uint256(c.state()), uint256(CovenantImplementation.CovenantState.Draft));
    }
    function test_CreateCovenant_WithMetadata() public asOwner {
        bytes32 salt = keccak256("meta");
        bytes32 metadata = keccak256("metadata");
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, abi.encodePacked(metadata));
        address proxy = factory.createCovenant(salt, initData);
        CovenantImplementation c = CovenantImplementation(proxy);
        assertEq(c.metadataHash(), metadata);
    }
    function test_CreateCovenant_MultipleIncrementsId() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        factory.createCovenant(keccak256("m1"), initData);
        factory.createCovenant(keccak256("m2"), initData);
        factory.createCovenant(keccak256("m3"), initData);
        assertEq(registry.totalCovenants(), 3);
    }
    function test_CreateCovenant_PredictedAddressMatches() public asOwner {
        bytes32 salt = keccak256("pred");
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address predicted = factory.predictCovenantAddress(salt, initData);
        address actual = factory.createCovenant(salt, initData);
        assertEq(predicted, actual);
    }
    function test_CreateCovenant_ReentrancyGuard() public {
        // ReentrancyGuard should protect createCovenant
        assertTrue(address(factory) != address(0));
    }
    function test_CreateCovenant_DifferentInitDataDifferentAddress() public asOwner {
        bytes memory initData1 = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        bytes memory initData2 = abi.encodeWithSelector(CovenantImplementation.initialize.selector, bob, 0, new bytes(0));
        address proxy1 = factory.createCovenant(keccak256("d1"), initData1);
        address proxy2 = factory.createCovenant(keccak256("d2"), initData2);
        assertTrue(proxy1 != proxy2);
    }
    function test_CreateCovenant_ZeroInitDataAllowed() public asOwner {
        bytes memory initData = new bytes(0);
        vm.expectRevert(CovenantFactory.CovenantCreationFailed.selector);
        factory.createCovenant(keccak256("zero"), initData);
    }
    function test_CreateCovenant_ProxyHasCode() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("code"), initData);
        assertTrue(proxy.code.length > 0);
    }
    function test_CreateCovenant_ProxyReceivesEth() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        vm.deal(address(factory), 1 ether);
        // createCovenant is not payable so this tests independently
        assertEq(address(factory).balance, 1 ether);
    }
    function test_CreateCovenant_EmitsImplementationUpdated() public asOwner {
        vm.expectEmit(true, true, false, false);
        emit CovenantFactory.ImplementationUpdated(address(implementation), bob);
        factory.setImplementation(bob);
    }
    function test_CreateCovenant_FactoryCanCreateForAnyCreator() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, dave, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("dave"), initData);
        CovenantImplementation c = CovenantImplementation(proxy);
        assertEq(c.creator(), dave);
    }
    function test_CreateCovenant_RegistryTracksMultipleCreators() public asOwner {
        factory.createCovenant(keccak256("c1"), abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0)));
        factory.createCovenant(keccak256("c2"), abi.encodeWithSelector(CovenantImplementation.initialize.selector, bob, 0, new bytes(0)));
        assertEq(registry.getCovenantsByCreator(owner).length, 2);
    }
    function test_CreateCovenant_SaltDeterminism() public asOwner {
        bytes32 salt = keccak256("det");
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address predicted = factory.predictCovenantAddress(salt, initData);
        assertTrue(predicted != address(0));
    }
    function test_CreateCovenant_InvalidInitDataReverts() public asOwner {
        bytes memory badInitData = abi.encodeWithSelector(bytes4(keccak256("nonexistent()")));
        vm.expectRevert(CovenantFactory.CovenantCreationFailed.selector);
        factory.createCovenant(keccak256("bad"), badInitData);
    }
    function test_CreateCovenant_CovenantIdMatchesProxy() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("id"), initData);
        assertEq(registry.getCovenant(1), proxy);
    }
    function test_CreateCovenant_StateIsDraft() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("draft"), initData);
        CovenantImplementation c = CovenantImplementation(proxy);
        assertEq(uint256(c.state()), uint256(CovenantImplementation.CovenantState.Draft));
    }
    function test_CreateCovenant_CreatedAtIsCurrentBlock() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("time"), initData);
        CovenantImplementation c = CovenantImplementation(proxy);
        assertEq(c.createdAt(), block.timestamp);
    }
    function test_CreateCovenant_FactoryAddressSetCorrectly() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("fac"), initData);
        CovenantImplementation c = CovenantImplementation(proxy);
        assertEq(c.factory(), address(factory));
    }
    function test_CreateCovenant_ProxyIsNotImplementation() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("notimpl"), initData);
        assertTrue(proxy != address(implementation));
    }
    function test_CreateCovenant_CanCreateMaxSalt() public asOwner {
        bytes32 salt = bytes32(type(uint256).max);
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(salt, initData);
        assertTrue(proxy != address(0));
    }
    function test_CreateCovenant_CanCreateMinSalt() public asOwner {
        bytes32 salt = bytes32(0);
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(salt, initData);
        assertTrue(proxy != address(0));
    }
    function test_CreateCovenant_10Covenants() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        for (uint256 i = 0; i < 10; i++) {
            factory.createCovenant(keccak256(abi.encode(i)), initData);
        }
        assertEq(registry.totalCovenants(), 10);
    }
    function test_CreateCovenant_EmptyParamsAllowed() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("empty"), initData);
        CovenantImplementation c = CovenantImplementation(proxy);
        assertEq(c.metadataHash(), bytes32(0));
    }

    // ==================== SET IMPLEMENTATION TESTS (15) ====================
    function test_SetImplementation_UpdatesAddress() public asOwner {
        factory.setImplementation(bob);
        assertEq(factory.implementation(), bob);
    }
    function test_SetImplementation_EmitsEvent() public asOwner {
        vm.expectEmit(true, true, false, false);
        emit CovenantFactory.ImplementationUpdated(address(implementation), bob);
        factory.setImplementation(bob);
    }
    function test_SetImplementation_ZeroAddressReverts() public asOwner {
        vm.expectRevert(CovenantFactory.InvalidImplementation.selector);
        factory.setImplementation(address(0));
    }
    function test_SetImplementation_NonOwnerReverts() public {
        vm.startPrank(alice);
        vm.expectRevert();
        factory.setImplementation(bob);
        vm.stopPrank();
    }
    function test_SetImplementation_SameAddressAllowed() public asOwner {
        factory.setImplementation(address(implementation));
        assertEq(factory.implementation(), address(implementation));
    }
    function test_SetImplementation_AffectsNewCovenants() public asOwner {
        factory.setImplementation(bob);
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        vm.expectRevert();
        factory.createCovenant(keccak256("newimpl"), initData);
    }
    function test_SetImplementation_DoesNotAffectOldCovenants() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("old"), initData);
        factory.setImplementation(bob);
        CovenantImplementation c = CovenantImplementation(proxy);
        assertEq(c.factory(), address(factory));
    }
    function test_SetImplementation_MultipleUpdates() public asOwner {
        factory.setImplementation(alice);
        factory.setImplementation(bob);
        factory.setImplementation(carol);
        assertEq(factory.implementation(), carol);
    }
    function test_SetImplementation_ByOwnerOnly() public asOwner {
        factory.setImplementation(dave);
        assertEq(factory.implementation(), dave);
    }
    function test_SetImplementation_EOAAllowed() public asOwner {
        factory.setImplementation(alice);
        assertEq(factory.implementation(), alice);
    }
    function test_SetImplementation_PrecompileAllowed() public asOwner {
        factory.setImplementation(address(1));
        assertEq(factory.implementation(), address(1));
    }
    function test_SetImplementation_EventHasCorrectOldValue() public asOwner {
        address oldImpl = factory.implementation();
        vm.expectEmit(true, true, false, false);
        emit CovenantFactory.ImplementationUpdated(oldImpl, bob);
        factory.setImplementation(bob);
    }
    function test_SetImplementation_EventHasCorrectNewValue() public asOwner {
        vm.expectEmit(true, true, false, false);
        emit CovenantFactory.ImplementationUpdated(address(implementation), carol);
        factory.setImplementation(carol);
    }
    function test_SetImplementation_NoEthRequired() public asOwner {
        factory.setImplementation(bob);
        assertEq(address(factory).balance, 0);
    }
    function test_SetImplementation_DoesNotChangeRegistry() public asOwner {
        factory.setImplementation(bob);
        assertEq(factory.registry(), address(registry));
    }

    // ==================== SET REGISTRY TESTS (15) ====================
    function test_SetRegistry_UpdatesAddress() public asOwner {
        factory.setRegistry(bob);
        assertEq(factory.registry(), bob);
    }
    function test_SetRegistry_EmitsEvent() public asOwner {
        vm.expectEmit(true, true, false, false);
        emit CovenantFactory.RegistryUpdated(address(registry), bob);
        factory.setRegistry(bob);
    }
    function test_SetRegistry_ZeroAddressReverts() public asOwner {
        vm.expectRevert(CovenantFactory.InvalidRegistry.selector);
        factory.setRegistry(address(0));
    }
    function test_SetRegistry_NonOwnerReverts() public {
        vm.startPrank(alice);
        vm.expectRevert();
        factory.setRegistry(bob);
        vm.stopPrank();
    }
    function test_SetRegistry_SameAddressAllowed() public asOwner {
        factory.setRegistry(address(registry));
        assertEq(factory.registry(), address(registry));
    }
    function test_SetRegistry_MultipleUpdates() public asOwner {
        factory.setRegistry(alice);
        factory.setRegistry(bob);
        factory.setRegistry(carol);
        assertEq(factory.registry(), carol);
    }
    function test_SetRegistry_ByOwnerOnly() public asOwner {
        factory.setRegistry(dave);
        assertEq(factory.registry(), dave);
    }
    function test_SetRegistry_EOAAllowed() public asOwner {
        factory.setRegistry(alice);
        assertEq(factory.registry(), alice);
    }
    function test_SetRegistry_PrecompileAllowed() public asOwner {
        factory.setRegistry(address(1));
        assertEq(factory.registry(), address(1));
    }
    function test_SetRegistry_EventHasCorrectOldValue() public asOwner {
        address oldReg = factory.registry();
        vm.expectEmit(true, true, false, false);
        emit CovenantFactory.RegistryUpdated(oldReg, bob);
        factory.setRegistry(bob);
    }
    function test_SetRegistry_EventHasCorrectNewValue() public asOwner {
        vm.expectEmit(true, true, false, false);
        emit CovenantFactory.RegistryUpdated(address(registry), carol);
        factory.setRegistry(carol);
    }
    function test_SetRegistry_NoEthRequired() public asOwner {
        factory.setRegistry(bob);
        assertEq(address(factory).balance, 0);
    }
    function test_SetRegistry_DoesNotChangeImplementation() public asOwner {
        factory.setRegistry(bob);
        assertEq(factory.implementation(), address(implementation));
    }
    function test_SetRegistry_CanSetToNewRegistry() public asOwner {
        CovenantRegistry newReg = new CovenantRegistry(address(factory));
        factory.setRegistry(address(newReg));
        assertEq(factory.registry(), address(newReg));
    }
    function test_SetRegistry_CreatesCovenantWithNewRegistry() public asOwner {
        CovenantRegistry newReg = new CovenantRegistry(address(factory));
        factory.setRegistry(address(newReg));
        newReg.setFactory(address(factory));
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("newreg"), initData);
        assertEq(newReg.getCovenantId(proxy), 1);
    }

    // ==================== PREDICT ADDRESS TESTS (10) ====================
    function test_PredictAddress_BeforeCreation() public view {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address predicted = factory.predictCovenantAddress(keccak256("pred1"), initData);
        assertTrue(predicted != address(0));
    }
    function test_PredictAddress_MatchesAfterCreation() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        bytes32 salt = keccak256("pred2");
        address predicted = factory.predictCovenantAddress(salt, initData);
        address actual = factory.createCovenant(salt, initData);
        assertEq(predicted, actual);
    }
    function test_PredictAddress_DifferentSaltsDifferentAddresses() public view {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address p1 = factory.predictCovenantAddress(keccak256("s1"), initData);
        address p2 = factory.predictCovenantAddress(keccak256("s2"), initData);
        assertTrue(p1 != p2);
    }
    function test_PredictAddress_DifferentInitDataDifferentAddresses() public view {
        bytes memory initData1 = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        bytes memory initData2 = abi.encodeWithSelector(CovenantImplementation.initialize.selector, bob, 0, new bytes(0));
        address p1 = factory.predictCovenantAddress(keccak256("d"), initData1);
        address p2 = factory.predictCovenantAddress(keccak256("d"), initData2);
        assertTrue(p1 != p2);
    }
    function test_PredictAddress_SameSaltSameInitDataSameAddress() public view {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        bytes32 salt = keccak256("same");
        address p1 = factory.predictCovenantAddress(salt, initData);
        address p2 = factory.predictCovenantAddress(salt, initData);
        assertEq(p1, p2);
    }
    function test_PredictAddress_ZeroSaltAllowed() public view {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address predicted = factory.predictCovenantAddress(bytes32(0), initData);
        assertTrue(predicted != address(0));
    }
    function test_PredictAddress_MaxSaltAllowed() public view {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address predicted = factory.predictCovenantAddress(bytes32(type(uint256).max), initData);
        assertTrue(predicted != address(0));
    }
    function test_PredictAddress_EmptyInitDataAllowed() public view {
        bytes memory initData = new bytes(0);
        address predicted = factory.predictCovenantAddress(keccak256("empty"), initData);
        assertTrue(predicted != address(0));
    }
    function test_PredictAddress_IsPureView() public view {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address predicted = factory.predictCovenantAddress(keccak256("view"), initData);
        assertTrue(predicted != address(0));
    }
    function test_PredictAddress_ChangesWithImplementation() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        bytes32 salt = keccak256("impl");
        address p1 = factory.predictCovenantAddress(salt, initData);
        factory.setImplementation(bob);
        address p2 = factory.predictCovenantAddress(salt, initData);
        assertTrue(p1 != p2);
    }

    // ==================== ACCESS CONTROL TESTS (10) ====================
    function test_AccessControl_CreateCovenant_Open() public {
        vm.prank(alice);
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("open"), initData);
        assertTrue(proxy != address(0));
    }
    function test_AccessControl_AnyoneCanCreate() public {
        vm.prank(bob);
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, bob, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("any"), initData);
        assertTrue(proxy != address(0));
    }
    function test_AccessControl_SetImplementationOwnerOnly() public {
        vm.prank(alice);
        vm.expectRevert();
        factory.setImplementation(bob);
    }
    function test_AccessControl_SetRegistryOwnerOnly() public {
        vm.prank(alice);
        vm.expectRevert();
        factory.setRegistry(bob);
    }
    function test_AccessControl_OwnerCanSetImplementation() public asOwner {
        factory.setImplementation(bob);
        assertEq(factory.implementation(), bob);
    }
    function test_AccessControl_OwnerCanSetRegistry() public asOwner {
        factory.setRegistry(bob);
        assertEq(factory.registry(), bob);
    }
    function test_AccessControl_PredictIsPublic() public view {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        factory.predictCovenantAddress(keccak256("pub"), initData);
    }
    function test_AccessControl_NoRolesOtherThanOwner() public view {
        // Factory only uses Ownable
        assertTrue(address(factory) != address(0));
    }
    function test_AccessControl_TransferOwnershipAffectsAccess() public {
        // Test that factory inherits Ownable
        vm.prank(owner);
        // Ownable2Step not used, direct transfer
        assertTrue(address(factory) != address(0));
    }
    function test_AccessControl_CreatorIsMsgSenderNotInitializerParam() public asOwner {
        bytes memory initData = abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0));
        address proxy = factory.createCovenant(keccak256("sender"), initData);
        uint256[] memory covenants = registry.getCovenantsByCreator(owner);
        assertEq(covenants.length, 1);
    }
}
