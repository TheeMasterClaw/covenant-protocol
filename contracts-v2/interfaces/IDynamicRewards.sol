// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDynamicRewards {
    struct UserPerformance {
        uint256 totalTasksCompleted;
        uint256 totalTaskValue;
        uint256 successfulDisputes;
        uint256 totalDisputes;
        uint256 onTimeCompletions;
        uint256 lateCompletions;
        uint256 qualityScoreSum;
        uint256 lastActivityTime;
        uint256 currentStreak;
        uint256 bestStreak;
        uint256 currentTier;
        uint256 effectiveMultiplier;
    }
    
    struct TaskCategory {
        string name;
        uint256 baseRewardRate;
        uint256 complexityWeight;
        bool active;
    }
    
    struct RewardPool {
        address token;
        uint256 totalAllocated;
        uint256 totalDistributed;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }
    
    event TaskCompleted(address indexed user, uint256 indexed categoryId, uint256 taskValue, uint256 quality, uint256 timeliness, uint256 newMultiplier);
    event TierUpgraded(address indexed user, uint256 newTier, uint256 multiplier);
    event RewardsAllocated(address indexed user, address indexed token, uint256 amount);
    event RewardsClaimed(address indexed user, address indexed token, uint256 amount);
    event PerformanceUpdated(address indexed user, uint256 newScore);
    event CategoryAdded(uint256 indexed categoryId, string name, uint256 baseRate);
    event PoolCreated(uint256 indexed poolId, address token, uint256 amount);
    
    error UnauthorizedTaskMarket();
    error UnauthorizedOracle();
    error InvalidCategory();
    error InvalidPool();
    error NoRewardsToClaim();
    error InvalidParameters();
    
    function recordTaskCompletion(address user, uint256 categoryId, uint256 taskValue, uint256 quality, uint256 timeliness, uint256 complexity) external;
    function recordDispute(address user, bool successful, uint256 stakeAmount) external;
    function applyDecay(address user) external;
    function claimRewards(address token) external;
    function claimAllRewards() external returns (uint256[] memory amounts);
    function getPerformance(address user) external view returns (UserPerformance memory);
    function getPendingRewards(address user, address token) external view returns (uint256);
    function calculateMultiplier(address user) external view returns (uint256);
    function getTierInfo(address user) external view returns (string memory tierName, uint256 tasksNeeded);
}
