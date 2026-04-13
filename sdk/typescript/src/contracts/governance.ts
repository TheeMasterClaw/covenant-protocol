import { BaseContract } from './base';
import {
  Proposal,
  Operation,
  EthereumAddress,
  Bytes32,
  CallOverrides,
  TransactionResult,
} from '../types';
import { EthersProvider } from '../providers';
import {
  CovenantGovernorABI,
  CovenantTimelockABI,
  CovenantTokenABI,
  CovenantTreasuryABI,
} from '../abis';

export class CovenantGovernor extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantGovernorABI, provider);
  }

  async propose(
    target: EthereumAddress,
    callData: string,
    description: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('propose', [target, callData, description], overrides);
  }

  async castVote(
    proposalId: bigint,
    support: number,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('castVote', [proposalId, support], overrides);
  }

  async execute(
    proposalId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('execute', [proposalId], overrides);
  }

  async cancel(
    proposalId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('cancel', [proposalId], overrides);
  }

  async getProposal(proposalId: bigint): Promise<Proposal> {
    const result = await this.call<any>('getProposal', [proposalId]);
    return {
      id: result.id,
      proposer: result.proposer,
      description: result.description,
      callData: result.callData,
      target: result.target,
      forVotes: result.forVotes,
      againstVotes: result.againstVotes,
      abstainVotes: result.abstainVotes,
      startTime: result.startTime,
      endTime: result.endTime,
      executed: result.executed,
      canceled: result.canceled,
    };
  }

  async getVotes(account: EthereumAddress): Promise<bigint> {
    return this.call('getVotes', [account]);
  }

  async quorum(): Promise<bigint> {
    return this.call('quorum', []);
  }

  async votingDelay(): Promise<bigint> {
    return this.call('votingDelay', []);
  }

  async votingPeriod(): Promise<bigint> {
    return this.call('votingPeriod', []);
  }
}

export class CovenantTimelock extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantTimelockABI, provider);
  }

  async schedule(
    target: EthereumAddress,
    value: bigint,
    data: string,
    delay: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('schedule', [target, value, data, delay], overrides);
  }

  async execute(
    target: EthereumAddress,
    value: bigint,
    data: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('execute', [target, value, data], overrides);
  }

  async cancel(
    operationId: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('cancel', [operationId], overrides);
  }

  async setDelay(
    newDelay: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('setDelay', [newDelay], overrides);
  }

  async getOperation(operationId: Bytes32): Promise<Operation> {
    const result = await this.call<any>('getOperation', [operationId]);
    return {
      target: result.target,
      value: result.value,
      data: result.data,
      scheduledAt: result.scheduledAt,
      delay: result.delay,
      executed: result.executed,
    };
  }

  async isOperationReady(operationId: Bytes32): Promise<boolean> {
    return this.call('isOperationReady', [operationId]);
  }

  async getMinDelay(): Promise<bigint> {
    return this.call('getMinDelay', []);
  }
}

export class CovenantToken extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantTokenABI, provider);
  }

  async mint(
    to: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('mint', [to, amount], overrides);
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

  async setMinter(
    minter: EthereumAddress,
    allowed: boolean,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('setMinter', [minter, allowed], overrides);
  }

  async maxSupply(): Promise<bigint> {
    return this.call('maxSupply', []);
  }
}

export class CovenantTreasury extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantTreasuryABI, provider);
  }

  async deposit(
    token: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('deposit', [token, amount], overrides);
  }

  async withdraw(
    token: EthereumAddress,
    recipient: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('withdraw', [token, recipient, amount], overrides);
  }

  async allocateBudget(
    recipient: EthereumAddress,
    token: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('allocateBudget', [recipient, token, amount], overrides);
  }

  async getBalance(token: EthereumAddress): Promise<bigint> {
    return this.call('getBalance', [token]);
  }

  async getBudget(
    recipient: EthereumAddress,
    token: EthereumAddress
  ): Promise<bigint> {
    return this.call('getBudget', [recipient, token]);
  }
}
