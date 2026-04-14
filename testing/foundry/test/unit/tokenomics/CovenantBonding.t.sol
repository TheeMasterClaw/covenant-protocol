// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../contracts-v2/tokenomics/bonding/CovenantBonding.sol";
import "../../../contracts-v2/tokenomics/COVEN.sol";
import "mocks/MockERC20.sol";

contract CovenantBondingTest is Test {
    CovenantBonding public bonding;
    COVEN public coven;
    MockERC20 public principal;
    
    address public owner = address(1);
    address public user = address(2);
    address public treasury = address(3);
    
    function setUp() public {
        vm.startPrank(owner);
        coven = new COVEN("COVENANT", "COVEN", 100_000_000e18, 500);
        principal = new MockERC20("Principal", "PRC", 18);
        bonding = new CovenantBonding(address(coven), treasury);
        
        coven.transfer(address(bonding), 1_000_000e18);
        principal.mint(user, 100_000e18);
        vm.stopPrank();
        
        vm.startPrank(user);
        principal.approve(address(bonding), type(uint256).max);
        vm.stopPrank();
    }
    
    function testAddBondType() public {
        vm.prank(owner);
        uint256 bondTypeId = bonding.addBondType(
            address(principal),
            address(0),
            false,
            1000,    // 10% discount
            100_000e18,
            7 days,
            0
        );
        
        assertEq(bondTypeId, 1);
        
        IBonding.BondType memory bt = bonding.getBondTypeInfo(bondTypeId);
        assertEq(bt.baseDiscount, 1000);
        assertTrue(bt.active);
    }
    
    function testDepositAndClaim() public {
        vm.startPrank(owner);
        bonding.addBondType(address(principal), address(0), false, 1000, 100_000e18, 7 days, 0);
        bonding.addPriceUpdater(owner);
        bonding.updatePrice(address(coven), 1e6);     // $1 COVEN
        bonding.updatePrice(address(principal), 1e6); // $1 principal
        vm.stopPrank();
        
        vm.prank(user);
        uint256 bondId = bonding.deposit(1, 1000e18, 500);
        
        IBonding.Bond memory bond = bonding.getBondInfo(bondId);
        assertGt(bond.covenAmount, 0);
        
        // Fast forward past vesting
        vm.warp(block.timestamp + 8 days);
        
        uint256 claimable = bonding.claimableAmount(bondId);
        assertGt(claimable, 0);
        
        vm.prank(user);
        uint256 claimed = bonding.claim(bondId);
        assertEq(claimed, claimable);
    }
    
    function testBondPriceDecreasesWithUtilization() public {
        vm.startPrank(owner);
        bonding.addBondType(address(principal), address(0), false, 1500, 10000e18, 7 days, 0);
        bonding.addPriceUpdater(owner);
        bonding.updatePrice(address(coven), 1e6);
        bonding.updatePrice(address(principal), 1e6);
        vm.stopPrank();
        
        // First deposit at low utilization
        vm.prank(user);
        bonding.deposit(1, 1000e18, 500);
        
        uint256 price1 = bonding.bondPrice(1);
        
        // Second deposit increases utilization
        deal(address(principal), address(4), 10000e18);
        vm.startPrank(address(4));
        principal.approve(address(bonding), type(uint256).max);
        bonding.deposit(1, 5000e18, 500);
        vm.stopPrank();
        
        uint256 price2 = bonding.bondPrice(1);
        
        // Price should increase (discount decreases) with higher utilization
        assertGe(price2, price1);
    }
}
