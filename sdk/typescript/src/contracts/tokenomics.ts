import { BaseContract } from './base';
import {
  Tokenomics,
  Stake,
  Distribution,
  EthereumAddress,
  CallOverrides,
  TransactionResult,
} from '../types';
import { EthersProvider } from '../providers';
import {
  COVENTokenABI,
  RewardDistributorABI,
  StakingPoolABI,
  ERC20ABI,
} from '../abis';

export class COVENToken extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, COVENTokenABI, provider);
  }

  async mintInflation(overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('mintInflation', [], overrides);
  }

  async burn(
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('burn', [amount], overrides);
  }

  async burnFrom(
    account: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('burnFrom', [account, amount], overrides);
  }

  async setStakingContract(
    stakingContract: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('setStakingContract', [stakingContract], overrides);
  }

  async getTokenomics(): Promise<Tokenomics> {
    const result = await this.call<any>('getTokenomics', []);
    return {
      maxSupply: result.maxSupply,
      totalMinted: result.totalMinted,
      inflationRate: result.inflationRate,
      lastMintTime: result.lastMintTime,
    };
  }
}

export class RewardDistributor extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, RewardDistributorABI, provider);
  }

  async addRewards(
    token: EthereumAddress,
    amount: bigint,
    duration: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('addRewards', [token, amount, duration], overrides);
  }

  async claimRewards(
    token: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('claimRewards', [token], overrides);
  }

  async getClaimableRewards(
    account: EthereumAddress,
    token: EthereumAddress
  ): Promise<bigint> {
    return this.call('getClaimableRewards', [account, token]);
  }

  async getDistribution(token: EthereumAddress): Promise<Distribution> {
    const result = await this.call<any>('getDistribution', [token]);
    return {
      token: result.token,
      amount: result.amount,
      startTime: result.startTime,
      endTime: result.endTime,
      claimed: result.claimed,
    };
  }
}

export class StakingPool extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, StakingPoolABI, provider);
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

  async claimRewards(overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('claimRewards', [], overrides);
  }

  async updatePool(overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('updatePool', [], overrides);
  }

  async getStake(account: EthereumAddress): Promise<Stake> {
    const result = await this.call<any>('getStake', [account]);
    return {
      amount: result.amount,
      rewardDebt: result.rewardDebt,
      lockEnd: result.lockEnd,
      multiplier: result.multiplier,
    };
  }

  async pendingRewards(account: EthereumAddress): Promise<bigint> {
    return this.call('pendingRewards', [account]);
  }

  async totalStaked(): Promise<bigint> {
    return this.call('totalStaked', []);
  }

  async getRewardToken(): Promise<EthereumAddress> {
    return this.call('getRewardToken', []);
  }

  async getStakeToken(): Promise<EthereumAddress> {
    return this.call('getStakeToken', []);
  }
}

export class ERC20 extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, ERC20ABI, provider);
  }

  async name(): Promise<string> {
    return this.call('name', []);
  }

  async symbol(): Promise<string> {
    return this.call('symbol', []);
  }

  async decimals(): Promise<number> {
    return this.call('decimals', []);
  }

  async totalSupply(): Promise<bigint> {
    return this.call('totalSupply', []);
  }

  async balanceOf(account: EthereumAddress): Promise<bigint> {
    return this.call('balanceOf', [account]);
  }

  async transfer(
    recipient: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('transfer', [recipient, amount], overrides);
  }

  async allowance(
    owner: EthereumAddress,
    spender: EthereumAddress
  ): Promise<bigint> {
    return this.call('allowance', [owner, spender]);
  }

  async approve(
    spender: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('approve', [spender, amount], overrides);
  }

  async transferFrom(
    sender: EthereumAddress,
    recipient: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('transferFrom', [sender, recipient, amount], overrides);
  }
}
