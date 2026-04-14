// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IVeToken} from "../interfaces/IVeToken.sol";
import {IBonding} from "../interfaces/IBonding.sol";
import {IPassport} from "../interfaces/IPassport.sol";
import {IDynamicRewards} from "../interfaces/IDynamicRewards.sol";
import {ISlashing} from "../interfaces/ISlashing.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title CovenantTokenomicsHub
 * @notice Central integration point for all COVENANT tokenomics modules
 * @dev Orchestrates veCOVEN, bonding, passport, dynamic rewards, and slashing
 */
contract CovenantTokenomicsHub is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ State ============
    
    IVeToken public veCoven;
    IBonding public bonding;
    IPassport public passport;
    IDynamicRewards public dynamicRewards;
    ISlashing public slashing;
    IERC20 public coven;
    
    // Protocol fee recipients
    address public treasury;
    uint256 public protocolFeeBps = 500; // 5%
    
    // Integration flags
    bool public requirePassportForTasks;
    bool public requireVeForGovernance;
    bool public dynamicRewardsActive;
    bool public slashingActive;
    
    // Governance parameters
    mapping(bytes32 => uint256) public protocolParameters;
    
    // Task integration
    mapping(address => bool) public authorizedTaskContracts;
    
    // ============ Events ============
    
    event ModuleUpdated(string moduleName, address newAddress);
    event TaskCompletedWithRewards(
        address indexed user,
        uint256 taskValue,
        uint256 veBoost,
        uint256 passportMultiplier,
        uint256 dynamicMultiplier,
        uint256 finalReward
    );
    event ParameterUpdated(bytes32 indexed param, uint256 value);
    event TreasuryUpdated(address indexed newTreasury);
    
    // ============ Errors ============
    
    error ModuleNotSet();
    error UnauthorizedTaskContract();
    error PassportRequired();
    error SlashingNotActive();
    
    // ============ Constructor ============
    
    constructor(address _coven, address _treasury) Ownable(msg.sender) {
        coven = IERC20(_coven);
        treasury = _treasury;
    }
    
    // ============ Administration ============
    
    function setVeToken(address _veCoven) external onlyOwner {
        veCoven = IVeToken(_veCoven);
        emit ModuleUpdated("veCOVEN", _veCoven);
    }
    
    function setBonding(address _bonding) external onlyOwner {
        bonding = IBonding(_bonding);
        emit ModuleUpdated("bonding", _bonding);
    }
    
    function setPassport(address _passport) external onlyOwner {
        passport = IPassport(_passport);
        emit ModuleUpdated("passport", _passport);
    }
    
    function setDynamicRewards(address _dynamicRewards) external onlyOwner {
        dynamicRewards = IDynamicRewards(_dynamicRewards);
        emit ModuleUpdated("dynamicRewards", _dynamicRewards);
    }
    
    function setSlashing(address _slashing) external onlyOwner {
        slashing = ISlashing(_slashing);
        emit ModuleUpdated("slashing", _slashing);
    }
    
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }
    
    function setProtocolFee(uint256 feeBps) external onlyOwner {
        require(feeBps <= 3000, "Fee too high"); // Max 30%
        protocolFeeBps = feeBps;
    }
    
    function setParameter(bytes32 param, uint256 value) external onlyOwner {
        protocolParameters[param] = value;
        emit ParameterUpdated(param, value);
    }
    
    function setIntegrationFlags(
        bool _requirePassport,
        bool _requireVe,
        bool _dynamicRewards,
        bool _slashing
    ) external onlyOwner {
        requirePassportForTasks = _requirePassport;
        requireVeForGovernance = _requireVe;
        dynamicRewardsActive = _dynamicRewards;
        slashingActive = _slashing;
    }
    
    function authorizeTaskContract(address taskContract, bool authorized) external onlyOwner {
        authorizedTaskContracts[taskContract] = authorized;
    }
    
    // ============ Core Integration Functions ============
    
    /**
     * @notice Complete a task with full tokenomics integration
     * @param user Task completer
     * @param categoryId Task category
     * @param taskValue Base task value
     * @param quality Quality score
     * @param timeliness Timeliness score
     * @param complexity Complexity multiplier
     * @return finalReward Calculated final reward
     */
    function processTaskCompletion(
        address user,
        uint256 categoryId,
        uint256 taskValue,
        uint256 quality,
        uint256 timeliness,
        uint256 complexity
    ) external returns (uint256 finalReward) {
        if (!authorizedTaskContracts[msg.sender]) revert UnauthorizedTaskContract();
        if (requirePassportForTasks && !passport.isVerified(user)) revert PassportRequired();
        
        // Record in dynamic rewards
        if (dynamicRewardsActive && address(dynamicRewards) != address(0)) {
            dynamicRewards.recordTaskCompletion(user, categoryId, taskValue, quality, timeliness, complexity);
        }
        
        // Calculate multipliers
        uint256 veBoost = _getVeBoost(user);
        uint256 passportMultiplier = _getPassportMultiplier(user);
        uint256 dynamicMultiplier = _getDynamicMultiplier(user);
        
        // Combined reward calculation
        finalReward = (taskValue * veBoost * passportMultiplier * dynamicMultiplier) / (10000 * 10000 * 10000);
        
        // Apply protocol fee
        uint256 fee = (finalReward * protocolFeeBps) / 10000;
        finalReward -= fee;
        
        // Update veCOVEN task boost based on performance
        if (address(veCoven) != address(0)) {
            uint256 taskBoost = _calculateTaskBoost(dynamicMultiplier, quality);
            veCoven.updateTaskBoost(user, taskBoost);
        }
        
        emit TaskCompletedWithRewards(
            user,
            taskValue,
            veBoost,
            passportMultiplier,
            dynamicMultiplier,
            finalReward
        );
    }
    
    /**
     * @notice Process dispute outcome with slashing
     */
    function processDisputeOutcome(
        address juror,
        bool votedCorrectly,
        uint256 stakeAmount,
        address stakeToken
    ) external {
        if (!authorizedTaskContracts[msg.sender]) revert UnauthorizedTaskContract();
        
        // Record dispute in dynamic rewards
        if (dynamicRewardsActive && address(dynamicRewards) != address(0)) {
            dynamicRewards.recordDispute(juror, votedCorrectly, stakeAmount);
        }
        
        // Apply slash if voted incorrectly
        if (!votedCorrectly && slashingActive && address(slashing) != address(0)) {
            slashing.slashMissedVote(juror, stakeToken, stakeAmount);
        }
    }
    
    /**
     * @notice Distribute protocol fees from task completion
     */
    function distributeFees(address token, uint256 amount) external {
        if (!authorizedTaskContracts[msg.sender]) revert UnauthorizedTaskContract();
        
        uint256 treasuryShare = (amount * protocolFeeBps) / 10000;
        uint256 veRewardShare = amount - treasuryShare;
        
        // Send to treasury
        if (treasuryShare > 0) {
            IERC20(token).safeTransferFrom(msg.sender, treasury, treasuryShare);
        }
        
        // Deposit as veCOVEN rewards
        if (veRewardShare > 0 && address(veCoven) != address(0)) {
            IERC20(token).safeTransferFrom(msg.sender, address(veCoven), veRewardShare);
            veCoven.depositRewards(token, veRewardShare);
        }
    }
    
    /**
     * @notice Get comprehensive user tokenomics profile
     */
    function getUserProfile(address user) external view returns (
        uint256 veBalance,
        uint256 passportScore,
        bool isVerified,
        uint256 dynamicMultiplier,
        uint256 reputationDamage,
        bool banned
    ) {
        if (address(veCoven) != address(0)) {
            uint256[] memory locks = veCoven.getUserLocks(user);
            for (uint i = 0; i < locks.length; i++) {
                veBalance += veCoven.getVeBalance(locks[i]);
            }
        }
        
        if (address(passport) != address(0)) {
            passportScore = passport.getScore(user);
            isVerified = passport.isVerified(user);
        }
        
        if (address(dynamicRewards) != address(0)) {
            dynamicMultiplier = dynamicRewards.calculateMultiplier(user);
        }
        
        if (address(slashing) != address(0)) {
            (, , reputationDamage, banned) = slashing.getOffenderHistory(user);
        }
    }
    
    // ============ Internal Helpers ============
    
    function _getVeBoost(address user) internal view returns (uint256) {
        if (address(veCoven) == address(0)) return 10000;
        
        uint256[] memory locks = veCoven.getUserLocks(user);
        if (locks.length == 0) return 10000;
        
        uint256 maxBoost = 10000;
        for (uint i = 0; i < locks.length; i++) {
            uint256 boost = veCoven.getTotalBoost(user, locks[i]);
            if (boost > maxBoost) maxBoost = boost;
        }
        return maxBoost;
    }
    
    function _getPassportMultiplier(address user) internal view returns (uint256) {
        if (address(passport) == address(0)) return 10000;
        return passport.getRewardMultiplier(user);
    }
    
    function _getDynamicMultiplier(address user) internal view returns (uint256) {
        if (!dynamicRewardsActive || address(dynamicRewards) == address(0)) return 10000;
        return dynamicRewards.calculateMultiplier(user);
    }
    
    function _calculateTaskBoost(uint256 dynamicMultiplier, uint256 quality) internal pure returns (uint256) {
        // Task boost based on dynamic multiplier and quality
        // Max 100% additional boost
        uint256 boost = ((dynamicMultiplier - 10000) * quality) / 10000;
        if (boost > 10000) boost = 10000;
        return boost;
    }
}
