import { ethers } from 'ethers';
import {
  createPublicClient,
  createWalletClient,
  http,
  PublicClient,
  WalletClient,
  custom,
  Account,
  Chain,
} from 'viem';
import { SdkConfig, ProviderType, CovenantSDKError, ValidationError } from '../types';

export interface IProvider {
  getAddress(): Promise<string>;
  getBalance(address: string): Promise<bigint>;
  getChainId(): Promise<number>;
  getBlockNumber(): Promise<bigint>;
  signMessage(message: string): Promise<string>;
}

export class EthersProvider implements IProvider {
  public readonly provider: ethers.JsonRpcProvider;
  public readonly signer?: ethers.JsonRpcSigner | ethers.Wallet;

  constructor(config: SdkConfig) {
    this.provider = new ethers.JsonRpcProvider(config.rpcUrl);
    if (config.privateKey) {
      this.signer = new ethers.Wallet(config.privateKey, this.provider);
    }
  }

  async getAddress(): Promise<string> {
    if (!this.signer) {
      throw new ValidationError('No signer configured. Provide a private key.');
    }
    return await this.signer.getAddress();
  }

  async getBalance(address: string): Promise<bigint> {
    return (await this.provider.getBalance(address)).toBigInt();
  }

  async getChainId(): Promise<number> {
    return Number((await this.provider.getNetwork()).chainId);
  }

  async getBlockNumber(): Promise<bigint> {
    return BigInt(await this.provider.getBlockNumber());
  }

  async signMessage(message: string): Promise<string> {
    if (!this.signer) {
      throw new ValidationError('No signer configured. Provide a private key.');
    }
    return await this.signer.signMessage(message);
  }

  getContract(address: string, abi: any): ethers.Contract {
    if (this.signer) {
      return new ethers.Contract(address, abi, this.signer);
    }
    return new ethers.Contract(address, abi, this.provider);
  }
}

export class ViemProvider implements IProvider {
  public readonly publicClient: PublicClient;
  public readonly walletClient?: WalletClient;
  private account?: Account;

  constructor(config: SdkConfig) {
    const chain: Chain = {
      id: config.chainId,
      name: `Chain ${config.chainId}`,
      nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 },
      rpcUrls: { default: { http: [config.rpcUrl] }, public: { http: [config.rpcUrl] } },
    } as Chain;

    this.publicClient = createPublicClient({ chain, transport: http(config.rpcUrl) });

    if (config.privateKey) {
      this.account = config.privateKey as Account;
      this.walletClient = createWalletClient({
        chain,
        transport: http(config.rpcUrl),
        account: this.account,
      });
    }
  }

  async getAddress(): Promise<string> {
    if (!this.walletClient || !this.account) {
      throw new ValidationError('No wallet client configured. Provide a private key.');
    }
    return this.account.address;
  }

  async getBalance(address: string): Promise<bigint> {
    return await this.publicClient.getBalance({ address: address as `0x${string}` });
  }

  async getChainId(): Promise<number> {
    return this.publicClient.chain?.id ?? 0;
  }

  async getBlockNumber(): Promise<bigint> {
    return await this.publicClient.getBlockNumber();
  }

  async signMessage(_message: string): Promise<string> {
    if (!this.walletClient || !this.account) {
      throw new ValidationError('No wallet client configured. Provide a private key.');
    }
    throw new CovenantSDKError('signMessage not implemented for viem provider', 'NOT_IMPLEMENTED');
  }
}

export function createProvider(config: SdkConfig, type: ProviderType = 'ethers'): EthersProvider | ViemProvider {
  switch (type) {
    case 'ethers':
      return new EthersProvider(config);
    case 'viem':
      return new ViemProvider(config);
    default:
      throw new ValidationError(`Unknown provider type: ${type}`);
  }
}
