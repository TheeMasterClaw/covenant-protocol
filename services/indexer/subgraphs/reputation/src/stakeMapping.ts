import { BigInt } from "@graphprotocol/graph-ts";
import {
  Staked,
  Unstaked,
  RewardsClaimed,
  StakeLocked,
  StakeUnlocked,
} from "../generated/ReputationStake/ReputationStake";
import {
  ReputationScore,
  ReputationStake,
  ReputationHistory,
  ReputationStakePool,
} from "../generated/schema";

function getOrCreateReputationScore(user: string): ReputationScore {
  let score = ReputationScore.load(user);
  if (!score) {
    score = new ReputationScore(user);
    score.user = new BigInt(0) as any;
    score.score = BigInt.fromI32(100);
    score.tier = "NOVICE";
    score.stakedAmount = BigInt.zero();
    score.lockedAmount = BigInt.zero();
    score.createdAt = BigInt.zero();
    score.updatedAt = BigInt.zero();
    score.decayFactor = BigInt.fromI32(1);
    score.boostMultiplier = BigInt.fromI32(1);
    score.consecutiveMonths = BigInt.zero();
    score.totalTasksCompleted = BigInt.zero();
    score.totalTasksCreated = BigInt.zero();
    score.totalDisputesWon = BigInt.zero();
    score.totalDisputesLost = BigInt.zero();
    score.averageRating = BigInt.zero();
    score.chainId = BigInt.fromI32(1);
    score.blockNumber = BigInt.zero();
    score.transactionHash = new BigInt(0) as any;
    score.save();
  }
  return score;
}

function getOrCreateStakePool(): ReputationStakePool {
  let pool = ReputationStakePool.load("pool");
  if (!pool) {
    pool = new ReputationStakePool("pool");
    pool.totalStaked = BigInt.zero();
    pool.rewardRate = BigInt.zero();
    pool.lastUpdateTime = BigInt.zero();
    pool.rewardPerTokenStored = BigInt.zero();
    pool.totalRewardsDistributed = BigInt.zero();
    pool.save();
  }
  return pool;
}

function recordHistory(user: string, oldScore: BigInt, newScore: BigInt, reason: string, event: any): void {
  let history = new ReputationHistory(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString()
  );
  history.user = new BigInt(0) as any;
  history.oldScore = oldScore;
  history.newScore = newScore;
  history.change = newScore.minus(oldScore);
  history.reason = reason;
  history.timestamp = event.block.timestamp;
  history.blockNumber = event.block.number;
  history.transactionHash = event.transaction.hash;
  history.save();
}

export function handleStaked(event: Staked): void {
  let user = event.params.user.toHex();
  let score = getOrCreateReputationScore(user);
  let oldScore = score.score;
  
  score.stakedAmount = score.stakedAmount.plus(event.params.amount);
  score.score = score.score.plus(event.params.amount.div(BigInt.fromI32(1000)));
  score.updatedAt = event.block.timestamp;
  score.blockNumber = event.block.number;
  score.transactionHash = event.transaction.hash;
  score.save();

  let stake = new ReputationStake(
    event.transaction.hash.toHex() + "-" + event.logIndex.toString()
  );
  stake.user = event.params.user;
  stake.amount = event.params.amount;
  stake.stakedAt = event.block.timestamp;
  stake.unlockTime = event.params.unlockTime;
  stake.withdrawn = false;
  stake.rewardsClaimed = BigInt.zero();
  stake.blockNumber = event.block.number;
  stake.save();

  let pool = getOrCreateStakePool();
  pool.totalStaked = pool.totalStaked.plus(event.params.amount);
  pool.lastUpdateTime = event.block.timestamp;
  pool.save();

  recordHistory(user, oldScore, score.score, "STAKE", event);
}

export function handleUnstaked(event: Unstaked): void {
  let user = event.params.user.toHex();
  let score = getOrCreateReputationScore(user);
  let oldScore = score.score;

  score.stakedAmount = score.stakedAmount.minus(event.params.amount);
  score.score = score.score.minus(event.params.amount.div(BigInt.fromI32(1000)));
  score.updatedAt = event.block.timestamp;
  score.blockNumber = event.block.number;
  score.save();

  let pool = getOrCreateStakePool();
  pool.totalStaked = pool.totalStaked.minus(event.params.amount);
  pool.lastUpdateTime = event.block.timestamp;
  pool.save();

  recordHistory(user, oldScore, score.score, "UNSTAKE", event);
}

export function handleRewardsClaimed(event: RewardsClaimed): void {
  let user = event.params.user.toHex();
  let score = getOrCreateReputationScore(user);
  score.score = score.score.plus(event.params.amount.div(BigInt.fromI32(10000)));
  score.updatedAt = event.block.timestamp;
  score.save();

  let pool = getOrCreateStakePool();
  pool.totalRewardsDistributed = pool.totalRewardsDistributed.plus(event.params.amount);
  pool.save();
}

export function handleStakeLocked(event: StakeLocked): void {
  let user = event.params.user.toHex();
  let score = getOrCreateReputationScore(user);
  score.lockedAmount = score.lockedAmount.plus(event.params.amount);
  score.updatedAt = event.block.timestamp;
  score.save();
}

export function handleStakeUnlocked(event: StakeUnlocked): void {
  let user = event.params.user.toHex();
  let score = getOrCreateReputationScore(user);
  score.lockedAmount = score.lockedAmount.minus(event.params.amount);
  score.updatedAt = event.block.timestamp;
  score.save();
}
