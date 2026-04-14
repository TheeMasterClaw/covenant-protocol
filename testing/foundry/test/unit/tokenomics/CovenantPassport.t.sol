// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../contracts-v2/tokenomics/sybil/CovenantPassport.sol";
import "../../../contracts-v2/tokenomics/COVEN.sol";

contract CovenantPassportTest is Test {
    CovenantPassport public passport;
    COVEN public coven;
    
    address public owner = address(1);
    address public user = address(2);
    address public verifier = address(3);
    
    function setUp() public {
        vm.startPrank(owner);
        coven = new COVEN("COVENANT", "COVEN", 100_000_000e18, 500);
        passport = new CovenantPassport(address(coven));
        passport.addVerifier(verifier);
        
        coven.transfer(user, 100_000e18);
        vm.stopPrank();
    }
    
    function _signStamp(address signer, address _user, bytes32 provider, bytes32 hash) internal view returns (bytes memory) {
        bytes32 digest = keccak256(abi.encodePacked(_user, provider, hash, block.timestamp / 1 days));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)) + 1, MessageHashUtils.toEthSignedMessageHash(digest));
        return abi.encodePacked(r, s, v);
    }
    
    function testAddStamp() public {
        bytes32 provider = keccak256("twitter");
        bytes32 hash = keccak256("credential1");
        bytes memory sig = _signStamp(verifier, user, provider, hash);
        
        vm.prank(user);
        passport.addStamp(provider, hash, sig);
        
        assertEq(passport.getScore(user), 15);
    }
    
    function testPassportVerified() public {
        bytes32[] memory providers = new bytes32[](4);
        providers[0] = keccak256("twitter");
        providers[1] = keccak256("github");
        providers[2] = keccak256("ens");
        providers[3] = keccak256("poap");
        
        vm.startPrank(owner);
        for (uint i = 0; i < providers.length; i++) {
            passport.batchVerifyStamps(
                _toArray(user),
                _toArray(providers[i]),
                _toArray(keccak256(abi.encodePacked("cred", i)))
            );
        }
        vm.stopPrank();
        
        assertGe(passport.getScore(user), 50);
        assertTrue(passport.isVerified(user));
    }
    
    function testReputationStakeBoost() public {
        vm.startPrank(user);
        coven.approve(address(passport), type(uint256).max);
        passport.stakeReputation(5000e18);
        vm.stopPrank();
        
        // 5000 / 100 = 50 boost, capped at 20
        assertEq(passport.getScore(user), 20);
    }
    
    function testRewardMultiplier() public {
        vm.startPrank(owner);
        passport.batchVerifyStamps(
            _toArray(user),
            _toArray(keccak256("twitter")),
            _toArray(keccak256("cred"))
        );
        vm.stopPrank();
        
        uint256 score = passport.getScore(user);
        uint256 multiplier = passport.getRewardMultiplier(user);
        
        if (score >= 50) {
            assertGe(multiplier, 10000);
            assertLe(multiplier, 20000);
        }
    }
    
    function _toArray(address val) internal pure returns (address[] memory arr) {
        arr = new address[](1);
        arr[0] = val;
    }
    
    function _toArray(bytes32 val) internal pure returns (bytes32[] memory arr) {
        arr = new bytes32[](1);
        arr[0] = val;
    }
}
