import { Address, Hex } from 'viem';

export type EthereumAddress = Address;
export type Bytes32 = Hex;
export type Bytes = Hex;

export interface SdkConfig {
  rpcUrl: string;
  chainId: number;
  contractAddresses: ContractAddresses;
  privateKey?: string;
}

export interface ContractAddresses {
  covenantFactory: EthereumAddress;
  covenantRegistry: EthereumAddress;
  covenantImplementation: EthereumAddress;
  covenantProxy: EthereumAddress;
  covenantEvents: EthereumAddress;
  taskMarket: EthereumAddress;
  taskAuction: EthereumAddress;
  taskEscrow: EthereumAddress;
  taskReview: EthereumAddress;
  taskDispute: EthereumAddress;
  disputeDAO: EthereumAddress;
  disputeResolution: EthereumAddress;
  disputeJury: EthereumAddress;
  disputeVoting: EthereumAddress;
  disputeEvidence: EthereumAddress;
  disputeAppeal: EthereumAddress;
  reputationStake: EthereumAddress;
  reputationOracle: EthereumAddress;
  reputationBoost: EthereumAddress;
  reputationDecay: EthereumAddress;
  reputationHistory: EthereumAddress;
  covenantGovernor: EthereumAddress;
  covenantTimelock: EthereumAddress;
  covenantToken: EthereumAddress;
  covenantTreasury: EthereumAddress;
  covenantBridge: EthereumAddress;
  messageRelayer: EthereumAddress;
  messageVerifier: EthereumAddress;
  covenantMultiSig: EthereumAddress;
  zkVerifier: EthereumAddress;
  covenToken: EthereumAddress;
  rewardDistributor: EthereumAddress;
  stakingPool: EthereumAddress;
}

// Covenant Types
export enum CovenantState {
  Draft = 0,
  Active = 1,
  Paused = 2,
  Resolved = 3,
  Terminated = 4,
}

export interface CovenantCreatedEvent {
  proxy: EthereumAddress;
  implementation: EthereumAddress;
  creator: EthereumAddress;
  salt: Bytes32;
}

// Task Types
export enum TaskStatus {
  Open = 0,
  Assigned = 1,
  Submitted = 2,
  Completed = 3,
  Disputed = 4,
  Cancelled = 5,
}

export interface Task {
  id: bigint;
  covenantId: bigint;
  creator: EthereumAddress;
  assignee: EthereumAddress;
  reward: bigint;
  rewardToken: EthereumAddress;
  deadline: bigint;
  status: TaskStatus;
  metadataHash: Bytes32;
}

export interface Auction {
  taskId: bigint;
  startPrice: bigint;
  endPrice: bigint;
  startTime: bigint;
  duration: bigint;
  highestBidder: EthereumAddress;
  highestBid: bigint;
  settled: boolean;
}

export interface Escrow {
  taskId: bigint;
  amount: bigint;
  token: EthereumAddress;
  payer: EthereumAddress;
  payee: EthereumAddress;
  state: EscrowState;
}

export enum EscrowState {
  Pending = 0,
  Funded = 1,
  Released = 2,
  Refunded = 3,
  Disputed = 4,
}

export interface Review {
  reviewId: bigint;
  taskId: bigint;
  reviewer: EthereumAddress;
  reviewee: EthereumAddress;
  rating: number;
  commentHash: Bytes32;
  createdAt: bigint;
}

export interface TaskDisputeRecord {
  disputeId: bigint;
  taskId: bigint;
  initiator: EthereumAddress;
  respondent: EthereumAddress;
  initiatedAt: bigint;
  status: TaskDisputeStatus;
  outcome: TaskDisputeOutcome;
  reasonHash: Bytes32;
}

export enum TaskDisputeStatus {
  Open = 0,
  Evidence = 1,
  Voting = 2,
  Resolved = 3,
  Appealed = 4,
}

export enum TaskDisputeOutcome {
  Pending = 0,
  InitiatorWins = 1,
  RespondentWins = 2,
  Split = 3,
}

// Reputation Types
export interface StakeInfo {
  amount: bigint;
  stakedAt: bigint;
  unlockTime: bigint;
  locked: boolean;
}

export interface OracleData {
  dataHash: Bytes32;
  timestamp: bigint;
  confidence: number;
  source: EthereumAddress;
}

export interface Boost {
  amount: bigint;
  expiresAt: bigint;
  reason: Bytes32;
  active: boolean;
}

export interface ReputationSnapshot {
  timestamp: bigint;
  score: bigint;
  context: Bytes32;
}

// Dispute Types
export interface DisputeParams {
  minStake: bigint;
  votingPeriod: bigint;
  quorum: bigint;
  appealThreshold: bigint;
}

export enum ResolutionOutcome {
  Pending = 0,
  InitiatorWins = 1,
  RespondentWins = 2,
  Split = 3,
  Dismissed = 4,
}

