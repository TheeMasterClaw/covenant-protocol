// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVeToken {
    struct Lock {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 veBalance;
        uint256 withdrawn;
    }
    
    event LockCreated(uint256 indexed tokenId, address indexed owner, uint256 amount, uint256 endTime, uint256 veBalance);
    event LockExtended(uint256 indexed tokenId, uint256 newEndTime, uint256 additionalVeBalance);
    event EarlyExit(uint256 indexed tokenId, uint256 withdrawnAmount, uint256 penaltyAmount);
    event RewardsClaimed(uint256 indexed tokenId, address indexed token, uint256 amount);
    event RewardRateUpdated(address indexed token, uint256 rate);
    event TaskBoostUpdated(address indexed user, uint256 multiplier);
    
    error InvalidLockDuration();
    error LockNotExpired();
    error LockExpired();
    error InsufficientBalance();
    error NotLockOwner();
    error LockNotFound();
    error InvalidAmount();
    error RewardTokenExists();
    
    function createLock(uint256 amount, uint256 duration) external returns (uint256 tokenId);
    function extendLock(uint256 tokenId, uint256 additionalDuration) external;
    function increaseLockAmount(uint256 tokenId, uint256 additionalAmount) external;
    function earlyExit(uint256 tokenId) external returns (uint256 withdrawnAmount);
    function withdraw(uint256 tokenId) external;
    function claimRewards(uint256 tokenId) external returns (uint256[] memory);
    function addRewardToken(address token, uint256 rate) external;
    function depositRewards(address token, uint256 amount) external;
    function updateTaskBoost(address user, uint256 boostPercent) external;
    function getTotalBoost(address user, uint256 tokenId) external view returns (uint256);
    function getVeBalance(uint256 tokenId) external view returns (uint256);
    function getUserLocks(address user) external view returns (uint256[] memory);
    function getLockInfo(uint256 tokenId) external view returns (Lock memory);
    function pendingRewardsAll(uint256 tokenId) external view returns (address[] memory tokens, uint256[] memory amounts);
    function totalVeSupply() external view returns (uint256);
    function totalLocked() external view returns (uint256);
    function coven() external view returns (address);
}
