import { BaseContract } from './base';
import {
  DisputeParams,
  ResolutionOutcome,
  Juror,
  Vote,
  Evidence,
  Appeal,
  EthereumAddress,
  Bytes32,
  CallOverrides,
  TransactionResult,
} from '../types';
import { EthersProvider } from '../providers';
import {
  DisputeDAOABI,
  DisputeResolutionABI,
  DisputeJuryABI,
  DisputeVotingABI,
  DisputeEvidenceABI,
  DisputeAppealABI,
} from '../abis';

export class DisputeDAO extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, DisputeDAOABI, provider);
  }

  async updateParams(
    params: DisputeParams,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('updateParams', [params], overrides);
  }

  async getParams(): Promise<DisputeParams> {
    return this.call('getParams', []);
  }

  async withdrawTreasury(
    token: EthereumAddress,
    recipient: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('withdrawTreasury', [token, recipient, amount], overrides);
  }
}

export class DisputeResolution extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, DisputeResolutionABI, provider);
  }

  async resolveDispute(
    disputeId: bigint,
    outcome: ResolutionOutcome,
    detailsHash: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send(
      'resolveDispute',
      [disputeId, outcome, detailsHash],
      overrides
    );
  }

  async executeResolution(
    disputeId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('executeResolution', [disputeId], overrides);
  }

  async getResolution(
    disputeId: bigint
  ): Promise<{ outcome: ResolutionOutcome; detailsHash: Bytes32; executed: boolean }> {
    return this.call('getResolution', [disputeId]);
  }

  async canAppeal(disputeId: bigint): Promise<boolean> {
    return this.call('canAppeal', [disputeId]);
  }
}

export class DisputeJury extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, DisputeJuryABI, provider);
  }

  async registerJuror(
    stake: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('registerJuror', [stake], overrides);
  }

  async unregisterJuror(overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('unregisterJuror', [], overrides);
  }

  async selectJury(
    disputeId: bigint,
    jurySize: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('selectJury', [disputeId, jurySize], overrides);
  }

  async slashJuror(
    juror: EthereumAddress,
    amount: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('slashJuror', [juror, amount], overrides);
  }

  async getJuror(account: EthereumAddress): Promise<Juror> {
    const result = await this.call<any>('getJuror', [account]);
    return {
      account: result.account,
      stake: result.stake,
      selectionScore: result.selectionScore,
      active: result.active,
    };
  }

  async getJurorsForDispute(disputeId: bigint): Promise<EthereumAddress[]> {
    return this.call('getJurorsForDispute', [disputeId]);
  }
}

export class DisputeVoting extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, DisputeVotingABI, provider);
  }

  async castVote(
    disputeId: bigint,
    choice: number,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('castVote', [disputeId, choice], overrides);
  }

  async closeVoting(
    disputeId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('closeVoting', [disputeId], overrides);
  }

  async getVote(disputeId: bigint, voter: EthereumAddress): Promise<Vote> {
    const result = await this.call<any>('getVote', [disputeId, voter]);
    return {
      voter: result.voter,
      choice: result.choice,
      weight: result.weight,
      timestamp: result.timestamp,
    };
  }

  async getVoteTally(disputeId: bigint): Promise<[bigint, bigint, bigint]> {
    return this.call('getVoteTally', [disputeId]);
  }

  async hasVoted(disputeId: bigint, voter: EthereumAddress): Promise<boolean> {
    return this.call('hasVoted', [disputeId, voter]);
  }

  async getVotingEndTime(disputeId: bigint): Promise<bigint> {
    return this.call('getVotingEndTime', [disputeId]);
  }
}

export class DisputeEvidence extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, DisputeEvidenceABI, provider);
  }

  async submitEvidence(
    disputeId: bigint,
    evidenceHash: Bytes32,
    metadataHash: Bytes32,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send(
      'submitEvidence',
      [disputeId, evidenceHash, metadataHash],
      overrides
    );
  }

  async getEvidence(evidenceId: bigint): Promise<Evidence> {
    const result = await this.call<any>('getEvidence', [evidenceId]);
    return {
      evidenceId: result.evidenceId,
      disputeId: result.disputeId,
      submitter: result.submitter,
      evidenceHash: result.evidenceHash,
      metadataHash: result.metadataHash,
      submittedAt: result.submittedAt,
    };
  }

  async getEvidenceByDispute(disputeId: bigint): Promise<bigint[]> {
    return this.call('getEvidenceByDispute', [disputeId]);
  }

  async getEvidencePeriodEnd(disputeId: bigint): Promise<bigint> {
    return this.call('getEvidencePeriodEnd', [disputeId]);
  }
}

export class DisputeAppeal extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, DisputeAppealABI, provider);
  }

  async fileAppeal(
    disputeId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('fileAppeal', [disputeId], overrides);
  }

  async resolveAppeal(
    appealId: bigint,
    status: number,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('resolveAppeal', [appealId, status], overrides);
  }

  async getAppeal(appealId: bigint): Promise<Appeal> {
    const result = await this.call<any>('getAppeal', [appealId]);
    return {
      appealId: result.appealId,
      disputeId: result.disputeId,
      appellant: result.appellant,
      bond: result.bond,
      appealedAt: result.appealedAt,
      status: result.status,
    };
  }

  async getAppealsByDispute(disputeId: bigint): Promise<bigint[]> {
    return this.call('getAppealsByDispute', [disputeId]);
  }

  async getAppealPeriod(): Promise<bigint> {
    return this.call('getAppealPeriod', []);
  }

  async getAppealBond(): Promise<bigint> {
    return this.call('getAppealBond', []);
  }
}