export interface Juror {
  account: EthereumAddress;
  stake: bigint;
  selectionScore: bigint;
  active: boolean;
}

export interface Vote {
  voter: EthereumAddress;
  choice: number;
  weight: bigint;
  timestamp: bigint;
}

export interface Evidence {
  evidenceId: bigint;
  disputeId: bigint;
  submitter: EthereumAddress;
  evidenceHash: Bytes32;
  metadataHash: Bytes32;
  submittedAt: bigint;
}

export interface Appeal {
  appealId: bigint;
  disputeId: bigint;
  appellant: EthereumAddress;
  bond: bigint;
  appealedAt: bigint;
  status: AppealStatus;
}

export enum AppealStatus {
  Pending = 0,
  Upheld = 1,
  Overturned = 2,
  Rejected = 3,
}

// Governance Types
export interface Proposal {
  id: bigint;
  proposer: EthereumAddress;
  description: string;
  callData: Bytes;
  target: EthereumAddress;
  forVotes: bigint;
  againstVotes: bigint;
  abstainVotes: bigint;
  startTime: bigint;
  endTime: bigint;
  executed: boolean;
  canceled: boolean;
}

// Cross-chain Types
export interface BridgeMessage {
  targetChain: number;
  targetContract: EthereumAddress;
  payload: Bytes;
  nonce: bigint;
}

export interface RelayJob {
  messageId: bigint;
  targetChain: number;
  payload: Bytes;
  fee: bigint;
  relayer: EthereumAddress;
  completed: boolean;
}

export interface VerifiedMessage {
  messageHash: Bytes32;
  signature: Bytes;
  signer: EthereumAddress;
  verifiedAt: bigint;
  valid: boolean;
}

// Security Types
export interface Transaction {
  to: EthereumAddress;
  value: bigint;
  data: Bytes;
  executed: boolean;
  confirmationCount: bigint;
}

export interface Operation {
  target: EthereumAddress;
  value: bigint;
  data: Bytes;
  scheduledAt: bigint;
  delay: bigint;
  executed: boolean;
}

export interface ZKProof {
  a: [bigint, bigint];
  b: [[bigint, bigint], [bigint, bigint]];
  c: [bigint, bigint];
}

// Tokenomics Types
export interface Tokenomics {
  maxSupply: bigint;
  totalMinted: bigint;
  inflationRate: bigint;
  lastMintTime: bigint;
}

export interface Stake {
  amount: bigint;
  rewardDebt: bigint;
  lockEnd: bigint;
  multiplier: bigint;
}

export interface Distribution {
  token: EthereumAddress;
  amount: bigint;
  startTime: bigint;
  endTime: bigint;
  claimed: bigint;
}

// Error Types
export class CovenantSDKError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly cause?: Error
  ) {
    super(message);
    this.name = 'CovenantSDKError';
  }
}

export class ContractCallError extends CovenantSDKError {
  constructor(message: string, cause?: Error) {
    super(message, 'CONTRACT_CALL_ERROR', cause);
    this.name = 'ContractCallError';
  }
}

export class TransactionError extends CovenantSDKError {
  constructor(message: string, cause?: Error) {
    super(message, 'TRANSACTION_ERROR', cause);
    this.name = 'TransactionError';
  }
}

export class ValidationError extends CovenantSDKError {
  constructor(message: string, cause?: Error) {
    super(message, 'VALIDATION_ERROR', cause);
    this.name = 'ValidationError';
  }
}

export class InsufficientFundsError extends CovenantSDKError {
  constructor(message: string, cause?: Error) {
    super(message, 'INSUFFICIENT_FUNDS_ERROR', cause);
    this.name = 'InsufficientFundsError';
  }
}

// Provider Type
export type ProviderType = 'ethers' | 'viem';

export interface CallOverrides {
  from?: EthereumAddress;
  value?: bigint;
  gasLimit?: bigint;
  gasPrice?: bigint;
  maxFeePerGas?: bigint;
  maxPriorityFeePerGas?: bigint;
}

export interface TransactionResult {
  hash: Bytes32;
  wait: () => Promise<TransactionReceipt>;
}

export interface TransactionReceipt {
  blockHash: Bytes32;
  blockNumber: bigint;
  contractAddress?: EthereumAddress;
  cumulativeGasUsed: bigint;
  effectiveGasPrice: bigint;
  from: EthereumAddress;
  gasUsed: bigint;
  logs: Log[];
  status: 'success' | 'reverted';
  to: EthereumAddress;
  transactionHash: Bytes32;
  transactionIndex: number;
}

export interface Log {
  address: EthereumAddress;
  topics: Bytes32[];
  data: Bytes;
  blockHash: Bytes32;
  blockNumber: bigint;
  logIndex: number;
  transactionHash: Bytes32;
  transactionIndex: number;
}
