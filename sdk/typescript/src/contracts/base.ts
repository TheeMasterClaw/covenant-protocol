import { ethers } from 'ethers';
import { EthersProvider } from '../providers';
import {
  EthereumAddress,
  Bytes32,
  CallOverrides,
  TransactionResult,
  CovenantSDKError,
} from '../types';
import { handleContractCall, handleTransaction } from '../utils';

export abstract class BaseContract {
  protected contract: ethers.Contract;
  protected provider: EthersProvider;

  constructor(
    address: EthereumAddress,
    abi: any,
    provider: EthersProvider
  ) {
    this.provider = provider;
    this.contract = provider.getContract(address, abi);
  }

  protected async call<T>(
    method: string,
    args: any[] = [],
    overrides?: CallOverrides
  ): Promise<T> {
    return handleContractCall(
      () => this.contract[method](...args, overrides || {}),
      method
    );
  }

  protected async send(
    method: string,
    args: any[] = [],
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    const tx = await handleTransaction(
      () => this.contract[method](...args, { value: overrides?.value || 0 }),
      method
    );
    return {
      hash: tx.hash,
      wait: async () => {
        const receipt = await tx.wait();
        return {
          blockHash: receipt.blockHash,
          blockNumber: BigInt(receipt.blockNumber),
          contractAddress: receipt.contractAddress,
          cumulativeGasUsed: receipt.cumulativeGasUsed,
          effectiveGasPrice: receipt.gasPrice,
          from: receipt.from,
          gasUsed: receipt.gasUsed,
          logs: receipt.logs,
          status: receipt.status === 1 ? 'success' : 'reverted',
          to: receipt.to,
          transactionHash: receipt.hash,
          transactionIndex: receipt.index,
        };
      },
    };
  }

  getAddress(): EthereumAddress {
    return this.contract.target as EthereumAddress;
  }

  on(event: string, listener: (...args: any[]) => void): void {
    this.contract.on(event, listener);
  }

  off(event: string, listener?: (...args: any[]) => void): void {
    this.contract.off(event, listener);
  }

  async queryFilter(
    event: string,
    fromBlock?: number,
    toBlock?: number
  ): Promise<any[]> {
    return this.contract.queryFilter(event, fromBlock, toBlock);
  }
}
