// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@account-abstraction/contracts/core/BasePaymaster.sol";
import "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IReputationStake {
    function calculateReputation(address _agent) external view returns (uint256);
}

/**
 * @title CovenantPaymaster
 * @notice ERC-4337 Paymaster with reputation-tiered gas sponsorship
 * @dev Sponsors gas for new users and high-reputation agents
 */
contract CovenantPaymaster is BasePaymaster {
    using ECDSA for bytes32;
    
    IReputationStake public reputationStake;
    
    uint256 constant TIER_NEW_USER = 0;
    uint256 constant TIER_VERIFIED = 1;
    uint256 constant TIER_PREMIUM = 2;
    
    struct SponsorshipConfig {
        uint16 maxFreeTxPerPeriod;
        uint32 periodDuration;
        uint32 maxGasPerTx;
        uint64 minReputationRequired;
    }
    
    mapping(uint256 => SponsorshipConfig) public tierConfigs;
    mapping(address => uint256) public userTier;
    mapping(address => uint16) public txCountInPeriod;
    mapping(address => uint40) public periodStart;
    
    event GasSponsored(address indexed user, uint256 gasCost, uint256 tier);
    event TierUpgraded(address indexed user, uint256 newTier);
    
    constructor(address _entryPoint, address _reputationStake) BasePaymaster(IEntryPoint(_entryPoint)) {
        reputationStake = IReputationStake(_reputationStake);
        
        tierConfigs[TIER_NEW_USER] = SponsorshipConfig(5, 1 days, 200000, 0);
        tierConfigs[TIER_VERIFIED] = SponsorshipConfig(20, 1 days, 300000, 100);
        tierConfigs[TIER_PREMIUM] = SponsorshipConfig(100, 1 days, 500000, 500);
    }
    
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) internal override returns (bytes memory context, uint256 validationData) {
        
        (uint256 tier, bytes memory signature) = abi.decode(
            userOp.paymasterAndData[20:],
            (uint256, bytes)
        );
        
        address sender = userOp.sender;
        SponsorshipConfig memory config = tierConfigs[tier];
        
        require(_verifyTierEligibility(sender, tier), "Tier not eligible");
        require(userOp.callGasLimit <= config.maxGasPerTx, "Gas limit exceeded");
        
        _checkAndResetPeriod(sender, config);
        require(txCountInPeriod[sender] < config.maxFreeTxPerPeriod, "Tx limit reached");
        
        bytes32 hash = keccak256(abi.encodePacked(userOpHash, tier));
        address signer = hash.recover(signature);
        require(signer == owner(), "Invalid signature");
        
        unchecked {
            txCountInPeriod[sender]++;
        }
        
        context = abi.encode(sender, tier, maxCost);
        validationData = _packValidationData(false, uint48(block.timestamp + 3600), 0);
    }
    
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 /*actualUserOpFeePerGas*/
    ) internal override {
        (address sender, uint256 tier,) = abi.decode(context, (address, uint256, uint256));
        
        if (mode == PostOpMode.opSucceeded) {
            _maybeUpgradeTier(sender);
            emit GasSponsored(sender, actualGasCost, tier);
        }
    }
    
    function _verifyTierEligibility(address _user, uint256 _tier) internal view returns (bool) {
        return reputationStake.calculateReputation(_user) >= tierConfigs[_tier].minReputationRequired;
    }
    
    function _checkAndResetPeriod(address _user, SponsorshipConfig memory _config) internal {
        if (block.timestamp > periodStart[_user] + _config.periodDuration) {
            periodStart[_user] = uint40(block.timestamp);
            txCountInPeriod[_user] = 0;
        }
    }
    
    function _maybeUpgradeTier(address _user) internal {
        uint256 currentTier = userTier[_user];
        uint256 reputation = reputationStake.calculateReputation(_user);
        
        if (currentTier < TIER_PREMIUM && reputation >= tierConfigs[TIER_PREMIUM].minReputationRequired) {
            userTier[_user] = TIER_PREMIUM;
            emit TierUpgraded(_user, TIER_PREMIUM);
        } else if (currentTier < TIER_VERIFIED && reputation >= tierConfigs[TIER_VERIFIED].minReputationRequired) {
            userTier[_user] = TIER_VERIFIED;
            emit TierUpgraded(_user, TIER_VERIFIED);
        }
    }
    
    receive() external payable {
        entryPoint.depositTo{value: msg.value}(address(this));
    }
}
