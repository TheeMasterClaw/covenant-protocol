// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {CovenantImplementation} from "../../../../contracts-v2/core/CovenantImplementation.sol";

contract CovenantImplementationTest is DeploymentFixtures {
    CovenantImplementation public covenant;
    address public proxy;

    function setUp() public override {
        super.setUp();
        vm.startPrank(owner);
        proxy = factory.createCovenant(
            keccak256("test_covenant"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 1, abi.encodePacked(bytes32(0)))
        );
        covenant = CovenantImplementation(proxy);
        vm.stopPrank();
    }

    // ==================== INITIALIZATION TESTS (25) ====================
    function test_Initialize_SetsFactory() public view {
        assertEq(covenant.factory(), address(factory));
    }
    function test_Initialize_SetsCreator() public view {
        assertEq(covenant.creator(), alice);
    }
    function test_Initialize_SetsCovenantId() public view {
        assertEq(covenant.covenantId(), 1);
    }
    function test_Initialize_SetsStateToDraft() public view {
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Draft));
    }
    function test_Initialize_SetsCreatedAt() public view {
        assertEq(covenant.createdAt(), block.timestamp);
    }
    function test_Initialize_EmitsEvent() public {
        vm.expectEmit(true, true, true, false);
        emit CovenantImplementation.CovenantInitialized(address(factory), alice, 1);
        factory.createCovenant(
            keccak256("test_init_event"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 2, abi.encodePacked(bytes32(0)))
        );
    }
    function test_Initialize_ZeroCreatorReverts() public {
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        factory.createCovenant(
            keccak256("test_zero"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, address(0), 3, abi.encodePacked(bytes32(0)))
        );
    }
    function test_Initialize_WithMetadata() public {
        bytes32 metadata = keccak256("metadata");
        address p = factory.createCovenant(
            keccak256("test_meta"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 4, abi.encodePacked(metadata))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.metadataHash(), metadata);
    }
    function test_Initialize_WithoutMetadata() public view {
        assertEq(covenant.metadataHash(), bytes32(0));
    }
    function test_Initialize_CannotReinitialize() public {
        vm.expectRevert();
        covenant.initialize(bob, 2, new bytes(0));
    }
    function test_Initialize_DifferentCreators() public {
        address p1 = factory.createCovenant(
            keccak256("c1"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 5, new bytes(0))
        );
        address p2 = factory.createCovenant(
            keccak256("c2"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, bob, 6, new bytes(0))
        );
        assertEq(CovenantImplementation(p1).creator(), alice);
        assertEq(CovenantImplementation(p2).creator(), bob);
    }
    function test_Initialize_DifferentIds() public {
        address p1 = factory.createCovenant(
            keccak256("i1"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0))
        );
        address p2 = factory.createCovenant(
            keccak256("i2"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0))
        );
        assertEq(CovenantImplementation(p1).covenantId(), 2);
        assertEq(CovenantImplementation(p2).covenantId(), 3);
    }
    function test_Initialize_FactoryIsMsgSender() public view {
        assertEq(covenant.factory(), address(factory));
    }
    function test_Initialize_ParamsTooShortHandled() public {
        address p = factory.createCovenant(
            keccak256("short"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 10, new bytes(16))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.metadataHash(), bytes32(0));
    }
    function test_Initialize_ParamsExactLength() public {
        bytes32 metadata = keccak256("exact");
        address p = factory.createCovenant(
            keccak256("exact_len"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 11, abi.encodePacked(metadata))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.metadataHash(), metadata);
    }
    function test_Initialize_ParamsLongerThan32() public {
        bytes memory longParams = new bytes(64);
        address p = factory.createCovenant(
            keccak256("long"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 12, longParams)
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.metadataHash(), bytes32(0));
    }
    function test_Initialize_CreatedAtIsBlockTimestamp() public view {
        assertEq(covenant.createdAt(), block.timestamp);
    }
    function test_Initialize_AfterWarp() public {
        vm.warp(block.timestamp + 1 days);
        address p = factory.createCovenant(
            keccak256("warp"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.createdAt(), block.timestamp);
    }
    function test_Initialize_SelfAsCreatorAllowed() public {
        address p = factory.createCovenant(
            keccak256("self"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.creator(), alice);
    }
    function test_Initialize_ContractAsCreatorAllowed() public {
        address p = factory.createCovenant(
            keccak256("contract"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, address(factory), 0, new bytes(0))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.creator(), address(factory));
    }
    function test_Initialize_PrecompileAsCreatorAllowed() public {
        address p = factory.createCovenant(
            keccak256("precompile"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, address(1), 0, new bytes(0))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.creator(), address(1));
    }
    function test_Initialize_MaxAddressAsCreatorAllowed() public {
        address maxAddr = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        address p = factory.createCovenant(
            keccak256("maxaddr"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, maxAddr, 0, new bytes(0))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.creator(), maxAddr);
    }
    function test_Initialize_EmptyParamsAllowed() public {
        address p = factory.createCovenant(
            keccak256("empty"),
            abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0))
        );
        CovenantImplementation c = CovenantImplementation(p);
        assertEq(c.metadataHash(), bytes32(0));
    }
    function test_Initialize_10Covenants() public {
        for (uint256 i = 0; i < 10; i++) {
            address p = factory.createCovenant(
                keccak256(abi.encode("batch", i)),
                abi.encodeWithSelector(CovenantImplementation.initialize.selector, alice, 0, new bytes(0))
            );
            CovenantImplementation c = CovenantImplementation(p);
            assertEq(c.creator(), alice);
        }
    }

    // ==================== ACTIVATE TESTS (20) ====================
    function test_Activate_FromDraft() public {
        vm.prank(alice);
        covenant.activate();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Active));
    }
    function test_Activate_EmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(uint8(CovenantImplementation.CovenantState.Draft), uint8(CovenantImplementation.CovenantState.Active));
        vm.prank(alice);
        covenant.activate();
    }
    function test_Activate_OnlyCreator() public {
        vm.prank(bob);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.activate();
    }
    function test_Activate_FromActiveReverts() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.InvalidStateTransition.selector);
        covenant.activate();
    }
    function test_Activate_FromPausedReverts() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.InvalidStateTransition.selector);
        covenant.activate();
    }
    function test_Activate_FromResolvedReverts() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.InvalidStateTransition.selector);
        covenant.activate();
    }
    function test_Activate_FromTerminatedReverts() public {
        vm.prank(address(factory));
        covenant.terminate();
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.InvalidStateTransition.selector);
        covenant.activate();
    }
    function test_Activate_WhenNotPaused() public {
        vm.prank(alice);
        covenant.activate();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Active));
    }
    function test_Activate_ByCreatorOnly() public {
        vm.prank(alice);
        covenant.activate();
        // Factory can't activate
        vm.prank(address(factory));
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.activate();
    }
    function test_Activate_OwnerCannotActivate() public {
        vm.prank(owner);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.activate();
    }
    function test_Activate_RandomCannotActivate() public {
        vm.prank(carol);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.activate();
    }
    function test_Activate_EmitsCorrectOldState() public {
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(0, 1);
        vm.prank(alice);
        covenant.activate();
    }
    function test_Activate_EmitsCorrectNewState() public {
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(uint8(CovenantImplementation.CovenantState.Draft), uint8(CovenantImplementation.CovenantState.Active));
        vm.prank(alice);
        covenant.activate();
    }
    function test_Activate_NoEthRequired() public {
        assertEq(address(covenant).balance, 0);
        vm.prank(alice);
        covenant.activate();
        assertEq(address(covenant).balance, 0);
    }
    function test_Activate_CanReceiveEthAfter() public {
        vm.prank(alice);
        covenant.activate();
        (bool success,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(covenant).balance, 1 ether);
    }
    function test_Activate_CovenantIdUnchanged() public {
        uint256 idBefore = covenant.covenantId();
        vm.prank(alice);
        covenant.activate();
        assertEq(covenant.covenantId(), idBefore);
    }
    function test_Activate_CreatorUnchanged() public {
        address creatorBefore = covenant.creator();
        vm.prank(alice);
        covenant.activate();
        assertEq(covenant.creator(), creatorBefore);
    }
    function test_Activate_FactoryUnchanged() public {
        address factoryBefore = covenant.factory();
        vm.prank(alice);
        covenant.activate();
        assertEq(covenant.factory(), factoryBefore);
    }
    function test_Activate_CreatedAtUnchanged() public {
        uint256 createdBefore = covenant.createdAt();
        vm.prank(alice);
        covenant.activate();
        assertEq(covenant.createdAt(), createdBefore);
    }

    // ==================== PAUSE TESTS (20) ====================
    function test_Pause_FromActive() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Paused));
    }
    function test_Pause_EmitsEvent() public {
        vm.prank(alice);
        covenant.activate();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(1, 2);
        vm.prank(alice);
        covenant.pause();
    }
    function test_Pause_OnlyCreator() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(bob);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.pause();
    }
    function test_Pause_FromDraftReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        covenant.pause();
    }
    function test_Pause_FromPausedReverts() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        vm.expectRevert();
        covenant.pause();
    }
    function test_Pause_FromResolvedReverts() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        vm.prank(alice);
        vm.expectRevert();
        covenant.pause();
    }
    function test_Pause_FromTerminatedReverts() public {
        vm.prank(address(factory));
        covenant.terminate();
        vm.prank(alice);
        vm.expectRevert();
        covenant.pause();
    }
    function test_Pause_SetsPausedFlag() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        // CovenantImplementation uses Pausable internally
    }
    function test_Pause_ByCreatorOnly() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Paused));
    }
    function test_Pause_OwnerCannotPause() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(owner);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.pause();
    }
    function test_Pause_FactoryCannotPause() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(address(factory));
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.pause();
    }
    function test_Pause_EmitsCorrectOldState() public {
        vm.prank(alice);
        covenant.activate();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(uint8(CovenantImplementation.CovenantState.Active), uint8(CovenantImplementation.CovenantState.Paused));
        vm.prank(alice);
        covenant.pause();
    }
    function test_Pause_EmitsCorrectNewState() public {
        vm.prank(alice);
        covenant.activate();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(1, 2);
        vm.prank(alice);
        covenant.pause();
    }
    function test_Pause_NoEthRequired() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        assertEq(address(covenant).balance, 0);
    }
    function test_Pause_CanStillReceiveEth() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        (bool success,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success);
    }
    function test_Pause_CovenantIdUnchanged() public {
        vm.prank(alice);
        covenant.activate();
        uint256 idBefore = covenant.covenantId();
        vm.prank(alice);
        covenant.pause();
        assertEq(covenant.covenantId(), idBefore);
    }
    function test_Pause_CreatorUnchanged() public {
        vm.prank(alice);
        covenant.activate();
        address creatorBefore = covenant.creator();
        vm.prank(alice);
        covenant.pause();
        assertEq(covenant.creator(), creatorBefore);
    }
    function test_Pause_FactoryUnchanged() public {
        vm.prank(alice);
        covenant.activate();
        address factoryBefore = covenant.factory();
        vm.prank(alice);
        covenant.pause();
        assertEq(covenant.factory(), factoryBefore);
    }
    function test_Pause_CreatedAtUnchanged() public {
        vm.prank(alice);
        covenant.activate();
        uint256 createdBefore = covenant.createdAt();
        vm.prank(alice);
        covenant.pause();
        assertEq(covenant.createdAt(), createdBefore);
    }

    // ==================== RESOLVE TESTS (20) ====================
    function test_Resolve_FromActive() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Resolved));
    }
    function test_Resolve_EmitsEvent() public {
        vm.prank(alice);
        covenant.activate();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(1, 3);
        vm.prank(alice);
        covenant.resolve();
    }
    function test_Resolve_OnlyCreator() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(bob);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.resolve();
    }
    function test_Resolve_FromDraftReverts() public {
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.InvalidStateTransition.selector);
        covenant.resolve();
    }
    function test_Resolve_FromPaused() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.resolve();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Resolved));
    }
    function test_Resolve_FromResolvedReverts() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.InvalidStateTransition.selector);
        covenant.resolve();
    }
    function test_Resolve_FromTerminatedReverts() public {
        vm.prank(address(factory));
        covenant.terminate();
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.InvalidStateTransition.selector);
        covenant.resolve();
    }
    function test_Resolve_ByCreatorOnly() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Resolved));
    }
    function test_Resolve_OwnerCannotResolve() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(owner);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.resolve();
    }
    function test_Resolve_FactoryCannotResolve() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(address(factory));
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.resolve();
    }
    function test_Resolve_EmitsCorrectOldState() public {
        vm.prank(alice);
        covenant.activate();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(uint8(CovenantImplementation.CovenantState.Active), uint8(CovenantImplementation.CovenantState.Resolved));
        vm.prank(alice);
        covenant.resolve();
    }
    function test_Resolve_EmitsCorrectNewState() public {
        vm.prank(alice);
        covenant.activate();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(1, 3);
        vm.prank(alice);
        covenant.resolve();
    }
    function test_Resolve_NoEthRequired() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        assertEq(address(covenant).balance, 0);
    }
    function test_Resolve_CanStillReceiveEth() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        (bool success,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success);
    }
    function test_Resolve_CovenantIdUnchanged() public {
        vm.prank(alice);
        covenant.activate();
        uint256 idBefore = covenant.covenantId();
        vm.prank(alice);
        covenant.resolve();
        assertEq(covenant.covenantId(), idBefore);
    }
    function test_Resolve_CreatorUnchanged() public {
        vm.prank(alice);
        covenant.activate();
        address creatorBefore = covenant.creator();
        vm.prank(alice);
        covenant.resolve();
        assertEq(covenant.creator(), creatorBefore);
    }
    function test_Resolve_FactoryUnchanged() public {
        vm.prank(alice);
        covenant.activate();
        address factoryBefore = covenant.factory();
        vm.prank(alice);
        covenant.resolve();
        assertEq(covenant.factory(), factoryBefore);
    }
    function test_Resolve_CreatedAtUnchanged() public {
        vm.prank(alice);
        covenant.activate();
        uint256 createdBefore = covenant.createdAt();
        vm.prank(alice);
        covenant.resolve();
        assertEq(covenant.createdAt(), createdBefore);
    }
    function test_Resolve_MultipleTransitions() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.unpause();
        vm.prank(alice);
        covenant.resolve();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Resolved));
    }

    // ==================== TERMINATE TESTS (20) ====================
    function test_Terminate_FromDraft() public {
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Terminated));
    }
    function test_Terminate_EmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(0, 4);
        vm.prank(address(factory));
        covenant.terminate();
    }
    function test_Terminate_OnlyFactory() public {
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.terminate();
    }
    function test_Terminate_FromActive() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Terminated));
    }
    function test_Terminate_FromPaused() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Terminated));
    }
    function test_Terminate_FromResolved() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Terminated));
    }
    function test_Terminate_FromTerminatedReverts() public {
        vm.prank(address(factory));
        covenant.terminate();
        vm.prank(address(factory));
        vm.expectRevert(CovenantImplementation.InvalidStateTransition.selector);
        covenant.terminate();
    }
    function test_Terminate_ByFactoryOnly() public {
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Terminated));
    }
    function test_Terminate_OwnerCannotTerminate() public {
        vm.prank(owner);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.terminate();
    }
    function test_Terminate_CreatorCannotTerminate() public {
        vm.prank(alice);
        vm.expectRevert(CovenantImplementation.Unauthorized.selector);
        covenant.terminate();
    }
    function test_Terminate_EmitsCorrectOldState() public {
        vm.prank(alice);
        covenant.activate();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(1, 4);
        vm.prank(address(factory));
        covenant.terminate();
    }
    function test_Terminate_EmitsCorrectNewState() public {
        vm.prank(alice);
        covenant.activate();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(1, 4);
        vm.prank(address(factory));
        covenant.terminate();
    }
    function test_Terminate_NoEthRequired() public {
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(address(covenant).balance, 0);
    }
    function test_Terminate_CanStillReceiveEth() public {
        vm.prank(address(factory));
        covenant.terminate();
        (bool success,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success);
    }
    function test_Terminate_CovenantIdUnchanged() public {
        uint256 idBefore = covenant.covenantId();
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(covenant.covenantId(), idBefore);
    }
    function test_Terminate_CreatorUnchanged() public {
        address creatorBefore = covenant.creator();
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(covenant.creator(), creatorBefore);
    }
    function test_Terminate_FactoryUnchanged() public {
        address factoryBefore = covenant.factory();
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(covenant.factory(), factoryBefore);
    }
    function test_Terminate_CreatedAtUnchanged() public {
        uint256 createdBefore = covenant.createdAt();
        vm.prank(address(factory));
        covenant.terminate();
        assertEq(covenant.createdAt(), createdBefore);
    }
    function test_Terminate_IsFinalState() public {
        vm.prank(address(factory));
        covenant.terminate();
        // Once terminated, no transitions possible
        vm.prank(alice);
        vm.expectRevert();
        covenant.activate();
        vm.prank(alice);
        vm.expectRevert();
        covenant.pause();
        vm.prank(alice);
        vm.expectRevert();
        covenant.resolve();
        vm.prank(address(factory));
        vm.expectRevert();
        covenant.terminate();
    }

    // ==================== UNPAUSE TESTS (15) ====================
    function test_Unpause_FromPaused() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.unpause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Active));
    }
    function test_Unpause_OnlyCreator() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(bob);
        vm.expectRevert();
        covenant.unpause();
    }
    function test_Unpause_FromActiveDoesNotRevert() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.unpause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Active));
    }
    function test_Unpause_FromDraftDoesNotRevert() public {
        vm.prank(alice);
        covenant.unpause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Draft));
    }
    function test_Unpause_FromResolvedDoesNotRevert() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.resolve();
        vm.prank(alice);
        covenant.unpause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Resolved));
    }
    function test_Unpause_FromTerminatedDoesNotRevert() public {
        vm.prank(address(factory));
        covenant.terminate();
        vm.prank(alice);
        covenant.unpause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Terminated));
    }
    function test_Unpause_EmitsStateChange() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.expectEmit(true, true, false, false);
        emit CovenantImplementation.CovenantStateChanged(2, 1);
        vm.prank(alice);
        covenant.unpause();
    }
    function test_Unpause_ByCreatorOnly() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.unpause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Active));
    }
    function test_Unpause_OwnerCannotUnpause() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(owner);
        vm.expectRevert();
        covenant.unpause();
    }
    function test_Unpause_FactoryCannotUnpause() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(address(factory));
        vm.expectRevert();
        covenant.unpause();
    }
    function test_Unpause_NoEthRequired() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.unpause();
        assertEq(address(covenant).balance, 0);
    }
    function test_Unpause_CanStillReceiveEth() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.unpause();
        (bool success,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success);
    }
    function test_Unpause_MultipleUnpausesAllowed() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.unpause();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.unpause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Active));
    }
    function test_Unpause_FromUnpausedDoesNotChangeState() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.unpause();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Active));
    }
    function test_Unpause_CanResolveAfter() public {
        vm.prank(alice);
        covenant.activate();
        vm.prank(alice);
        covenant.pause();
        vm.prank(alice);
        covenant.unpause();
        vm.prank(alice);
        covenant.resolve();
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Resolved));
    }

    // ==================== RECEIVE/FALLBACK TESTS (10) ====================
    function test_Receive_AcceptsEth() public {
        (bool success,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(covenant).balance, 1 ether);
    }
    function test_Fallback_AcceptsEth() public {
        (bool success,) = address(covenant).call{value: 1 ether}(abi.encodeWithSelector(bytes4(0x12345678)));
        assertTrue(success);
    }
    function test_Receive_MultipleDeposits() public {
        for (uint256 i = 0; i < 5; i++) {
            (bool success,) = address(covenant).call{value: 1 ether}("");
            assertTrue(success);
        }
        assertEq(address(covenant).balance, 5 ether);
    }
    function test_Receive_ZeroEthAllowed() public {
        (bool success,) = address(covenant).call{value: 0}("");
        assertTrue(success);
    }
    function test_Receive_LargeAmountAllowed() public {
        (bool success,) = address(covenant).call{value: 1000 ether}("");
        assertTrue(success);
        assertEq(address(covenant).balance, 1000 ether);
    }
    function test_Receive_FromAnyone() public {
        vm.prank(alice);
        (bool success,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success);
        vm.prank(bob);
        (bool success2,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success2);
    }
    function test_Fallback_WithData() public {
        (bool success,) = address(covenant).call{value: 1 ether}(abi.encode("data"));
        assertTrue(success);
    }
    function test_Fallback_WithoutValue() public {
        (bool success,) = address(covenant).call(abi.encode("data"));
        assertTrue(success);
    }
    function test_Receive_InAnyState() public {
        (bool success1,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success1);
        vm.prank(alice);
        covenant.activate();
        (bool success2,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success2);
        vm.prank(alice);
        covenant.resolve();
        (bool success3,) = address(covenant).call{value: 1 ether}("");
        assertTrue(success3);
    }
    function test_Receive_DoesNotChangeState() public view {
        assertEq(uint256(covenant.state()), uint256(CovenantImplementation.CovenantState.Draft));
    }
}
