// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IDynamicRewards} from "../../interfaces/IDynamicRewards.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title DynamicRewardDistributor
 * @notice Dynamic reward curves based on task completion performance
 * @dev Integrates with TaskMarket for on-chain performance tracking
 */
contract DynamicRewardDistributor is IDynamicRewards, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // ============ Constants ============
    
    uint256 public constant BASE_MULTIPLIER = 10000;
    uint256 public constant MAX_MULTIPLIER = 35000; // 3.5x max total boost
    uint256 public constant PRECISION = 1e18;
    
    // Tier thresholds
    uint256 public constant TIER_NOVICE = 10;
    uint256 public constant TIER_PROFICIENT = 50;
    uint256 public constant TIER_EXPERT = 200;
    uint256 public constant TIER_MASTER = 500;
    
    // Decay constants
    uint256 public constant ACTIVITY_WINDOW = 90 days;
    uint256 public constant DECAY_RATE = 100; // 1% per day of inactivity
    
    // ============ State ============
    
    
    
    
    mapping(address => UserPerformance) public performance;
    mapping(uint256 => TaskCategory) public taskCategories;
    mapping(uint256 => RewardPool) public rewardPools;
    mapping(address => mapping(address => uint256)) public pendingRewards;
    mapping(address => mapping(address => uint256)) public claimedRewards;
    mapping(address => bool) public taskMarketContracts;
    mapping(address => bool) public authorizedOracles;
    
    uint256 public nextCategoryId;
    uint256 public nextPoolId;
    address[] public activeRewardTokens;
    
    // Curve parameters
    uint256 public noviceSlope;
    uint256 public proficientCurve;
    uint256 public expertCurve;
    uint256 public masterAsymptote;
    
    // Quality weights
    uint256 public onTimeWeight;
    uint256 public disputeWeight;
    uint256 public qualityWeight;
    uint256 public complexityWeight;
    uint256 public streakWeight;
    
    // ============ Events ============
    
    
    // ============ Errors ============
    
    
    // ============ Constructor ============
    
    constructor() Ownable(msg.sender) {
        nextCategoryId = 1;
        nextPoolId = 1;
        
        noviceSlope = 500;      // 5% per task
        proficientCurve = 100;  // Logarithmic coefficient
        expertCurve = 50;       // S-curve steepness
        masterAsymptote = 30000; // 3x asymptote
        
        onTimeWeight = 2000;
        disputeWeight = 3000;
        qualityWeight = 2500;
        complexityWeight = 1500;
        streakWeight = 1000;
    }
    
    // ============ Administration ============
    
    function addTaskMarket(address market) external onlyOwner {
        taskMarketContracts[market] = true;
    }
    
    function removeTaskMarket(address market) external onlyOwner {
        taskMarketContracts[market] = false;
    }
    
    function addOracle(address oracle) external onlyOwner {
        authorizedOracles[oracle] = true;
    }
    
    function removeOracle(address oracle) external onlyOwner {
        authorizedOracles[oracle] = false;
    }
    
    function addTaskCategory(string calldata name, uint256 baseRate, uint256 complexity) 
        external 
        onlyOwner 
        returns (uint256 categoryId) 
    {
        categoryId = nextCategoryId++;
        taskCategories[categoryId] = TaskCategory({
            name: name,
            baseRewardRate: baseRate,
            complexityWeight: complexity,
            active: true
        });
        emit CategoryAdded(categoryId, name, baseRate);
    }
    
    function createRewardPool(address token, uint256 amount, uint256 duration) 
        external 
        onlyOwner 
        returns (uint256 poolId) 
    {
        if (token == address(0) || amount == 0 || duration == 0) revert InvalidParameters();
        
        poolId = nextPoolId++;
        rewardPools[poolId] = RewardPool({
            token: token,
            totalAllocated: amount,
            totalDistributed: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            active: true
        });
        
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        
        // Track active reward token
        bool exists = false;
        for (uint i = 0; i < activeRewardTokens.length; i++) {
            if (activeRewardTokens[i] == token) {
                exists = true;
                break;
            }
        }
        if (!exists) activeRewardTokens.push(token);
        
        emit PoolCreated(poolId, token, amount);
    }
    
    function setCurveParameters(
        uint256 _noviceSlope,
        uint256 _proficientCurve,
        uint256 _expertCurve,
        uint256 _masterAsymptote
    ) external onlyOwner {
        noviceSlope = _noviceSlope;
        proficientCurve = _proficientCurve;
        expertCurve = _expertCurve;
        masterAsymptote = _masterAsymptote;
    }
    
    function setQualityWeights(
        uint256 _onTime,
        uint256 _dispute,
        uint256 _quality,
        uint256 _complexity,
        uint256 _streak
    ) external onlyOwner {
        uint256 total = _onTime + _dispute + _quality + _complexity + _streak;
        if (total != BASE_MULTIPLIER) revert InvalidParameters();
        
        onTimeWeight = _onTime;
        disputeWeight = _dispute;
        qualityWeight = _quality;
        complexityWeight = _complexity;
        streakWeight = _streak;
    }
    
    // ============ Task Completion Tracking ============
    
    /**
     * @notice Record task completion and update user performance
     * @param user Task completer
     * @param categoryId Task category
     * @param taskValue Value of the task
     * @param quality Quality score (0-10000)
     * @param timeliness Timeliness score (0-10000)
     * @param complexity Complexity multiplier
     */
    function recordTaskCompletion(
        address user,
        uint256 categoryId,
        uint256 taskValue,
        uint256 quality,
        uint256 timeliness,
        uint256 complexity
    ) external {
        if (!taskMarketContracts[msg.sender]) revert UnauthorizedTaskMarket();
        if (!taskCategories[categoryId].active) revert InvalidCategory();
        
        UserPerformance storage perf = performance[user];
        
        // Update basic stats
        perf.totalTasksCompleted++;
        perf.totalTaskValue += taskValue;
        perf.qualityScoreSum += quality;
        
        if (timeliness >= 8000) {
            perf.onTimeCompletions++;
            perf.currentStreak++;
        } else {
            perf.lateCompletions++;
            if (perf.currentStreak > perf.bestStreak) {
                perf.bestStreak = perf.currentStreak;
            }
            perf.currentStreak = 0;
        }
        
        perf.lastActivityTime = block.timestamp;
        
        // Calculate performance score components
        uint256 onTimeScore = (perf.onTimeCompletions * BASE_MULTIPLIER) / 
            (perf.onTimeCompletions + perf.lateCompletions);
        
        uint256 avgQuality = perf.qualityScoreSum / perf.totalTasksCompleted;
        
        uint256 streakBonus = perf.currentStreak >= 10 ? 2500 : 
                             perf.currentStreak >= 5 ? 1500 : 
                             perf.currentStreak >= 3 ? 500 : 0;
        
        // Calculate new tier and multiplier
        uint256 newTier = _calculateTier(perf.totalTasksCompleted, onTimeScore, avgQuality);
        uint256 baseMultiplier = _calculateBaseMultiplier(perf.totalTasksCompleted, newTier);
        
        // Apply quality adjustments
        uint256 qualityMultiplier = (onTimeWeight * onTimeScore + 
                                     qualityWeight * avgQuality +
                                     streakWeight * streakBonus +
                                     complexityWeight * complexity) / BASE_MULTIPLIER;
        
        uint256 finalMultiplier = (baseMultiplier * qualityMultiplier) / BASE_MULTIPLIER;
        if (finalMultiplier > MAX_MULTIPLIER) finalMultiplier = MAX_MULTIPLIER;
        if (finalMultiplier < BASE_MULTIPLIER) finalMultiplier = BASE_MULTIPLIER;
        
        perf.currentTier = newTier;
        perf.effectiveMultiplier = finalMultiplier;
        
        if (newTier > perf.currentTier) {
            emit TierUpgraded(user, newTier, finalMultiplier);
        }
        
        emit TaskCompleted(user, categoryId, taskValue, quality, timeliness, finalMultiplier);
        
        // Calculate and allocate rewards
        uint256 rewardAmount = (taskValue * taskCategories[categoryId].baseRewardRate * finalMultiplier) / 
            (BASE_MULTIPLIER * BASE_MULTIPLIER);
        
        // Find an active pool with this token
        for (uint i = 1; i < nextPoolId; i++) {
            RewardPool storage pool = rewardPools[i];
            if (pool.active && pool.token != address(0) && 
                pool.totalDistributed + rewardAmount <= pool.totalAllocated &&
                block.timestamp >= pool.startTime && block.timestamp <= pool.endTime) {
                
                pendingRewards[user][pool.token] += rewardAmount;
                pool.totalDistributed += rewardAmount;
                emit RewardsAllocated(user, pool.token, rewardAmount);
                break;
            }
        }
    }
    
    /**
     * @notice Record dispute participation
     */
    function recordDispute(
        address user,
        bool successful,
        uint256 stakeAmount
    ) external {
        if (!taskMarketContracts[msg.sender] && !authorizedOracles[msg.sender]) 
            revert UnauthorizedTaskMarket();
        
        UserPerformance storage perf = performance[user];
        perf.totalDisputes++;
        if (successful) perf.successfulDisputes++;
        perf.lastActivityTime = block.timestamp;
        
        // Dispute success adds bonus to multiplier
        uint256 disputeSuccessRate = (perf.successfulDisputes * BASE_MULTIPLIER) / 
            (perf.totalDisputes > 0 ? perf.totalDisputes : 1);
        
        // Re-calculate multiplier with dispute bonus
        uint256 baseMultiplier = _calculateBaseMultiplier(perf.totalTasksCompleted, perf.currentTier);
        uint256 disputeBonus = (disputeWeight * disputeSuccessRate) / BASE_MULTIPLIER;
        uint256 newMultiplier = (baseMultiplier * disputeBonus) / BASE_MULTIPLIER;
        
        if (newMultiplier > MAX_MULTIPLIER) newMultiplier = MAX_MULTIPLIER;
        perf.effectiveMultiplier = newMultiplier;
        
        // Allocate dispute rewards
        uint256 disputeReward = successful ? (stakeAmount * 1000) / BASE_MULTIPLIER : 0; // 10% bonus
        if (disputeReward > 0) {
            for (uint i = 1; i < nextPoolId; i++) {
                RewardPool storage pool = rewardPools[i];
                if (pool.active && pool.totalDistributed + disputeReward <= pool.totalAllocated) {
                    pendingRewards[user][pool.token] += disputeReward;
                    pool.totalDistributed += disputeReward;
                    emit RewardsAllocated(user, pool.token, disputeReward);
                    break;
                }
            }
        }
        
        emit PerformanceUpdated(user, newMultiplier);
    }
    
    /**
     * @notice Apply inactivity decay to a user's multiplier
     */
    function applyDecay(address user) external {
        UserPerformance storage perf = performance[user];
        uint256 timeInactive = block.timestamp > perf.lastActivityTime ? 
            block.timestamp - perf.lastActivityTime : 0;
        
        if (timeInactive > ACTIVITY_WINDOW) {
            uint256 daysInactive = timeInactive / 1 days;
            uint256 decayFactor = BASE_MULTIPLIER - (daysInactive * DECAY_RATE);
            if (decayFactor < 5000) decayFactor = 5000; // Max 50% decay
            
            perf.effectiveMultiplier = (perf.effectiveMultiplier * decayFactor) / BASE_MULTIPLIER;
            if (perf.effectiveMultiplier < BASE_MULTIPLIER) {
                perf.effectiveMultiplier = BASE_MULTIPLIER;
            }
            
            // Reset streak on significant inactivity
            if (daysInactive > 30) {
                if (perf.currentStreak > perf.bestStreak) {
                    perf.bestStreak = perf.currentStreak;
                }
                perf.currentStreak = 0;
            }
            
            emit PerformanceUpdated(user, perf.effectiveMultiplier);
        }
    }
    
    // ============ Reward Claims ============
    
    function claimRewards(address token) external nonReentrant {
        uint256 amount = pendingRewards[msg.sender][token];
        if (amount == 0) revert NoRewardsToClaim();
        
        pendingRewards[msg.sender][token] = 0;
        claimedRewards[msg.sender][token] += amount;
        
        IERC20(token).safeTransfer(msg.sender, amount);
        
        emit RewardsClaimed(msg.sender, token, amount);
    }
    
    function claimAllRewards() external nonReentrant returns (uint256[] memory amounts) {
        amounts = new uint256[](activeRewardTokens.length);
        
        for (uint i = 0; i < activeRewardTokens.length; i++) {
            address token = activeRewardTokens[i];
            uint256 amount = pendingRewards[msg.sender][token];
            
            if (amount > 0) {
                pendingRewards[msg.sender][token] = 0;
                claimedRewards[msg.sender][token] += amount;
                amounts[i] = amount;
                IERC20(token).safeTransfer(msg.sender, amount);
                emit RewardsClaimed(msg.sender, token, amount);
            }
        }
    }
    
    // ============ View Functions ============
    
    function getPerformance(address user) external view returns (UserPerformance memory) {
        return performance[user];
    }
    
    function getPendingRewards(address user, address token) external view returns (uint256) {
        return pendingRewards[user][token];
    }
    
    function calculateMultiplier(address user) external view returns (uint256) {
        UserPerformance storage perf = performance[user];
        if (perf.totalTasksCompleted == 0) return BASE_MULTIPLIER;
        return perf.effectiveMultiplier;
    }
    
    function getTierInfo(address user) external view returns (string memory tierName, uint256 tasksNeeded) {
        UserPerformance storage perf = performance[user];
        uint256 tier = perf.currentTier;
        
        if (tier == 0) return ("Novice", TIER_NOVICE - perf.totalTasksCompleted);
        if (tier == 1) return ("Proficient", TIER_PROFICIENT - perf.totalTasksCompleted);
        if (tier == 2) return ("Expert", TIER_EXPERT - perf.totalTasksCompleted);
        if (tier == 3) return ("Master", TIER_MASTER - perf.totalTasksCompleted);
        return ("Grandmaster", 0);
    }
    
    // ============ Internal Functions ============
    
    function _calculateTier(
        uint256 tasksCompleted,
        uint256 onTimeRate,
        uint256 avgQuality
    ) internal pure returns (uint256 tier) {
        if (tasksCompleted >= TIER_MASTER && onTimeRate >= 9000 && avgQuality >= 8500) return 4;
        if (tasksCompleted >= TIER_EXPERT && onTimeRate >= 8500 && avgQuality >= 8000) return 3;
        if (tasksCompleted >= TIER_PROFICIENT && onTimeRate >= 8000 && avgQuality >= 7500) return 2;
        if (tasksCompleted >= TIER_NOVICE && onTimeRate >= 7000 && avgQuality >= 6500) return 1;
        return 0;
    }
    
    function _calculateBaseMultiplier(uint256 tasksCompleted, uint256 tier) internal view returns (uint256) {
        if (tier == 0) {
            // Novice: Linear 1x to 1.5x
            uint256 progress = (tasksCompleted * BASE_MULTIPLIER) / TIER_NOVICE;
            return BASE_MULTIPLIER + ((progress * 5000) / BASE_MULTIPLIER);
        }
        if (tier == 1) {
            // Proficient: Logarithmic 1.5x to 2x
            uint256 extra = tasksCompleted - TIER_NOVICE;
            uint256 range = TIER_PROFICIENT - TIER_NOVICE;
            uint256 logValue = _log2((extra * 100) / range + 1);
            return 15000 + ((logValue * 5000) / 100);
        }
        if (tier == 2) {
            // Expert: S-curve 2x to 2.75x
            uint256 extra = tasksCompleted - TIER_PROFICIENT;
            uint256 range = TIER_EXPERT - TIER_PROFICIENT;
            uint256 sigmoid = _sigmoid((extra * 1000) / range);
            return 20000 + ((sigmoid * 7500) / BASE_MULTIPLIER);
        }
        if (tier >= 3) {
            // Master+: Asymptotic approach to 3.5x
            uint256 extra = tasksCompleted >= TIER_MASTER ? TIER_MASTER - TIER_EXPERT : tasksCompleted - TIER_EXPERT;
            uint256 range = TIER_MASTER - TIER_EXPERT;
            uint256 asymptotic = (extra * BASE_MULTIPLIER) / (range + extra);
            return 27500 + ((asymptotic * 7500) / BASE_MULTIPLIER);
        }
        return BASE_MULTIPLIER;
    }
    
    function _log2(uint256 x) internal pure returns (uint256) {
        uint256 n = 0;
        while (x > 1) {
            x = x / 2;
            n++;
        }
        return n * 100;
    }
    
    function _sigmoid(uint256 x) internal pure returns (uint256) {
        // Simplified sigmoid: x / (1 + |x|) scaled to 0-10000
        // x is expected in range 0-1000
        if (x > 1000) x = 1000;
        return (x * BASE_MULTIPLIER) / (1000 + x);
    }
}