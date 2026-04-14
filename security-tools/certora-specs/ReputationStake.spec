// ReputationStake.spec
// Formal verification specification for ReputationStake contract

methods {
    function stake(uint256 amount, uint256 lockDuration) external;
    function unstake(uint256 amount) external;
    function slash(address account, uint256 amount, bytes32 reason) external;
    function getStakeInfo(address account) external returns (ReputationStake.StakeInfo memory) envfree;
    function totalStaked() external returns (uint256) envfree;
    function getStakeToken() external returns (address) envfree;
    function owner() external returns (address) envfree;
}

// ============================================
// GHOST VARIABLES FOR TRACKING
// ============================================

ghost sumAllStakes() returns uint256 {
    init_state axiom sumAllStakes() == 0;
}

ghost mapping(address => uint256) ghost_stakeAmount;
ghost mapping(address => uint256) ghost_unlockTime;

// ============================================
// HOOKS
// ============================================

hook Sstore stakes[KEY address user].amount uint256 newAmount (uint256 oldAmount) {
    havoc sumAllStakes assuming sumAllStakes@new() == sumAllStakes@old() + newAmount - oldAmount;
    ghost_stakeAmount[user] = newAmount;
}

hook Sstore stakes[KEY address user].unlockTime uint256 newUnlock (uint256 oldUnlock) {
    ghost_unlockTime[user] = newUnlock;
}

// ============================================
// INVARIANTS
// ============================================

// INVARIANT: Sum of all user stakes equals totalStaked
invariant totalStakedEqualsSum()
    totalStaked() == sumAllStakes()
    filtered { f -> f.selector != sig:initialize().selector }
    {
        preserved {
            require sumAllStakes() >= 0;
        }
    }

// INVARIANT: Total staked is non-negative
invariant totalStakedNonNegative()
    totalStaked() >= 0;

// INVARIANT: Individual stake amount is non-negative
invariant individualStakeNonNegative(address user)
    getStakeInfo(user).amount >= 0;

// INVARIANT: Unlock time is in the future if stake is locked
invariant unlockTimeInFuture(address user, env e)
    getStakeInfo(user).locked => getStakeInfo(user).unlockTime >= e.block.timestamp;

// ============================================
// RULES
// ============================================

// RULE: Staking increases total staked
rule stakeIncreasesTotal(address user, uint256 amount, uint256 lockDuration, env e) {
    require e.msg.sender == user;
    require amount > 0;
    
    uint256 totalBefore = totalStaked();
    uint256 userStakeBefore = getStakeInfo(user).amount;
    
    stake(e, amount, lockDuration);
    
    uint256 totalAfter = totalStaked();
    uint256 userStakeAfter = getStakeInfo(user).amount;
    
    assert totalAfter == totalBefore + amount,
        "Total staked must increase by stake amount";
    assert userStakeAfter == userStakeBefore + amount,
        "User stake must increase by stake amount";
}

// RULE: Unstaking decreases total staked
rule unstakeDecreasesTotal(address user, uint256 amount, env e) {
    require e.msg.sender == user;
    
    uint256 totalBefore = totalStaked();
    uint256 userStakeBefore = getStakeInfo(user).amount;
    uint256 unlockTime = getStakeInfo(user).unlockTime;
    
    require amount <= userStakeBefore;
    require e.block.timestamp >= unlockTime;
    
    unstake@withrevert(e, amount);
    bool reverted = lastReverted;
    
    if (!reverted) {
        assert totalStaked() == totalBefore - amount,
            "Total staked must decrease by unstake amount";
        assert getStakeInfo(user).amount == userStakeBefore - amount,
            "User stake must decrease by unstake amount";
    }
}

// RULE: Cannot unstake before unlock time
rule cannotUnstakeBeforeUnlock(address user, uint256 amount, env e) {
    require e.msg.sender == user;
    require getStakeInfo(user).locked;
    require e.block.timestamp < getStakeInfo(user).unlockTime;
    require amount > 0;
    
    unstake@withrevert(e, amount);
    
    assert lastReverted,
        "Should not be able to unstake before unlock time";
}

// RULE: Slashing reduces stake and total
rule slashReducesStake(address user, address slasher, uint256 amount, bytes32 reason, env e) {
    require e.msg.sender == slasher;
    require slasher == owner();
    
    uint256 userStakeBefore = getStakeInfo(user).amount;
    uint256 totalBefore = totalStaked();
    
    require amount <= userStakeBefore;
    
    slash(e, user, amount, reason);
    
    assert getStakeInfo(user).amount == userStakeBefore - amount,
        "User stake must decrease by slash amount";
    assert totalStaked() == totalBefore - amount,
        "Total staked must decrease by slash amount";
}

// RULE: Only owner can slash
rule onlyOwnerCanSlash(address caller, address user, uint256 amount, bytes32 reason, env e) {
    require e.msg.sender == caller;
    require caller != owner();
    
    slash@withrevert(e, user, amount, reason);
    
    assert lastReverted,
        "Only owner should be able to slash";
}

// RULE: Cannot stake zero amount
rule cannotStakeZero(env e) {
    stake@withrevert(e, 0, 0);
    assert lastReverted,
        "Should not be able to stake zero amount";
}

// RULE: Cannot unstake more than staked
rule cannotUnstakeMoreThanStaked(address user, uint256 amount, env e) {
    require e.msg.sender == user;
    require amount > getStakeInfo(user).amount;
    
    unstake@withrevert(e, amount);
    assert lastReverted,
        "Should not be able to unstake more than staked";
}

// RULE: Staking updates unlock time correctly
rule stakeUpdatesUnlockTime(address user, uint256 amount, uint256 lockDuration, env e) {
    require e.msg.sender == user;
    require amount > 0;
    
    uint256 oldUnlockTime = getStakeInfo(user).unlockTime;
    uint256 expectedNewUnlock = e.block.timestamp + lockDuration;
    
    stake(e, amount, lockDuration);
    
    uint256 newUnlockTime = getStakeInfo(user).unlockTime;
    
    if (expectedNewUnlock > oldUnlockTime) {
        assert newUnlockTime == expectedNewUnlock,
            "Unlock time should be extended to new duration";
    } else {
        assert newUnlockTime == oldUnlockTime,
            "Unlock time should remain unchanged if new lock is shorter";
    }
}
