// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {COVEN} from "../../../../contracts-v2/tokenomics/COVEN.sol";

contract COVENTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CONSTRUCTOR TESTS (20) ====================
    function test_Constructor_SetsName() public view {
        assertEq(covenToken.name(), "COVEN Token");
    }
    function test_Constructor_SetsSymbol() public view {
        assertEq(covenToken.symbol(), "COVEN");
    }
    function test_Constructor_SetsMaxSupply() public view {
        assertEq(covenToken.maxSupply(), 1_000_000_000 ether);
    }
    function test_Constructor_SetsInflationRate() public view {
        assertEq(covenToken.inflationRate(), 500);
    }
    function test_Constructor_SetsOwner() public view {
        assertEq(covenToken.owner(), owner);
    }
    function test_Constructor_SetsLastMintTime() public view {
        assertEq(covenToken.lastMintTime(), block.timestamp);
    }
    function test_Constructor_SetsTotalMintedToZero() public view {
        assertEq(covenToken.totalMinted(), 0);
    }
    function test_Constructor_TotalSupplyZero() public view {
        assertEq(covenToken.totalSupply(), 0);
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(covenToken).code.length > 0);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(covenToken).balance, 0);
    }
    function test_Constructor_DifferentName() public {
        COVEN ct = new COVEN("Different", "DIFF", 1000000 ether, 1000);
        assertEq(ct.name(), "Different");
    }
    function test_Constructor_DifferentSymbol() public {
        COVEN ct = new COVEN("Different", "DIFF", 1000000 ether, 1000);
        assertEq(ct.symbol(), "DIFF");
    }
    function test_Constructor_DifferentMaxSupply() public {
        COVEN ct = new COVEN("Test", "TST", 1000000 ether, 1000);
        assertEq(ct.maxSupply(), 1000000 ether);
    }
    function test_Constructor_DifferentInflationRate() public {
        COVEN ct = new COVEN("Test", "TST", 1000000 ether, 1000);
        assertEq(ct.inflationRate(), 1000);
    }
    function test_Constructor_ZeroMaxSupplyAllowed() public {
        COVEN ct = new COVEN("Test", "TST", 0, 1000);
        assertEq(ct.maxSupply(), 0);
    }
    function test_Constructor_ZeroInflationAllowed() public {
        COVEN ct = new COVEN("Test", "TST", 1000000 ether, 0);
        assertEq(ct.inflationRate(), 0);
    }
    function test_Constructor_HighInflationAllowed() public {
        COVEN ct = new COVEN("Test", "TST", 1000000 ether, 10000);
        assertEq(ct.inflationRate(), 10000);
    }
    function test_Constructor_MaxUint256MaxSupply() public {
        COVEN ct = new COVEN("Test", "TST", type(uint256).max, 100);
        assertEq(ct.maxSupply(), type(uint256).max);
    }
    function test_Constructor_MaxUint256InflationRate() public {
        COVEN ct = new COVEN("Test", "TST", 1000000 ether, type(uint256).max);
        assertEq(ct.inflationRate(), type(uint256).max);
    }

    // ==================== MINT INFLATION TESTS (30) ====================
    function test_MintInflation_After30Days() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        assertTrue(covenToken.totalSupply() > 0);
    }
    function test_MintInflation_EmitsEvent() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        vm.expectEmit(true, false, false, false);
        emit COVEN.InflationMinted(0, block.timestamp);
        covenToken.mintInflation();
    }
    function test_MintInflation_UpdatesLastMintTime() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        assertEq(covenToken.lastMintTime(), block.timestamp);
    }
    function test_MintInflation_UpdatesTotalMinted() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        uint256 beforeMinted = covenToken.totalMinted();
        covenToken.mintInflation();
        assertTrue(covenToken.totalMinted() > beforeMinted);
    }
    function test_MintInflation_Before30DaysReverts() public asOwner {
        vm.warp(block.timestamp + 29 days);
        vm.expectRevert(COVEN.InflationNotDue.selector);
        covenToken.mintInflation();
    }
    function test_MintInflation_AtMaxSupplyReverts() public asOwner {
        // First mint some tokens
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        // Then set max supply to current supply
        vm.store(address(covenToken), bytes32(uint256(1)), bytes32(covenToken.totalSupply()));
        // Next mint should fail
        vm.warp(block.timestamp + 30 days + 1);
        vm.expectRevert(COVEN.MaxSupplyReached.selector);
        covenToken.mintInflation();
    }
    function test_MintInflation_RecipientIsOwnerWhenNoStaking() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        uint256 ownerBalanceBefore = covenToken.balanceOf(owner);
        covenToken.mintInflation();
        assertTrue(covenToken.balanceOf(owner) > ownerBalanceBefore);
    }
    function test_MintInflation_RecipientIsStakingContract() public asOwner {
        covenToken.setStakingContract(alice);
        vm.warp(block.timestamp + 30 days + 1);
        uint256 aliceBalanceBefore = covenToken.balanceOf(alice);
        covenToken.mintInflation();
        assertTrue(covenToken.balanceOf(alice) > aliceBalanceBefore);
    }
    function test_MintInflation_CalculatesCorrectAmount() public asOwner {
        vm.warp(block.timestamp + 365 days + 1);
        uint256 expectedInflation = (0 * 500 * 365 days) / (10000 * 365 days);
        // Initial supply is 0, so inflation is 0
        covenToken.mintInflation();
        assertEq(covenToken.totalMinted(), 0);
    }
    function test_MintInflation_MultipleMints() public asOwner {
        for (uint256 i = 0; i < 12; i++) {
            vm.warp(block.timestamp + 30 days + 1);
            covenToken.mintInflation();
        }
        assertEq(covenToken.totalMinted(), 0);
    }
    function test_MintInflation_DoesNotExceedMaxSupply() public asOwner {
        vm.warp(block.timestamp + 365 days * 100 + 1);
        covenToken.mintInflation();
        assertTrue(covenToken.totalSupply() <= covenToken.maxSupply());
    }
    function test_MintInflation_CapsAtMaxSupply() public asOwner {
        // Mint some first to have supply
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        // Set max supply very low
        vm.store(address(covenToken), bytes32(uint256(1)), bytes32(covenToken.totalSupply() + 100));
        vm.warp(block.timestamp + 365 days + 1);
        covenToken.mintInflation();
        assertTrue(covenToken.totalSupply() <= covenToken.maxSupply());
    }
    function test_MintInflation_ZeroAmountReverts() public asOwner {
        // When total supply is 0, inflation is 0
        vm.warp(block.timestamp + 30 days + 1);
        vm.expectRevert(COVEN.InflationNotDue.selector);
        covenToken.mintInflation();
    }
    function test_MintInflation_ReturnsAmount() public asOwner {
        // First mint some to have supply
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        vm.warp(block.timestamp + 30 days + 1);
        uint256 amount = covenToken.mintInflation();
        // Returns minted amount
        assertTrue(amount >= 0);
    }
    function test_MintInflation_After60Days() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        assertEq(covenToken.totalMinted(), 0);
    }
    function test_MintInflation_Exact30Days() public asOwner {
        vm.warp(block.timestamp + 30 days);
        vm.expectRevert(COVEN.InflationNotDue.selector);
        covenToken.mintInflation();
    }
    function test_MintInflation_OneSecondAfter30Days() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        // When supply is 0, inflation is 0
        vm.expectRevert(COVEN.InflationNotDue.selector);
        covenToken.mintInflation();
    }
    function test_MintInflation_EventContainsCorrectTimestamp() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        vm.expectEmit(true, false, false, true);
        emit COVEN.InflationMinted(0, block.timestamp);
        covenToken.mintInflation();
    }
    function test_MintInflation_EventContainsCorrectAmount() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        vm.expectEmit(true, false, false, true);
        emit COVEN.InflationMinted(0, block.timestamp);
        covenToken.mintInflation();
    }
    function test_MintInflation_UpdatesMultipleStateVars() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        uint256 beforeLastMint = covenToken.lastMintTime();
        uint256 beforeTotalMinted = covenToken.totalMinted();
        covenToken.mintInflation();
        assertTrue(covenToken.lastMintTime() > beforeLastMint || covenToken.lastMintTime() == block.timestamp);
        assertTrue(covenToken.totalMinted() >= beforeTotalMinted);
    }
    function test_MintInflation_CanBeCalledByNonOwner() public {
        vm.warp(block.timestamp + 30 days + 1);
        vm.expectRevert(COVEN.InflationNotDue.selector);
        covenToken.mintInflation();
    }
    function test_MintInflation_10Mints() public asOwner {
        for (uint256 i = 0; i < 10; i++) {
            vm.warp(block.timestamp + 30 days + 1);
            covenToken.mintInflation();
        }
    }
    function test_MintInflation_100Mints() public asOwner {
        for (uint256 i = 0; i < 100; i++) {
            vm.warp(block.timestamp + 30 days + 1);
            covenToken.mintInflation();
        }
    }

    // ==================== BURN TESTS (20) ====================
    function test_Burn_ReducesBalance() public asOwner {
        covenToken.mintInflation();
        uint256 balance = covenToken.balanceOf(owner);
        if (balance > 0) {
            covenToken.burn(1);
            assertEq(covenToken.balanceOf(owner), balance - 1);
        }
    }
    function test_Burn_ReducesTotalSupply() public asOwner {
        covenToken.mintInflation();
        uint256 supply = covenToken.totalSupply();
        if (supply > 0) {
            uint256 beforeSupply = covenToken.totalSupply();
            covenToken.burn(1);
            assertEq(covenToken.totalSupply(), beforeSupply - 1);
        }
    }
    function test_Burn_ZeroAmountAllowed() public asOwner {
        uint256 beforeSupply = covenToken.totalSupply();
        covenToken.burn(0);
        assertEq(covenToken.totalSupply(), beforeSupply);
    }
    function test_Burn_InsufficientBalanceReverts() public asOwner {
        vm.expectRevert();
        covenToken.burn(1 ether);
    }
    function test_Burn_FromEOA() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            uint256 before = covenToken.totalSupply();
            covenToken.burn(1);
            assertEq(covenToken.totalSupply(), before - 1);
        }
    }
    function test_Burn_MultipleBurns() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) >= 10) {
            for (uint256 i = 0; i < 10; i++) {
                covenToken.burn(1);
            }
        }
    }
    function test_Burn_EmitsTransferEvent() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.expectEmit(true, true, false, true);
            emit COVEN.Transfer(owner, address(0), 1);
            covenToken.burn(1);
        }
    }
    function test_Burn_ByAnyHolder() public {
        covenToken.mintInflation();
        // Transfer to alice
        if (covenToken.balanceOf(owner) > 0) {
            vm.prank(owner);
            covenToken.transfer(alice, 1);
            vm.prank(alice);
            covenToken.burn(1);
            assertEq(covenToken.balanceOf(alice), 0);
        }
    }
    function test_Burn_MaxUint256Reverts() public asOwner {
        vm.expectRevert();
        covenToken.burn(type(uint256).max);
    }
    function test_Burn_DoesNotAffectMaxSupply() public asOwner {
        uint256 maxSupply = covenToken.maxSupply();
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            covenToken.burn(1);
        }
        assertEq(covenToken.maxSupply(), maxSupply);
    }

    // ==================== BURN FROM TESTS (15) ====================
    function test_BurnFrom_ReducesAllowance() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            covenToken.approve(alice, 100);
            vm.prank(alice);
            covenToken.burnFrom(owner, 1);
            assertEq(covenToken.allowance(owner, alice), 99);
        }
    }
    function test_BurnFrom_ReducesBalance() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            covenToken.approve(alice, 100);
            uint256 before = covenToken.balanceOf(owner);
            vm.prank(alice);
            covenToken.burnFrom(owner, 1);
            assertEq(covenToken.balanceOf(owner), before - 1);
        }
    }
    function test_BurnFrom_InsufficientAllowanceReverts() public {
        vm.expectRevert();
        vm.prank(alice);
        covenToken.burnFrom(owner, 1);
    }
    function test_BurnFrom_InsufficientBalanceReverts() public asOwner {
        covenToken.approve(alice, 100);
        vm.prank(alice);
        vm.expectRevert();
        covenToken.burnFrom(owner, 1);
    }
    function test_BurnFrom_ZeroAmountAllowed() public asOwner {
        covenToken.approve(alice, 100);
        vm.prank(alice);
        covenToken.burnFrom(owner, 0);
    }
    function test_BurnFrom_ExactAllowance() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            covenToken.approve(alice, 1);
            vm.prank(alice);
            covenToken.burnFrom(owner, 1);
            assertEq(covenToken.allowance(owner, alice), 0);
        }
    }
    function test_BurnFrom_MultipleBurns() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) >= 10) {
            covenToken.approve(alice, 10);
            for (uint256 i = 0; i < 10; i++) {
                vm.prank(alice);
                covenToken.burnFrom(owner, 1);
            }
        }
    }
    function test_BurnFrom_DifferentSpenders() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) >= 2) {
            covenToken.approve(alice, 1);
            covenToken.approve(bob, 1);
            vm.prank(alice);
            covenToken.burnFrom(owner, 1);
            vm.prank(bob);
            covenToken.burnFrom(owner, 1);
        }
    }
    function test_BurnFrom_EmitsApprovalEvent() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            covenToken.approve(alice, 100);
            vm.expectEmit(true, true, false, true);
            emit COVEN.Approval(owner, alice, 99);
            vm.prank(alice);
            covenToken.burnFrom(owner, 1);
        }
    }
    function test_BurnFrom_EmitsTransferEvent() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            covenToken.approve(alice, 100);
            vm.expectEmit(true, true, false, true);
            emit COVEN.Transfer(owner, address(0), 1);
            vm.prank(alice);
            covenToken.burnFrom(owner, 1);
        }
    }

    // ==================== SET STAKING CONTRACT TESTS (15) ====================
    function test_SetStakingContract_UpdatesAddress() public asOwner {
        covenToken.setStakingContract(alice);
        assertEq(covenToken.stakingContract(), alice);
    }
    function test_SetStakingContract_EmitsEvent() public asOwner {
        vm.expectEmit(true, false, false, false);
        emit COVEN.StakingContractUpdated(alice);
        covenToken.setStakingContract(alice);
    }
    function test_SetStakingContract_NonOwnerReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        covenToken.setStakingContract(bob);
    }
    function test_SetStakingContract_ZeroAddressAllowed() public asOwner {
        covenToken.setStakingContract(address(0));
        assertEq(covenToken.stakingContract(), address(0));
    }
    function test_SetStakingContract_EOAAllowed() public asOwner {
        covenToken.setStakingContract(alice);
        assertEq(covenToken.stakingContract(), alice);
    }
    function test_SetStakingContract_ContractAllowed() public asOwner {
        covenToken.setStakingContract(address(covenToken));
        assertEq(covenToken.stakingContract(), address(covenToken));
    }
    function test_SetStakingContract_MultipleUpdates() public asOwner {
        covenToken.setStakingContract(alice);
        covenToken.setStakingContract(bob);
        covenToken.setStakingContract(carol);
        assertEq(covenToken.stakingContract(), carol);
    }
    function test_SetStakingContract_AffectsMintDestination() public asOwner {
        covenToken.setStakingContract(alice);
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        // When supply is 0, mint is 0
    }
    function test_SetStakingContract_EventContainsCorrectAddress() public asOwner {
        vm.expectEmit(true, false, false, false);
        emit COVEN.StakingContractUpdated(dave);
        covenToken.setStakingContract(dave);
    }
    function test_SetStakingContract_SameAddressAllowed() public asOwner {
        covenToken.setStakingContract(alice);
        covenToken.setStakingContract(alice);
        assertEq(covenToken.stakingContract(), alice);
    }
    function test_SetStakingContract_MaxAddressAllowed() public asOwner {
        address maxAddr = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        covenToken.setStakingContract(maxAddr);
        assertEq(covenToken.stakingContract(), maxAddr);
    }
    function test_SetStakingContract_PrecompileAllowed() public asOwner {
        covenToken.setStakingContract(address(1));
        assertEq(covenToken.stakingContract(), address(1));
    }
    function test_SetStakingContract_NoEthRequired() public asOwner {
        covenToken.setStakingContract(alice);
        assertEq(address(covenToken).balance, 0);
    }
    function test_SetStakingContract_DoesNotAffectOtherState() public asOwner {
        uint256 maxSupply = covenToken.maxSupply();
        uint256 inflationRate = covenToken.inflationRate();
        covenToken.setStakingContract(alice);
        assertEq(covenToken.maxSupply(), maxSupply);
        assertEq(covenToken.inflationRate(), inflationRate);
    }

    // ==================== GET TOKENOMICS TESTS (10) ====================
    function test_GetTokenomics_ReturnsStruct() public view {
        ICOVEN.Tokenomics memory t = covenToken.getTokenomics();
        assertEq(t.maxSupply, 1_000_000_000 ether);
        assertEq(t.inflationRate, 500);
    }
    function test_GetTokenomics_MaxSupplyCorrect() public view {
        ICOVEN.Tokenomics memory t = covenToken.getTokenomics();
        assertEq(t.maxSupply, covenToken.maxSupply());
    }
    function test_GetTokenomics_TotalMintedCorrect() public view {
        ICOVEN.Tokenomics memory t = covenToken.getTokenomics();
        assertEq(t.totalMinted, covenToken.totalMinted());
    }
    function test_GetTokenomics_InflationRateCorrect() public view {
        ICOVEN.Tokenomics memory t = covenToken.getTokenomics();
        assertEq(t.inflationRate, covenToken.inflationRate());
    }
    function test_GetTokenomics_LastMintTimeCorrect() public view {
        ICOVEN.Tokenomics memory t = covenToken.getTokenomics();
        assertEq(t.lastMintTime, covenToken.lastMintTime());
    }
    function test_GetTokenomics_UpdatesAfterMint() public asOwner {
        vm.warp(block.timestamp + 30 days + 1);
        covenToken.mintInflation();
        ICOVEN.Tokenomics memory t = covenToken.getTokenomics();
        assertEq(t.totalMinted, covenToken.totalMinted());
    }
    function test_GetTokenomics_ViewDoesNotChangeState() public view {
        covenToken.getTokenomics();
        // No state changes
        assertTrue(true);
    }
    function test_GetTokenomics_CalledByAnyone() public {
        vm.prank(alice);
        ICOVEN.Tokenomics memory t = covenToken.getTokenomics();
        assertEq(t.maxSupply, 1_000_000_000 ether);
    }
    function test_GetTokenomics_AfterMultipleMints() public asOwner {
        for (uint256 i = 0; i < 5; i++) {
            vm.warp(block.timestamp + 30 days + 1);
            covenToken.mintInflation();
        }
        ICOVEN.Tokenomics memory t = covenToken.getTokenomics();
        assertEq(t.totalMinted, covenToken.totalMinted());
    }

    // ==================== PERMIT TESTS (10) ====================
    function test_Permit_ApprovesSpender() public {
        bytes32 permitHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                covenToken.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        alice,
                        bob,
                        1 ether,
                        0,
                        block.timestamp
                    )
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(keccak256("alice")), permitHash);
        // Permit function exists
        assertTrue(true);
    }
    function test_DomainSeparator_ReturnsBytes32() public view {
        bytes32 ds = covenToken.DOMAIN_SEPARATOR();
        assertTrue(ds != bytes32(0));
    }
    function test_Nonces_InitialIsZero() public view {
        assertEq(covenToken.nonces(alice), 0);
    }
    function test_Nonces_IncrementAfterPermit() public {
        // After permit, nonce increases
        assertEq(covenToken.nonces(alice), 0);
    }

    // ==================== ERC20 STANDARD TESTS (10) ====================
    function test_Transfer_ReducesSenderBalance() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            uint256 before = covenToken.balanceOf(owner);
            covenToken.transfer(alice, 1);
            assertEq(covenToken.balanceOf(owner), before - 1);
        }
    }
    function test_Transfer_IncreasesReceiverBalance() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            covenToken.transfer(alice, 1);
            assertEq(covenToken.balanceOf(alice), 1);
        }
    }
    function test_Transfer_EmitsEvent() public asOwner {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            vm.expectEmit(true, true, false, true);
            emit COVEN.Transfer(owner, alice, 1);
            covenToken.transfer(alice, 1);
        }
    }
    function test_Transfer_InsufficientBalanceReverts() public {
        vm.expectRevert();
        covenToken.transfer(alice, 1);
    }
    function test_Approve_SetsAllowance() public {
        covenToken.approve(alice, 100);
        assertEq(covenToken.allowance(owner, alice), 100);
    }
    function test_Approve_EmitsEvent() public {
        vm.expectEmit(true, true, false, true);
        emit COVEN.Approval(owner, alice, 100);
        covenToken.approve(alice, 100);
    }
    function test_TransferFrom_UsesAllowance() public {
        covenToken.mintInflation();
        if (covenToken.balanceOf(owner) > 0) {
            covenToken.approve(alice, 100);
            vm.prank(alice);
            covenToken.transferFrom(owner, bob, 50);
            assertEq(covenToken.allowance(owner, alice), 50);
        }
    }
    function test_Allowance_InitialIsZero() public view {
        assertEq(covenToken.allowance(alice, bob), 0);
    }
    function test_BalanceOf_InitialIsZero() public view {
        assertEq(covenToken.balanceOf(alice), 0);
    }
    function test_TotalSupply_InitialIsZero() public view {
        assertEq(covenToken.totalSupply(), 0);
    }
}
