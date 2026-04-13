import { BaseContract } from './base';
import {
  CovenantState,
  EthereumAddress,
  Bytes32,
  CallOverrides,
  TransactionResult,
} from '../types';
import { EthersProvider } from '../providers';
import {
  CovenantFactoryABI,
  CovenantRegistryABI,
  CovenantImplementationABI,
  CovenantProxyABI,
  CovenantEventsABI,
} from '../abis';

export class CovenantFactory extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantFactoryABI, provider);
  }

  async createCovenant(
    salt: Bytes32,
    initData: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('createCovenant', [salt, initData], overrides);
  }

  async predictCovenantAddress(salt: Bytes32, initData: string): Promise<EthereumAddress> {
    return this.call('predictCovenantAddress', [salt, initData]);
  }

  async implementation(): Promise<EthereumAddress> {
    return this.call('implementation', []);
  }

  async registry(): Promise<EthereumAddress> {
    return this.call('registry', []);
  }

  async setImplementation(
    newImplementation: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('setImplementation', [newImplementation], overrides);
  }

  async setRegistry(
    newRegistry: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('setRegistry', [newRegistry], overrides);
  }
}

export class CovenantRegistry extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantRegistryABI, provider);
  }

  async register(
    proxy: EthereumAddress,
    creator: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult & { covenantId: bigint }> {
    const tx = await this.send('register', [proxy, creator], overrides);
    return {
      ...tx,
      covenantId: BigInt(0),
    };
  }

  async deregister(covenantId: bigint, overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('deregister', [covenantId], overrides);
  }

  async getCovenant(covenantId: bigint): Promise<EthereumAddress> {
    return this.call('getCovenant', [covenantId]);
  }

  async getCovenantId(proxy: EthereumAddress): Promise<bigint> {
    return this.call('getCovenantId', [proxy]);
  }

  async getCovenantsByCreator(creator: EthereumAddress): Promise<bigint[]> {
    return this.call('getCovenantsByCreator', [creator]);
  }

  async totalCovenants(): Promise<bigint> {
    return this.call('totalCovenants', []);
  }

  async factory(): Promise<EthereumAddress> {
    return this.call('factory', []);
  }
}

export class CovenantImplementation extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantImplementationABI, provider);
  }

  async initialize(
    creator: EthereumAddress,
    covenantId: bigint,
    params: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('initialize', [creator, covenantId, params], overrides);
  }

  async activate(overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('activate', [], overrides);
  }

  async pause(overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('pause', [], overrides);
  }

  async resolve(overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('resolve', [], overrides);
  }

  async terminate(overrides?: CallOverrides): Promise<TransactionResult> {
    return this.send('terminate', [], overrides);
  }

  async state(): Promise<CovenantState> {
    return this.call('state', []);
  }

  async creator(): Promise<EthereumAddress> {
    return this.call('creator', []);
  }

  async covenantId(): Promise<bigint> {
    return this.call('covenantId', []);
  }
}

export class CovenantProxy extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantProxyABI, provider);
  }

  async upgradeToAndCall(
    newImplementation: EthereumAddress,
    data: string,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('upgradeToAndCall', [newImplementation, data], overrides);
  }

  async implementation(): Promise<EthereumAddress> {
    return this.call('implementation', []);
  }

  async admin(): Promise<EthereumAddress> {
    return this.call('admin', []);
  }

  async changeAdmin(
    newAdmin: EthereumAddress,
    overrides?: CallOverrides
  ): Promise<TransactionResult> {
    return this.send('changeAdmin', [newAdmin], overrides);
  }
}

export class CovenantEvents extends BaseContract {
  constructor(address: EthereumAddress, provider: EthersProvider) {
    super(address, CovenantEventsABI, provider);
  }
}
