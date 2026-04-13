import { ethers } from 'ethers';
import { SdkConfig, ContractAddresses, EthereumAddress } from './types';
import { EthersProvider, createProvider } from './providers';
import { validateAddress } from './utils';
import {
  CovenantFactory,
  CovenantRegistry,
  CovenantImplementation,
  CovenantProxy,
  CovenantEvents,
  TaskMarket,
  TaskAuction,
  TaskEscrow,
  TaskReview,
  TaskDispute,
  DisputeDAO,
  DisputeResolution,
  DisputeJury,
  DisputeVoting,
  DisputeEvidence,
  DisputeAppeal,
  ReputationStake,
  ReputationOracle,
  ReputationBoost,
  ReputationDecay,
  ReputationHistory,
  CovenantGovernor,
  CovenantTimelock,
  CovenantToken,
  CovenantTreasury,
  CovenantBridge,
  MessageRelayer,
  MessageVerifier,
  CovenantMultiSig,
  ZKVerifier,
  COVENToken,
  RewardDistributor,
  StakingPool,
  ERC20,
} from './contracts';

export class CovenantSDK {
  public provider: EthersProvider;
  public addresses: ContractAddresses;

  // Core
  public covenantFactory: CovenantFactory;
  public covenantRegistry: CovenantRegistry;
  public covenantImplementation: CovenantImplementation;
  public covenantProxy: CovenantProxy;
  public covenantEvents: CovenantEvents;

  // Task
  public taskMarket: TaskMarket;
  public taskAuction: TaskAuction;
  public taskEscrow: TaskEscrow;
  public taskReview: TaskReview;
  public taskDispute: TaskDispute;

  // Dispute
  public disputeDAO: DisputeDAO;
  public disputeResolution: DisputeResolution;
  public disputeJury: DisputeJury;
  public disputeVoting: DisputeVoting;
  public disputeEvidence: DisputeEvidence;
  public disputeAppeal: DisputeAppeal;

  // Reputation
  public reputationStake: ReputationStake;
  public reputationOracle: ReputationOracle;
  public reputationBoost: ReputationBoost;
  public reputationDecay: ReputationDecay;
  public reputationHistory: ReputationHistory;

  // Governance
  public covenantGovernor: CovenantGovernor;
  public covenantTimelock: CovenantTimelock;
  public covenantToken: CovenantToken;
  public covenantTreasury: CovenantTreasury;

  // Cross-chain
  public covenantBridge: CovenantBridge;
  public messageRelayer: MessageRelayer;
  public messageVerifier: MessageVerifier;

  // Security
  public covenantMultiSig: CovenantMultiSig;
  public zkVerifier: ZKVerifier;

  // Tokenomics
  public covenToken: COVENToken;
  public rewardDistributor: RewardDistributor;
  public stakingPool: StakingPool;

