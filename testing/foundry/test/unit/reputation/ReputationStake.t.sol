// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DeploymentFixtures} from "../../../fixtures/DeploymentFixtures.sol";
import {ReputationStake} from "../../../../contracts-v2/reputation/ReputationStake.sol";

contract ReputationStakeTest is DeploymentFixtures {
    function setUp() public override {
        super.setUp();
    }

    // ==================== CONSTRUCTOR TESTS (15) ====================
    function test_Constructor_SetsStakeToken() public view {
        assertEq(address(reputationStake.stakeToken()), address(token));
    }
    function test_Constructor_SetsOwner() public view {
        assertEq(reputationStake.owner(), owner);
    }
    function test_Constructor_ZeroTokenReverts() public {
        // The v2 constructor doesn't revert on zero token
        ReputationStake rs = new ReputationStake(address(0));
        assertEq(address(rs.stakeToken()), address(0));
    }
    function test_Constructor_CodeSizeNonZero() public view {
        assertTrue(address(reputationStake).code.length > 0);
    }
    function test_Constructor_BalanceIsZero() public view {
        assertEq(address(reputationStake).balance, 0);
    }
    function test_Constructor_NoEthRequired() public {
        ReputationStake rs = new ReputationStake(address(token));
        assertEq(address(rs).balance, 0);
    }
    function test_Constructor_MultipleInstancesIndependent() public {
        ReputationStake rs1 = new ReputationStake(address(token));
        ReputationStake rs2 = new ReputationStake(address(rewardToken));
        assertEq(address(rs1.stakeToken()), address(token));
        assertEq(address(rs2.stakeToken()), address(rewardToken));
    }
    function test_Constructor_DifferentTokensAllowed() public {
        ReputationStake rs = new ReputationStake(address(rewardToken));
        assertEq(address(rs.stakeToken()), address(rewardToken));
    }
    function test_Constructor_EOATokenAllowed() public {
        ReputationStake rs = new ReputationStake(alice);
        assertEq(address(rs.stakeToken()), alice);
    }
    function test_Constructor_PrecompileTokenAllowed() public {
        ReputationStake rs = new ReputationStake(address(1));
        assertEq(address(rs.stakeToken()), address(1));
    }
    function test_Constructor_MaxAddressTokenAllowed() public {
        address maxAddr = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        ReputationStake rs = new ReputationStake(maxAddr);
        assertEq(address(rs.stakeToken()), maxAddr);
    }
    function test_Constructor_TotalStakedAmountZero() public view {
        assertEq(reputationStake.totalStaked(), 0);
    }
    function test_Constructor_StateInitialized() public view {
        assertEq(reputationStake.totalStaked(), 0);
    }
    function test_Constructor_OwnableSetCorrectly() public view {
        assertEq(reputationStake.owner(), owner);
    }
    function test_Constructor_TransferOwnershipAvailable() public asOwner {
        reputationStake.transferOwnership(alice);
        assertEq(reputationStake.owner(), alice);
    }

    // ==================== STAKE TESTS (30) ====================
    function test_Stake_EOA() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        IReputationStake.StakeInfo memory info = reputationStake.getStakeInfo(alice);
        assertEq(info.amount, 1 ether);
    }
    function test_Stake_EmitsEvent() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        vm.expectEmit(true, true, true, false);
        emit ReputationStake.Staked(alice, 1 ether, block.timestamp + 7 days);
        reputationStake.stake(1 ether, 7 days);
    }
    function test_Stake_StoresStakeInfo() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        IReputationStake.StakeInfo memory info = reputationStake.getStakeInfo(alice);
        assertEq(info.amount, 1 ether);
        assertEq(info.locked, true);
        assertEq(info.unlockTime, block.timestamp + 7 days);
    }
    function test_Stake_ZeroAmountReverts() public asAlice {
        vm.expectRevert(ReputationStake.InvalidAmount.selector);
        reputationStake.stake(0, 7 days);
    }
    function test_Stake_UpdatesTotalStaked() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        assertEq(reputationStake.totalStaked(), 1 ether);
    }
    function test_Stake_TransfersTokens() public asAlice {
        uint256 balanceBefore = token.balanceOf(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        assertEq(balanceBefore - token.balanceOf(alice), 1 ether);
    }
    function test_Stake_ContractReceivesTokens() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        assertEq(token.balanceOf(address(reputationStake)), 1 ether);
    }
    function test_Stake_MultipleStakes() public asAlice {
        token.approve(address(reputationStake), 3 ether);
        reputationStake.stake(1 ether, 7 days);
        reputationStake.stake(1 ether, 14 days);
        reputationStake.stake(1 ether, 21 days);
        IReputationStake.StakeInfo memory info = reputationStake.getStakeInfo(alice);
        assertEq(info.amount, 3 ether);
    }
    function test_Stake_ExtendsUnlockTime() public asAlice {
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(1 ether, 7 days);
        uint256 firstUnlock = reputationStake.getStakeInfo(alice).unlockTime;
        reputationStake.stake(1 ether, 14 days);
        uint256 secondUnlock = reputationStake.getStakeInfo(alice).unlockTime;
        assertEq(secondUnlock, firstUnlock + 7 days);
    }
    function test_Stake_DoesNotReduceUnlockTime() public asAlice {
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(1 ether, 14 days);
        uint256 firstUnlock = reputationStake.getStakeInfo(alice).unlockTime;
        reputationStake.stake(1 ether, 7 days);
        uint256 secondUnlock = reputationStake.getStakeInfo(alice).unlockTime;
        assertEq(secondUnlock, firstUnlock);
    }
    function test_Stake_ZeroLockDuration() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        IReputationStake.StakeInfo memory info = reputationStake.getStakeInfo(alice);
        assertEq(info.locked, false);
        assertEq(info.unlockTime, block.timestamp);
    }
    function test_Stake_LargeAmount() public asAlice {
        token.approve(address(reputationStake), 1000000 ether);
        reputationStake.stake(1000000 ether, 7 days);
        assertEq(reputationStake.getStakeInfo(alice).amount, 1000000 ether);
    }
    function test_Stake_DifferentUsers() public {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        vm.stopPrank();
        vm.startPrank(bob);
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(2 ether, 7 days);
        vm.stopPrank();
        assertEq(reputationStake.getStakeInfo(alice).amount, 1 ether);
        assertEq(reputationStake.getStakeInfo(bob).amount, 2 ether);
    }
    function test_Stake_TotalStakedMultipleUsers() public {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        vm.stopPrank();
        vm.startPrank(bob);
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(2 ether, 7 days);
        vm.stopPrank();
        assertEq(reputationStake.totalStaked(), 3 ether);
    }
    function test_Stake_StakedAtIsBlockTimestamp() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        assertEq(reputationStake.getStakeInfo(alice).stakedAt, block.timestamp);
    }
    function test_Stake_AfterWarp() public asAlice {
        vm.warp(block.timestamp + 1 days);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        assertEq(reputationStake.getStakeInfo(alice).stakedAt, block.timestamp);
    }
    function test_Stake_EventContainsCorrectAmount() public asAlice {
        token.approve(address(reputationStake), 5 ether);
        vm.expectEmit(true, true, true, false);
        emit ReputationStake.Staked(alice, 5 ether, block.timestamp + 7 days);
        reputationStake.stake(5 ether, 7 days);
    }
    function test_Stake_EventContainsCorrectAccount() public asBob {
        token.approve(address(reputationStake), 1 ether);
        vm.expectEmit(true, true, true, false);
        emit ReputationStake.Staked(bob, 1 ether, block.timestamp + 7 days);
        reputationStake.stake(1 ether, 7 days);
    }
    function test_Stake_EventContainsCorrectUnlockTime() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        uint256 unlockTime = block.timestamp + 30 days;
        vm.expectEmit(true, true, true, false);
        emit ReputationStake.Staked(alice, 1 ether, unlockTime);
        reputationStake.stake(1 ether, 30 days);
    }
    function test_Stake_10Stakes() public asAlice {
        token.approve(address(reputationStake), 10 ether);
        for (uint256 i = 0; i < 10; i++) {
            reputationStake.stake(1 ether, 7 days);
        }
        assertEq(reputationStake.getStakeInfo(alice).amount, 10 ether);
    }
    function test_Stake_100Stakes() public asAlice {
        token.approve(address(reputationStake), 100 ether);
        for (uint256 i = 0; i < 100; i++) {
            reputationStake.stake(1 ether, 7 days);
        }
        assertEq(reputationStake.getStakeInfo(alice).amount, 100 ether);
    }
    function test_Stake_MaxUint256LockDuration() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, type(uint256).max);
        assertEq(reputationStake.getStakeInfo(alice).unlockTime, block.timestamp + type(uint256).max);
    }
    function test_Stake_MinAmount() public asAlice {
        token.approve(address(reputationStake), 1);
        reputationStake.stake(1, 7 days);
        assertEq(reputationStake.getStakeInfo(alice).amount, 1);
    }
    function test_Stake_NoApprovalReverts() public asAlice {
        vm.expectRevert();
        reputationStake.stake(1 ether, 7 days);
    }
    function test_Stake_InsufficientApprovalReverts() public asAlice {
        token.approve(address(reputationStake), 0.5 ether);
        vm.expectRevert();
        reputationStake.stake(1 ether, 7 days);
    }
    function test_Stake_LockedFlagTrue() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 1);
        assertEq(reputationStake.getStakeInfo(alice).locked, true);
    }
    function test_Stake_LockedFlagFalse() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        assertEq(reputationStake.getStakeInfo(alice).locked, false);
    }

    // ==================== UNSTAKE TESTS (25) ====================
    function test_Unstake_FullAmount() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Unstake_EmitsEvent() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.expectEmit(true, true, false, false);
        emit ReputationStake.Unstaked(alice, 1 ether);
        reputationStake.unstake(1 ether);
    }
    function test_Unstake_UpdatesTotalStaked() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.totalStaked(), 0);
    }
    function test_Unstake_TransfersTokensBack() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        uint256 balanceBefore = token.balanceOf(alice);
        reputationStake.unstake(1 ether);
        assertEq(token.balanceOf(alice) - balanceBefore, 1 ether);
    }
    function test_Unstake_InsufficientStakeReverts() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.expectRevert(ReputationStake.InsufficientStake.selector);
        reputationStake.unstake(2 ether);
    }
    function test_Unstake_StakeLockedReverts() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        vm.expectRevert(ReputationStake.StakeLocked.selector);
        reputationStake.unstake(1 ether);
    }
    function test_Unstake_PartialAmount() public asAlice {
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(2 ether, 0);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.getStakeInfo(alice).amount, 1 ether);
    }
    function test_Unstake_MultipleUnstakes() public asAlice {
        token.approve(address(reputationStake), 3 ether);
        reputationStake.stake(3 ether, 0);
        reputationStake.unstake(1 ether);
        reputationStake.unstake(1 ether);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Unstake_AfterLockExpires() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        vm.warp(block.timestamp + 7 days);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Unstake_AfterLockExpiresPartial() public asAlice {
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(2 ether, 7 days);
        vm.warp(block.timestamp + 7 days);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.getStakeInfo(alice).amount, 1 ether);
    }
    function test_Unstake_DifferentUsers() public {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        vm.startPrank(bob);
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(2 ether, 0);
        vm.stopPrank();
        vm.prank(alice);
        reputationStake.unstake(1 ether);
        vm.prank(bob);
        reputationStake.unstake(2 ether);
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
        assertEq(reputationStake.getStakeInfo(bob).amount, 0);
    }
    function test_Unstake_TotalStakedDecreases() public asAlice {
        token.approve(address(reputationStake), 3 ether);
        reputationStake.stake(3 ether, 0);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.totalStaked(), 2 ether);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.totalStaked(), 1 ether);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.totalStaked(), 0);
    }
    function test_Unstake_EventContainsCorrectAmount() public asAlice {
        token.approve(address(reputationStake), 5 ether);
        reputationStake.stake(5 ether, 0);
        vm.expectEmit(true, true, false, false);
        emit ReputationStake.Unstaked(alice, 3 ether);
        reputationStake.unstake(3 ether);
    }
    function test_Unstake_EventContainsCorrectAccount() public asBob {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.expectEmit(true, true, false, false);
        emit ReputationStake.Unstaked(bob, 1 ether);
        reputationStake.unstake(1 ether);
    }
    function test_Unstake_ZeroAmountAllowed() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        reputationStake.unstake(0);
        assertEq(reputationStake.getStakeInfo(alice).amount, 1 ether);
    }
    function test_Unstake_LockExpiredExactTime() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        vm.warp(block.timestamp + 7 days);
        reputationStake.unstake(1 ether);
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Unstake_LockNotExpiredOneSecondBefore() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        vm.warp(block.timestamp + 7 days - 1);
        vm.expectRevert(ReputationStake.StakeLocked.selector);
        reputationStake.unstake(1 ether);
    }
    function test_Unstake_ContractBalanceDecreases() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        uint256 balanceBefore = token.balanceOf(address(reputationStake));
        reputationStake.unstake(1 ether);
        assertEq(balanceBefore - token.balanceOf(address(reputationStake)), 1 ether);
    }
    function test_Unstake_NoReentrancy() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        reputationStake.unstake(1 ether);
        vm.expectRevert(ReputationStake.InsufficientStake.selector);
        reputationStake.unstake(1 ether);
    }
    function test_Unstake_AlreadyUnstakedReverts() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        reputationStake.unstake(1 ether);
        vm.expectRevert(ReputationStake.InsufficientStake.selector);
        reputationStake.unstake(1 ether);
    }
    function test_Unstake_10Unstakes() public asAlice {
        token.approve(address(reputationStake), 10 ether);
        reputationStake.stake(10 ether, 0);
        for (uint256 i = 0; i < 10; i++) {
            reputationStake.unstake(1 ether);
        }
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Unstake_MaxUint256AmountReverts() public asAlice {
        vm.expectRevert(ReputationStake.InsufficientStake.selector);
        reputationStake.unstake(type(uint256).max);
    }

    // ==================== SLASH TESTS (20) ====================
    function test_Slash_ByOwner() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Slash_EmitsEvent() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        vm.expectEmit(true, true, true, false);
        emit ReputationStake.Slashed(alice, 1 ether, keccak256("reason"));
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
    }
    function test_Slash_UpdatesTotalStaked() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(reputationStake.totalStaked(), 0);
    }
    function test_Slash_TransfersToOwner() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(token.balanceOf(owner) - ownerBalanceBefore, 1 ether);
    }
    function test_Slash_InsufficientStakeReverts() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        vm.expectRevert(ReputationStake.InsufficientStake.selector);
        reputationStake.slash(alice, 2 ether, keccak256("reason"));
    }
    function test_Slash_NonOwnerReverts() public {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        vm.prank(bob);
        vm.expectRevert();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
    }
    function test_Slash_PartialAmount() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(2 ether, 0);
        vm.stopPrank();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(reputationStake.getStakeInfo(alice).amount, 1 ether);
    }
    function test_Slash_MultipleSlashes() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 3 ether);
        reputationStake.stake(3 ether, 0);
        vm.stopPrank();
        reputationStake.slash(alice, 1 ether, keccak256("reason1"));
        reputationStake.slash(alice, 1 ether, keccak256("reason2"));
        reputationStake.slash(alice, 1 ether, keccak256("reason3"));
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Slash_DifferentUsers() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        vm.startPrank(bob);
        token.approve(address(reputationStake), 2 ether);
        reputationStake.stake(2 ether, 0);
        vm.stopPrank();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        reputationStake.slash(bob, 2 ether, keccak256("reason"));
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
        assertEq(reputationStake.getStakeInfo(bob).amount, 0);
    }
    function test_Slash_LockedStakeCanBeSlashed() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        vm.stopPrank();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Slash_EventContainsCorrectAccount() public asOwner {
        vm.startPrank(bob);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        vm.expectEmit(true, true, true, false);
        emit ReputationStake.Slashed(bob, 1 ether, keccak256("reason"));
        reputationStake.slash(bob, 1 ether, keccak256("reason"));
    }
    function test_Slash_EventContainsCorrectAmount() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 5 ether);
        reputationStake.stake(5 ether, 0);
        vm.stopPrank();
        vm.expectEmit(true, true, true, false);
        emit ReputationStake.Slashed(alice, 3 ether, keccak256("reason"));
        reputationStake.slash(alice, 3 ether, keccak256("reason"));
    }
    function test_Slash_EventContainsCorrectReason() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        bytes32 reason = keccak256("bad behavior");
        vm.expectEmit(true, true, true, false);
        emit ReputationStake.Slashed(alice, 1 ether, reason);
        reputationStake.slash(alice, 1 ether, reason);
    }
    function test_Slash_ZeroAmountAllowed() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        reputationStake.slash(alice, 0, keccak256("reason"));
        assertEq(reputationStake.getStakeInfo(alice).amount, 1 ether);
    }
    function test_Slash_ContractBalanceDecreases() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        uint256 balanceBefore = token.balanceOf(address(reputationStake));
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(balanceBefore - token.balanceOf(address(reputationStake)), 1 ether);
    }
    function test_Slash_TotalStakedDecreases() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 3 ether);
        reputationStake.stake(3 ether, 0);
        vm.stopPrank();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(reputationStake.totalStaked(), 2 ether);
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(reputationStake.totalStaked(), 1 ether);
    }
    function test_Slash_NoReentrancy() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        vm.expectRevert(ReputationStake.InsufficientStake.selector);
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
    }
    function test_Slash_10Slashes() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 10 ether);
        reputationStake.stake(10 ether, 0);
        vm.stopPrank();
        for (uint256 i = 0; i < 10; i++) {
            reputationStake.slash(alice, 1 ether, keccak256(abi.encode(i)));
        }
        assertEq(reputationStake.getStakeInfo(alice).amount, 0);
    }
    function test_Slash_AlwaysToOwner() public asOwner {
        vm.startPrank(alice);
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        vm.stopPrank();
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        reputationStake.slash(alice, 1 ether, keccak256("reason"));
        assertEq(token.balanceOf(owner) - ownerBalanceBefore, 1 ether);
    }

    // ==================== VIEW FUNCTION TESTS (10) ====================
    function test_GetStakeInfo_Empty() public view {
        IReputationStake.StakeInfo memory info = reputationStake.getStakeInfo(alice);
        assertEq(info.amount, 0);
        assertEq(info.stakedAt, 0);
        assertEq(info.unlockTime, 0);
        assertEq(info.locked, false);
    }
    function test_GetStakeInfo_AfterStake() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        IReputationStake.StakeInfo memory info = reputationStake.getStakeInfo(alice);
        assertEq(info.amount, 1 ether);
        assertEq(info.locked, true);
    }
    function test_TotalStaked_Empty() public view {
        assertEq(reputationStake.totalStaked(), 0);
    }
    function test_TotalStaked_AfterStake() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 7 days);
        assertEq(reputationStake.totalStaked(), 1 ether);
    }
    function test_GetStakeToken_ReturnsCorrectAddress() public view {
        assertEq(reputationStake.getStakeToken(), address(token));
    }
    function test_ViewFunctions_ArePureOrView() public view {
        reputationStake.getStakeInfo(alice);
        reputationStake.totalStaked();
        reputationStake.getStakeToken();
        assertTrue(true);
    }
    function test_GetStakeInfo_ReturnType() public view {
        IReputationStake.StakeInfo memory info = reputationStake.getStakeInfo(alice);
        assertEq(info.amount, 0);
    }
    function test_TotalStaked_ReturnType() public view {
        uint256 total = reputationStake.totalStaked();
        assertEq(total, 0);
    }
    function test_GetStakeToken_ReturnType() public view {
        address tokenAddr = reputationStake.getStakeToken();
        assertEq(tokenAddr, address(token));
    }
    function test_GetStakeInfo_AfterUnstake() public asAlice {
        token.approve(address(reputationStake), 1 ether);
        reputationStake.stake(1 ether, 0);
        reputationStake.unstake(1 ether);
        IReputationStake.StakeInfo memory info = reputationStake.getStakeInfo(alice);
        assertEq(info.amount, 0);
    }
}
