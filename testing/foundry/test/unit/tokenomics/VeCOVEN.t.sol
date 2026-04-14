// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../contracts-v2/tokenomics/veToken/veCOVEN.sol";
import "../../../contracts-v2/tokenomics/COVEN.sol";

contract VeCOVENTest is Test {
    VeCOVEN public veCoven;
    COVEN public coven;
    address public owner = address(1);
    address public user = address(2);
    address public rewardToken = address(3);
    
    function setUp() public {
        vm.startPrank(owner);
        coven = new COVEN("COVENANT", "COVEN", 100_000_000e18, 500);
        veCoven = new VeCOVEN(address(coven));
        coven.transfer(user, 100_000e18);
        vm.stopPrank();
        vm.prank(user);
        coven.approve(address(veCoven), type(uint256).max);
    }
    
    function testCreateLock() public {
        vm.prank(user);
        uint256 tokenId = veCoven.createLock(10_000e18, 365 days);
        assertEq(veCoven.ownerOf(tokenId), user);
        assertEq(veCoven.totalLocked(), 10_000e18);
    }
}
