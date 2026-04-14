// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../contracts-v2/tokenomics/dynamic/DynamicRewardDistributor.sol";
import "mocks/MockERC20.sol";

contract DynamicRewardDistributorTest is Test {
    DynamicRewardDistributor public distributor;
    MockERC20 public rewardToken;
    
    address public owner = address(1);
    address public taskMarket = address(2);
    address public user = address(3);
    
    function setUp() public {
        vm.startPrank(owner);
        distributor = new DynamicRewardDistributor();
        rewardToken = new MockERC20("Reward", "RWD");
        
        distributor.addTaskMarket(taskMarket);
        distributor.addTaskCategory("Development", 100e18, 100);
        distributor.createRewardPool(address(rewardToken), 1_000_000e18, 365 days);
        vm.stopPrank();
        
        rewardToken.mint(address(distributor), 1_000_000e18);
    }
    
    function testRecordTaskCompletion() public {
        vm.prank(taskMarket);
        distributor.recordTaskCompletion(user, 1, 1000e18, 9000, 10000, 12000);
        
        IDynamicRewards.UserPerformance memory perf = distributor.getPerformance(user);
        assertEq(perf.totalTasksCompleted, 1);
        assertEq(perf.currentTier, 0);
    }
    
    function testTierUpgrade() public {
        vm.startPrank(taskMarket);
        for (uint i = 0; i < 15; i++) {
            distributor.recordTaskCompletion(user, 1, 1000e18, 9500, 10000, 12000);
        }
        vm.stopPrank();
        
        IDynamicRewards.UserPerformance memory perf = distributor.getPerformance(user);
        assertGe(perf.currentTier, 1);
    }
    
    function testMultiplierIncreasesWithTasks() public {
        vm.startPrank(taskMarket);
        distributor.recordTaskCompletion(user, 1, 1000e18, 9000, 10000, 12000);
        vm.stopPrank();
        
        uint256 mult1 = distributor.calculateMultiplier(user);
        
        vm.startPrank(taskMarket);
        for (uint i = 0; i < 20; i++) {
            distributor.recordTaskCompletion(user, 1, 1000e18, 9000, 10000, 12000);
        }
        vm.stopPrank();
        
        uint256 mult2 = distributor.calculateMultiplier(user);
        assertGt(mult2, mult1);
    }
    
    function testDecayReducesMultiplier() public {
        vm.startPrank(taskMarket);
        distributor.recordTaskCompletion(user, 1, 1000e18, 9000, 10000, 12000);
        vm.stopPrank();
        
        uint256 multBefore = distributor.calculateMultiplier(user);
        
        vm.warp(block.timestamp + 120 days);
        distributor.applyDecay(user);
        
        uint256 multAfter = distributor.calculateMultiplier(user);
        assertLe(multAfter, multBefore);
    }
    
    function testClaimRewards() public {
        vm.startPrank(taskMarket);
        distributor.recordTaskCompletion(user, 1, 1000e18, 9000, 10000, 12000);
        vm.stopPrank();
        
        uint256 pending = distributor.getPendingRewards(user, address(rewardToken));
        assertGt(pending, 0);
        
        vm.prank(user);
        distributor.claimRewards(address(rewardToken));
        
        assertEq(distributor.getPendingRewards(user, address(rewardToken)), 0);
        assertGt(rewardToken.balanceOf(user), 0);
    }
}
