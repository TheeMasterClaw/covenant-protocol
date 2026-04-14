// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IVeToken} from "../../interfaces/IVeToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract VeCOVEN is IVeToken, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public constant MAX_LOCK_TIME = 4 * 365 days;
    uint256 public constant MIN_LOCK_TIME = 7 days;
    uint256 public constant MAX_BOOST = 25000;
    uint256 public constant BASE_MULTIPLIER = 10000;
    uint256 public constant WEEK = 7 days;
    uint256 public constant PENALTY_25 = 2500;
    uint256 public constant PENALTY_50 = 5000;
    uint256 public constant PENALTY_75 = 7500;

    IERC20 public immutable covenToken;
    
    mapping(uint256 => Lock) public locks;
    mapping(address => uint256[]) public userLocks;
    
    uint256 public totalVeSupply;
    uint256 public totalLocked;
    uint256 public nextTokenId;
    
    mapping(address => uint256) public rewardPerTokenStored;
    mapping(address => mapping(uint256 => uint256)) public rewardPerTokenPaid;
    mapping(address => mapping(uint256 => uint256)) public rewards;
    mapping(address => uint256) public rewardRates;
    address[] public rewardTokens;
    mapping(address => uint256) public taskBoostMultiplier;

    constructor(address _coven) ERC721("Vote-Escrowed COVEN", "veCOVEN") Ownable(msg.sender) {
        covenToken = IERC20(_coven);
        nextTokenId = 1;
    }
    
    function coven() external view returns (address) {
        return address(covenToken);
    }
    
    function createLock(uint256 amount, uint256 duration) 
        external 
        nonReentrant 
        returns (uint256 tokenId) 
    {
        if (amount == 0) revert InvalidAmount();
        if (duration < MIN_LOCK_TIME || duration > MAX_LOCK_TIME) revert InvalidLockDuration();
        
        tokenId = nextTokenId++;
        uint256 veBalance = (amount * duration) / MAX_LOCK_TIME;
        uint256 endTime = ((block.timestamp + duration) / WEEK) * WEEK;
        
        locks[tokenId] = Lock({
            amount: amount,
            startTime: block.timestamp,
            endTime: endTime,
            veBalance: veBalance,
            withdrawn: 0
        });
        
        userLocks[msg.sender].push(tokenId);
        totalVeSupply += veBalance;
        totalLocked += amount;
        
        _mint(msg.sender, tokenId);
        covenToken.safeTransferFrom(msg.sender, address(this), amount);
        
        emit LockCreated(tokenId, msg.sender, amount, endTime, veBalance);
    }
    
    function extendLock(uint256 tokenId, uint256 additionalDuration) 
        external 
        nonReentrant 
    {
        if (ownerOf(tokenId) != msg.sender) revert NotLockOwner();
        
        Lock storage lock = locks[tokenId];
        if (block.timestamp >= lock.endTime) revert LockExpired();
        
        uint256 newDuration = lock.endTime - lock.startTime + additionalDuration;
        if (newDuration > MAX_LOCK_TIME) revert InvalidLockDuration();
        
        _updateRewards(tokenId);
        
        uint256 oldVeBalance = lock.veBalance;
        uint256 newVeBalance = (lock.amount * newDuration) / MAX_LOCK_TIME;
        uint256 additionalVe = newVeBalance - oldVeBalance;
        
        lock.endTime = ((lock.endTime + additionalDuration) / WEEK) * WEEK;
        lock.veBalance = newVeBalance;
        
        totalVeSupply += additionalVe;
        
        emit LockExtended(tokenId, lock.endTime, additionalVe);
    }
    
    function increaseLockAmount(uint256 tokenId, uint256 additionalAmount) 
        external 
        nonReentrant 
    {
        if (additionalAmount == 0) revert InvalidAmount();
        if (ownerOf(tokenId) != msg.sender) revert NotLockOwner();
        
        Lock storage lock = locks[tokenId];
        if (block.timestamp >= lock.endTime) revert LockExpired();
        
        _updateRewards(tokenId);
        
        uint256 oldVeBalance = lock.veBalance;
        lock.amount += additionalAmount;
        
        uint256 remainingDuration = lock.endTime - lock.startTime;
        uint256 newVeBalance = (lock.amount * remainingDuration) / MAX_LOCK_TIME;
        uint256 additionalVe = newVeBalance - oldVeBalance;
        
        lock.veBalance = newVeBalance;
        totalVeSupply += additionalVe;
        totalLocked += additionalAmount;
        
        covenToken.safeTransferFrom(msg.sender, address(this), additionalAmount);
        
        emit LockCreated(tokenId, msg.sender, additionalAmount, lock.endTime, additionalVe);
    }
    
    function earlyExit(uint256 tokenId) external nonReentrant returns (uint256 withdrawnAmount) {
        if (ownerOf(tokenId) != msg.sender) revert NotLockOwner();
        
        Lock storage lock = locks[tokenId];
        if (block.timestamp >= lock.endTime) revert LockExpired();
        
        _updateRewards(tokenId);
        
        uint256 remainingTime = lock.endTime - block.timestamp;
        uint256 penaltyPercent = _calculatePenalty(remainingTime);
        uint256 penaltyAmount = (lock.amount * penaltyPercent) / BASE_MULTIPLIER;
        withdrawnAmount = lock.amount - penaltyAmount;
        
        _burn(tokenId);
        
        totalVeSupply -= lock.veBalance;
        totalLocked -= lock.amount;
        lock.withdrawn = lock.amount;
        
        covenToken.safeTransfer(msg.sender, withdrawnAmount);
        
        uint256 toLockers = penaltyAmount / 2;
        if (totalVeSupply > 0 && toLockers > 0) {}
        
        emit EarlyExit(tokenId, withdrawnAmount, penaltyAmount);
    }
    
    function withdraw(uint256 tokenId) external nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert NotLockOwner();
        
        Lock storage lock = locks[tokenId];
        if (block.timestamp < lock.endTime) revert LockNotExpired();
        
        _updateRewards(tokenId);
        
        uint256 amount = lock.amount - lock.withdrawn;
        if (amount == 0) revert InsufficientBalance();
        
        _burn(tokenId);
        
        totalVeSupply -= lock.veBalance;
        totalLocked -= amount;
        lock.withdrawn = lock.amount;
        
        covenToken.safeTransfer(msg.sender, amount);
        
        emit EarlyExit(tokenId, amount, 0);
    }
    
    function addRewardToken(address token, uint256 rate) external onlyOwner {
        if (rewardRates[token] != 0) revert RewardTokenExists();
        rewardTokens.push(token);
        rewardRates[token] = rate;
        emit RewardRateUpdated(token, rate);
    }
    
    function depositRewards(address token, uint256 amount) external {
        if (rewardRates[token] == 0) revert InvalidAmount();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _updateRewardPerToken(token);
    }
    
    function claimRewards(uint256 tokenId) external nonReentrant returns (uint256[] memory) {
        if (ownerOf(tokenId) != msg.sender) revert NotLockOwner();
        
        _updateRewards(tokenId);
        
        uint256[] memory claimed = new uint256[](rewardTokens.length);
        
        for (uint i = 0; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            uint256 reward = rewards[token][tokenId];
            
            if (reward > 0) {
                rewards[token][tokenId] = 0;
                claimed[i] = reward;
                IERC20(token).safeTransfer(msg.sender, reward);
                emit RewardsClaimed(tokenId, token, reward);
            }
        }
        
        return claimed;
    }
    
    function updateTaskBoost(address user, uint256 boostPercent) external onlyOwner {
        taskBoostMultiplier[user] = boostPercent > 10000 ? 10000 : boostPercent;
        emit TaskBoostUpdated(user, taskBoostMultiplier[user]);
    }
    
    function getTotalBoost(address user, uint256 tokenId) external view returns (uint256) {
        Lock storage lock = locks[tokenId];
        if (lock.amount == 0) return BASE_MULTIPLIER;
        
        uint256 veBoost = BASE_MULTIPLIER + ((lock.veBalance * (MAX_BOOST - BASE_MULTIPLIER)) / lock.amount);
        uint256 taskBoost = BASE_MULTIPLIER + taskBoostMultiplier[user];
        
        return (veBoost * taskBoost) / BASE_MULTIPLIER;
    }
    
    function getVeBalance(uint256 tokenId) external view returns (uint256) {
        Lock storage lock = locks[tokenId];
        if (block.timestamp >= lock.endTime) return 0;
        
        uint256 remaining = lock.endTime - block.timestamp;
        uint256 totalDuration = lock.endTime - lock.startTime;
        return (lock.veBalance * remaining) / totalDuration;
    }
    
    function getUserLocks(address user) external view returns (uint256[] memory) {
        return userLocks[user];
    }
    
    function getLockInfo(uint256 tokenId) external view returns (Lock memory) {
        return locks[tokenId];
    }
    
    function pendingRewardsAll(uint256 tokenId) external view returns (address[] memory tokens, uint256[] memory amounts) {
        tokens = rewardTokens;
        amounts = new uint256[](rewardTokens.length);
        
        for (uint i = 0; i < rewardTokens.length; i++) {
            amounts[i] = _pendingRewards(rewardTokens[i], tokenId);
        }
    }
    
    function _updateRewards(uint256 tokenId) internal {
        for (uint i = 0; i < rewardTokens.length; i++) {
            _updateRewardPerToken(rewardTokens[i]);
            
            address token = rewardTokens[i];
            uint256 pending = _pendingRewards(token, tokenId);
            if (pending > 0) {
                rewards[token][tokenId] += pending;
                rewardPerTokenPaid[token][tokenId] = rewardPerTokenStored[token];
            }
        }
    }
    
    function _updateRewardPerToken(address token) internal {
        if (totalVeSupply == 0) return;
        
        uint256 timeElapsed = block.timestamp - lastUpdateTime(token);
        if (timeElapsed == 0) return;
        
        uint256 reward = rewardRates[token] * timeElapsed;
        rewardPerTokenStored[token] += (reward * 1e18) / totalVeSupply;
    }
    
    function lastUpdateTime(address token) internal view returns (uint256) {
        return block.timestamp;
    }
    
    function _pendingRewards(address token, uint256 tokenId) internal view returns (uint256) {
        Lock storage lock = locks[tokenId];
        if (lock.amount == 0) return 0;
        
        uint256 weight = lock.veBalance;
        uint256 rewardPerToken = rewardPerTokenStored[token];
        
        return (weight * (rewardPerToken - rewardPerTokenPaid[token][tokenId])) / 1e18;
    }
    
    function _calculatePenalty(uint256 remainingTime) internal pure returns (uint256) {
        if (remainingTime > 3 * 365 days) return PENALTY_75;
        if (remainingTime > 2 * 365 days) return PENALTY_50;
        if (remainingTime > 1 * 365 days) return PENALTY_25;
        return remainingTime / (365 days / 100);
    }
    
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (_ownerOf(tokenId) != address(0)) {
            _updateRewards(tokenId);
        }
        return super._update(to, tokenId, auth);
    }
}