  constructor(config: SdkConfig) {
    this.addresses = config.contractAddresses;
    this.provider = createProvider(config, 'ethers') as EthersProvider;

    // Initialize Core contracts
    this.covenantFactory = new CovenantFactory(
      validateAddress(this.addresses.covenantFactory),
      this.provider
    );
    this.covenantRegistry = new CovenantRegistry(
      validateAddress(this.addresses.covenantRegistry),
      this.provider
    );
    this.covenantImplementation = new CovenantImplementation(
      validateAddress(this.addresses.covenantImplementation),
      this.provider
    );
    this.covenantProxy = new CovenantProxy(
      validateAddress(this.addresses.covenantProxy),
      this.provider
    );
    this.covenantEvents = new CovenantEvents(
      validateAddress(this.addresses.covenantEvents),
      this.provider
    );

    // Initialize Task contracts
    this.taskMarket = new TaskMarket(
      validateAddress(this.addresses.taskMarket),
      this.provider
    );
    this.taskAuction = new TaskAuction(
      validateAddress(this.addresses.taskAuction),
      this.provider
    );
    this.taskEscrow = new TaskEscrow(
      validateAddress(this.addresses.taskEscrow),
      this.provider
    );
    this.taskReview = new TaskReview(
      validateAddress(this.addresses.taskReview),
      this.provider
    );
    this.taskDispute = new TaskDispute(
      validateAddress(this.addresses.taskDispute),
      this.provider
    );

    // Initialize Dispute contracts
    this.disputeDAO = new DisputeDAO(
      validateAddress(this.addresses.disputeDAO),
      this.provider
    );
    this.disputeResolution = new DisputeResolution(
      validateAddress(this.addresses.disputeResolution),
      this.provider
    );
    this.disputeJury = new DisputeJury(
      validateAddress(this.addresses.disputeJury),
      this.provider
    );
    this.disputeVoting = new DisputeVoting(
      validateAddress(this.addresses.disputeVoting),
      this.provider
    );
    this.disputeEvidence = new DisputeEvidence(
      validateAddress(this.addresses.disputeEvidence),
      this.provider
    );
    this.disputeAppeal = new DisputeAppeal(
      validateAddress(this.addresses.disputeAppeal),
      this.provider
    );

    // Initialize Reputation contracts
    this.reputationStake = new ReputationStake(
      validateAddress(this.addresses.reputationStake),
      this.provider
    );
    this.reputationOracle = new ReputationOracle(
      validateAddress(this.addresses.reputationOracle),
      this.provider
    );
    this.reputationBoost = new ReputationBoost(
      validateAddress(this.addresses.reputationBoost),
      this.provider
    );
    this.reputationDecay = new ReputationDecay(
      validateAddress(this.addresses.reputationDecay),
      this.provider
    );
    this.reputationHistory = new ReputationHistory(
      validateAddress(this.addresses.reputationHistory),
      this.provider
    );

    // Initialize Governance contracts
    this.covenantGovernor = new CovenantGovernor(
      validateAddress(this.addresses.covenantGovernor),
      this.provider
    );
    this.covenantTimelock = new CovenantTimelock(
      validateAddress(this.addresses.covenantTimelock),
      this.provider
    );
    this.covenantToken = new CovenantToken(
      validateAddress(this.addresses.covenantToken),
      this.provider
    );
    this.covenantTreasury = new CovenantTreasury(
      validateAddress(this.addresses.covenantTreasury),
      this.provider
    );

    // Initialize Cross-chain contracts
    this.covenantBridge = new CovenantBridge(
      validateAddress(this.addresses.covenantBridge),
      this.provider
    );
    this.messageRelayer = new MessageRelayer(
      validateAddress(this.addresses.messageRelayer),
      this.provider
    );
    this.messageVerifier = new MessageVerifier(
      validateAddress(this.addresses.messageVerifier),
      this.provider
    );

    // Initialize Security contracts
    this.covenantMultiSig = new CovenantMultiSig(
      validateAddress(this.addresses.covenantMultiSig),
      this.provider
    );
    this.zkVerifier = new ZKVerifier(
      validateAddress(this.addresses.zkVerifier),
      this.provider
    );

    // Initialize Tokenomics contracts
    this.covenToken = new COVENToken(
      validateAddress(this.addresses.covenToken),
      this.provider
    );
    this.rewardDistributor = new RewardDistributor(
      validateAddress(this.addresses.rewardDistributor),
      this.provider
    );
    this.stakingPool = new StakingPool(
      validateAddress(this.addresses.stakingPool),
      this.provider
    );
  }

  async getAddress(): Promise<string> {
    return this.provider.getAddress();
  }

  async getBalance(address?: string): Promise<bigint> {
    const addr = address || (await this.getAddress());
    return this.provider.getBalance(addr);
  }

  async getBlockNumber(): Promise<bigint> {
    return this.provider.getBlockNumber();
  }

  async getChainId(): Promise<number> {
    return this.provider.getChainId();
  }

  async signMessage(message: string): Promise<string> {
    return this.provider.signMessage(message);
  }

  getERC20(address: EthereumAddress): ERC20 {
    return new ERC20(validateAddress(address), this.provider);
  }
}
