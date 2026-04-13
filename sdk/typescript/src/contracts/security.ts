import { BaseContract } from './base';
import {
  Transaction,
  ZKProof,
  EthereumAddress,
  Bytes32,
  CallOverrides,
  TransactionResult,
} from '../types';
import { EthersProvider } from '../providers';
import { CovenantMultiSigABI, ZKVerifierABI } from '../abis';

export class CovenantMultiSig extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantMultiSigABI, provider);
  }

  async submitTransaction(
    to: EthereumAddress,
    value: bigint,
    data: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('submitTransaction', [to, value, data], overrides);
  }

  async confirmTransaction(
    txIndex: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('confirmTransaction', [txIndex], overrides);
  }

  async revokeConfirmation(
    txIndex: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('revokeConfirmation', [txIndex], overrides);
  }

  async executeTransaction(
    txIndex: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('executeTransaction', [txIndex], overrides);
  }

  async addSigner(
    signer: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('addSigner', [signer], overrides);
  }

  async removeSigner(
    signer: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('removeSigner', [signer], overrides);
  }

  async changeRequiredConfirmations(
    required: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('changeRequiredConfirmations', [required], overrides);
  }

  async isSigner(account: EthereumAddress): Promise<boolean> {
    return this.call('isSigner', [account]);
  }

  async getTransaction(txIndex: bigint): Promise<Transaction> {
    const result = await this.call<any>('getTransaction', [txIndex]);
    return {
      to: result.to,
      value: result.value,
      data: result.data,
      executed: result.executed,
      confirmationCount: result.confirmationCount,
    };
  }

  async getTransactionCount(): Promise<bigint> {
    return this.call('getTransactionCount', []);
  }
}

export class ZKVerifier extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, ZKVerifierABI, provider);
  }

  async verifyProof(
    circuitId: Bytes32,
    publicInputs: bigint[],
    proof: ZKProof,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    const proofArg = {
      a: proof.a.map((v) => v.toString()),
      b: proof.b.map((inner) => inner.map((v) => v.toString())),
      c: proof.c.map((v) => v.toString()),
    };
    return this.send(
      'verifyProof',
      [circuitId, publicInputs.map((v) => v.toString()), proofArg],
      overrides
    );
  }

  async setVerifier(
    circuitId: Bytes32,
    verifier: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('setVerifier', [circuitId, verifier], overrides);
  }

  async getVerifier(circuitId: Bytes32): Promise<EthereumAddress> {
    return this.call('getVerifier', [circuitId]);
  }

  async hashProof(proof: ZKProof): Promise<Bytes32> {
    const proofArg = {
      a: proof.a.map((v) => v.toString()),
      b: proof.b.map((inner) => inner.map((v) => v.toString())),
      c: proof.c.map((v) => v.toString()),
    };
    return this.call('hashProof', [proofArg]);
  }
}
