import { ethers } from 'ethers';
import { NetworkConfig } from './config.js';

// Minimal ABI fragments for common interactions
export const COVENANT_FACTORY_ABI = [
  'function deployCovenant(bytes calldata initCode, bytes32 salt) external payable returns (address covenant)',
  'event CovenantDeployed(address indexed covenant, bytes32 indexed salt, address indexed deployer)',
  'function getCovenantAddress(bytes32 salt, address deployer) external view returns (address)',
  'function covenantCount() external view returns (uint256)',
  'function covenants(uint256 index) external view returns (address)'
];

export const COVENANT_ABI = [
  'function name() view returns (string)',
  'function version() view returns (string)',
  'function owner() view returns (address)',
  'function termsHash() view returns (bytes32)',
  'function parties(uint256) view returns (address)',
  'function status() view returns (uint8)',
  'function execute() external',
  'function terminate() external',
  'event Executed()',
  'event Terminated()'
];

export const TASK_REGISTRY_ABI = [
  'function createTask(string calldata title, string calldata description, uint256 reward, uint256 deadline) external payable returns (uint256 taskId)',
  'function bid(uint256 taskId, uint256 amount, string calldata proposal) external',
  'function acceptBid(uint256 taskId, uint256 bidIndex) external',
  'function completeTask(uint256 taskId) external',
  'function taskCount() view returns (uint256)',
  'function tasks(uint256) view returns (uint256 id, address creator, string title, uint256 reward, uint256 deadline, uint8 status)',
  'function getBids(uint256 taskId) view returns (tuple(address bidder, uint256 amount, string proposal, uint8 status)[])',
  'event TaskCreated(uint256 indexed taskId, address indexed creator, uint256 reward)',
  'event BidSubmitted(uint256 indexed taskId, address indexed bidder, uint256 amount)'
];

export const DISPUTE_ARBITER_ABI = [
  'function fileDispute(address covenant, string calldata reason, bytes calldata evidence) external payable returns (uint256 disputeId)',
  'function resolveDispute(uint256 disputeId, uint8 ruling) external',
  'function disputes(uint256) view returns (uint256 id, address covenant, address complainant, string reason, uint8 status, uint8 ruling)',
  'function disputeCount() view returns (uint256)',
  'event DisputeFiled(uint256 indexed disputeId, address indexed covenant, address indexed complainant)',
  'event DisputeResolved(uint256 indexed disputeId, uint8 ruling)'
];

export const REPUTATION_ABI = [
  'function stake(uint256 amount) external',
  'function unstake(uint256 amount) external',
  'function slash(address user, uint256 amount) external',
  'function getReputation(address user) view returns (uint256 score, uint256 staked)',
  'function totalStaked() view returns (uint256)',
  'event Staked(address indexed user, uint256 amount)',
  'event Unstaked(address indexed user, uint256 amount)',
  'event Slashed(address indexed user, uint256 amount)'
];

export const GOVERNANCE_ABI = [
  'function propose(string calldata description, address target, bytes calldata callData) external returns (uint256 proposalId)',
  'function vote(uint256 proposalId, bool support) external',
  'function execute(uint256 proposalId) external',
  'function proposals(uint256) view returns (uint256 id, string description, address proposer, uint256 forVotes, uint256 againstVotes, uint8 status)',
  'function proposalCount() view returns (uint256)',
  'function hasVoted(uint256 proposalId, address voter) view returns (bool)',
  'event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description)',
  'event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes)'
];

export const ERC20_ABI = [
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function decimals() view returns (uint8)',
  'function totalSupply() view returns (uint256)',
  'function balanceOf(address account) view returns (uint256)',
  'function transfer(address to, uint256 amount) external returns (bool)',
  'function approve(address spender, uint256 amount) external returns (bool)',
  'function allowance(address owner, address spender) view returns (uint256)',
  'event Transfer(address indexed from, address indexed to, uint256 amount)',
  'event Approval(address indexed owner, address indexed spender, uint256 amount)'
];

export function getContractAddress(network: NetworkConfig, name: string): string {
  const address = network.contracts[name];
  if (!address) {
    throw new Error(`Contract "${name}" not configured for network "${network.name}". ` +
      `Add it with: covenant network add-contract ${network.name} ${name} <address>`);
  }
  if (!ethers.isAddress(address)) {
    throw new Error(`Invalid address for contract "${name}": ${address}`);
  }
  return address;
}

export function getContract(
  address: string,
  abi: string[],
  signerOrProvider: ethers.Signer | ethers.Provider
): ethers.Contract {
  return new ethers.Contract(address, abi, signerOrProvider);
}
