// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../contracts-v2/tokenomics/slashing/CovenantSlashing.sol";
import "mocks/MockERC20.sol";

contract CovenantSlashingTest is Test {
    CovenantSlashing public slashing;
    MockERC20 public stakeToken;
    
    address public owner = address(1);
    address public initiator = address(2);
    address public target = address(3);
    address public victim = address(4);
    address public treasury = address(5);
    
    function setUp() public {
        vm.startPrank(owner);
        slashing = new CovenantSlashing(treasury);
        stakeToken = new MockERC20("Stake", "STK", 18);
        slashing.addSlashInitiator(initiator);
        vm.stopPrank();
        
        stakeToken.mint(address(this), 1_000_000e18);
        stakeToken.approve(address(slashing), type(uint256).max);
    }
    
    function testProposeSlash() public {
        vm.prank(initiator);
        uint256 slashId = slashing.proposeSlash(
            target,
            address(stakeToken),
            ISlashing.SlashCategory.JUROR,
            2, // Penalty
            "Missed vote",
            keccak256("evidence"),
            10_000e18,
            victim
        );
        
        ISlashing.SlashRecord memory record = slashing.getSlashRecord(slashId);
        assertEq(record.target, target);
        assertEq(record.severity, 2);
        assertTrue(slashing.canAppeal(slashId));
    }
    
    function testExecuteSlashAfterAppealWindow() public {
        vm.prank(initiator);
        uint256 slashId = slashing.proposeSlash(
            target,
            address(stakeToken),
            ISlashing.SlashCategory.TASK_PROVIDER,
            3, // Major
            "Late delivery",
            keccak256("evidence"),
            10_000e18,
            address(0)
        );
        
        vm.warp(block.timestamp + 8 days);
        
        // Fund the slashing for test purposes
        stakeToken.mint(address(slashing), 10_000e18);
        
        slashing.executeSlash(slashId, address(stakeToken));
        
        (uint256 offenses,,,) = slashing.getOffenderHistory(target);
        assertEq(offenses, 1);
    }
    
    function testCriticalSlashBansUser() public {
        vm.prank(initiator);
        uint256 slashId = slashing.proposeSlash(
            target,
            address(stakeToken),
            ISlashing.SlashCategory.JUROR,
            4, // Critical
            "Fraud",
            keccak256("evidence"),
            10_000e18,
            address(0)
        );
        
        vm.warp(block.timestamp + 8 days);
        stakeToken.mint(address(slashing), 10_000e18);
        slashing.executeSlash(slashId, address(stakeToken));
        
        (,,, bool banned) = slashing.getOffenderHistory(target);
        assertTrue(banned);
    }
    
    function testSlashAmountWithHistory() public {
        // First offense
        vm.startPrank(initiator);
        uint256 slash1 = slashing.proposeSlash(target, address(stakeToken), ISlashing.SlashCategory.JUROR, 2, "First", keccak256("ev1"), 10_000e18, address(0));
        vm.stopPrank();
        
        vm.warp(block.timestamp + 8 days);
        stakeToken.mint(address(slashing), 10_000e18);
        slashing.executeSlash(slash1, address(stakeToken));
        
        vm.warp(block.timestamp + 1 days);
        
        // Second offense should have higher slash amount
        vm.startPrank(initiator);
        uint256 slash2 = slashing.proposeSlash(target, address(stakeToken), ISlashing.SlashCategory.JUROR, 2, "Second", keccak256("ev2"), 10_000e18, address(0));
        vm.stopPrank();
        
        ISlashing.SlashRecord memory r1 = slashing.getSlashRecord(slash1);
        ISlashing.SlashRecord memory r2 = slashing.getSlashRecord(slash2);
        assertGt(r2.amount, r1.amount);
    }
    
    function testQuickSlashFunctions() public {
        vm.startPrank(initiator);
        uint256 slashId = slashing.slashMissedVote(target, address(stakeToken), 10_000e18);
        vm.stopPrank();
        
        ISlashing.SlashRecord memory record = slashing.getSlashRecord(slashId);
        assertEq(record.severity, 1);
        assertEq(uint256(record.category), uint256(ISlashing.SlashCategory.JUROR));
    }
    
    function testAppealAndReverse() public {
        vm.prank(initiator);
        uint256 slashId = slashing.proposeSlash(target, address(stakeToken), ISlashing.SlashCategory.JUROR, 2, "Test", keccak256("ev"), 10_000e18, address(0));
        
        uint256 bondAmount = 200e18; // 1% * 2 = 2%, so 200e18 for 10k stake
        
        vm.deal(target, 1e18);
        vm.prank(target);
        slashing.appealSlash{value: bondAmount}(slashId);
        
        ISlashing.SlashRecord memory record = slashing.getSlashRecord(slashId);
        assertEq(uint256(record.status), uint256(ISlashing.SlashStatus.APPEALED));
        
        vm.prank(owner);
        slashing.resolveAppeal(slashId, false);
        
        record = slashing.getSlashRecord(slashId);
        assertEq(uint256(record.status), uint256(ISlashing.SlashStatus.REVERSED));
    }
}
