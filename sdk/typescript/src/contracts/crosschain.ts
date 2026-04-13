import { BaseContract } from './base';
import {
  BridgeMessage,
  RelayJob,
  VerifiedMessage,
  EthereumAddress,
  CallOverrides,
  TransactionResult,
} from '../types';
import { EthersProvider } from '../providers';
import {
  CovenantBridgeABI,
  MessageRelayerABI,
  MessageVerifierABI,
} from '../abis';

export class CovenantBridge extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantBridgeABI, provider);
  }

  async sendMessage(
    targetChain: number,
    payload: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('sendMessage', [targetChain, payload], overrides);
  }

  async receiveMessage(
    sourceChain: number,
    payload: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('receiveMessage', [sourceChain, payload], overrides);
  }

  async addSupportedChain(
    chainId: number,
    adapter: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('addSupportedChain', [chainId, adapter], overrides);
  }

  async getMessageStatus(messageId: bigint): Promise<number> {
    return this.call('getMessageStatus', [messageId]);
  }
}

export class MessageRelayer extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, MessageRelayerABI, provider);
  }

  async requestRelay(
    targetChain: number,
    payload: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('requestRelay', [targetChain, payload], overrides);
  }

  async completeRelay(
    messageId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('completeRelay', [messageId], overrides);
  }

  async claimFee(
    messageId: bigint,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('claimFee', [messageId], overrides);
  }

  async getRelayJob(messageId: bigint): Promise<RelayJob> {
    const result = await this.call<any>('getRelayJob', [messageId]);
    return {
      messageId: result.messageId,
      targetChain: result.targetChain,
      payload: result.payload,
      fee: result.fee,
      relayer: result.relayer,
      completed: result.completed,
    };
  }
}

export class MessageVerifier extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, MessageVerifierABI, provider);
  }

  async verifyMessage(
    messageHash: string,
    signature: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('verifyMessage', [messageHash, signature], overrides);
  }

  async authorizeSigner(
    signer: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('authorizeSigner', [signer], overrides);
  }

  async revokeSigner(
    signer: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('revokeSigner', [signer], overrides);
  }

  async isAuthorizedSigner(signer: EthereumAddress): Promise<boolean> {
    return this.call('isAuthorizedSigner', [signer]);
  }

  async getVerification(messageHash: string): Promise<VerifiedMessage> {
    const result = await this.call<any>('getVerification', [messageHash]);
    return {
      messageHash: result.messageHash,
      signature: result.signature,
      signer: result.signer,
      verifiedAt: result.verifiedAt,
      valid: result.valid,
    };
  }
}
