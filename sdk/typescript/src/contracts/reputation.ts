import { BaseContract } from './base';
import {
  StakeInfo,
  OracleData,
  Boost,
  ReputationSnapshot,
  EthereumAddress,
  Bytes32,
  CallOverrides,
  TransactionResult,
} from '../types';
import { EthersProvider } from '../providers';
import {
  ReputationStakeABI,
  ReputationOracleABI,
  ReputationBoostABI,
  ReputationDecayABI,
  ReputationHistoryABI,
} from '../abis';

export class ReputationStake extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, ReputationStakeABI, provider);
  }

  async stake(
    amount: bigint,
    lockDuration: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('stake', [amount, lockDuration], overrides);
  }

  async unstake(
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('unstake', [amount], overrides);
  }

  async slash(
    account: EthereumAddress,
    amount: bigint,
    reason: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('slash', [account, amount, reason], overrides);
  }

  async getStakeInfo(account: EthereumAddress): Promise<StakeInfo> {
    const result = await this.call<any>('getStakeInfo', [account]);
    return {
      amount: result.amount,
      stakedAt: result.stakedAt,
      unlockTime: result.unlockTime,
      locked: result.locked,
    };
  }

  async totalStaked(): Promise<bigint> {
    return this.call('totalStaked', []);
  }

  async getStakeToken(): Promise<EthereumAddress> {
    return this.call('getStakeToken', []);
  }
}

export class ReputationOracle extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, ReputationOracleABI, provider);
  }

  async submitData(
    dataHash: Bytes32,
    confidence: number,
    proof: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('submitData', [dataHash, confidence, proof], overrides);
  }

  async getData(dataHash: Bytes32): Promise<OracleData> {
    const result = await this.call<any>('getData', [dataHash]);
    return {
      dataHash: result.dataHash,
      timestamp: result.timestamp,
      confidence: result.confidence,
      source: result.source,
    };
  }

  async authorizeOracle(
    oracle: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('authorizeOracle', [oracle], overrides);
  }

  async revokeOracle(
    oracle: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('revokeOracle', [oracle], overrides);
  }

  async isAuthorized(oracle: EthereumAddress): Promise<boolean> {
    return this.call('isAuthorized', [oracle]);
  }
}

export class ReputationBoost extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, ReputationBoostABI, provider);
  }

  async grantBoost(
    account: EthereumAddress,
    amount: bigint,
    reason: Bytes32,
    duration: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send(
      'grantBoost',
      [account, amount, reason, duration],
      overrides
    );
  }

  async revokeBoost(
    account: EthereumAddress,
    boostId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('revokeBoost', [account, boostId], overrides);
  }

  async getActiveBoosts(account: EthereumAddress): Promise<Boost[]> {
    const results = await this.call<any[]>('getActiveBoosts', [account]);
    return results.map((result) => ({
      amount: result.amount,
      expiresAt: result.expiresAt,
      reason: result.reason,
      active: result.active,
    }));
  }

  async getTotalBoost(account: EthereumAddress): Promise<bigint> {
    return this.call('getTotalBoost', [account]);
  }

  async isBoostActive(
    account: EthereumAddress,
    boostId: bigint
  ): Promise<boolean> {
    return this.call('isBoostActive', [account, boostId]);
  }
}

export class ReputationDecay extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, ReputationDecayABI, provider);
  }

  async applyDecay(
    account: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('applyDecay', [account], overrides);
  }

  async calculateDecay(account: EthereumAddress): Promise<bigint> {
    return this.call('calculateDecay', [account]);
  }

  async setDecayRate(
    rate: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('setDecayRate', [rate], overrides);
  }

  async setDecayInterval(
    interval: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('setDecayInterval', [interval], overrides);
  }

  async getDecayRate(): Promise<bigint> {
    return this.call('getDecayRate', []);
  }

  async getDecayInterval(): Promise<bigint> {
    return this.call('getDecayInterval', []);
  }

  async getLastDecayTime(account: EthereumAddress): Promise<bigint> {
    return this.call('getLastDecayTime', [account]);
  }
}

export class ReputationHistory extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, ReputationHistoryABI, provider);
  }

  async recordSnapshot(
    account: EthereumAddress,
    score: bigint,
    context: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('recordSnapshot', [account, score, context], overrides);
  }

  async getHistory(account: EthereumAddress): Promise<ReputationSnapshot[]> {
    const results = await this.call<any[]>('getHistory', [account]);
    return results.map((result) => ({
      timestamp: result.timestamp,
      score: result.score,
      context: result.context,
    }));
  }

  async getHistoryRange(
    account: EthereumAddress,
    start: bigint,
    end: bigint
  ): Promise<ReputationSnapshot[]> {
    const results = await this.call<any[]>('getHistoryRange', [
      account,
      start,
      end,
    ]);
    return results.map((result) => ({
      timestamp: result.timestamp,
      score: result.score,
      context: result.context,
    }));
  }

  async getLatestSnapshot(
    account: EthereumAddress
  ): Promise<ReputationSnapshot> {
    const result = await this.call<any>('getLatestSnapshot', [account]);
    return {
      timestamp: result.timestamp,
      score: result.score,
      context: result.context,
    };
  }

  async getScoreAtTime(
    account: EthereumAddress,
    timestamp: bigint
  ): Promise<bigint> {
    return this.call('getScoreAtTime', [account, timestamp]);
  }
}
