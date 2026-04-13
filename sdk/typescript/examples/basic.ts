import { ethers } from 'ethers';
import { CovenantSDK, SdkConfig } from '../src';

// Example configuration
const config: SdkConfig = {
  rpcUrl: process.env.RPC_URL || 'http://localhost:8545',
  chainId: Number(process.env.CHAIN_ID) || 31337,
  privateKey: process.env.PRIVATE_KEY || '0x...',
  contractAddresses: {
    covenantFactory: '0x...',
    covenantRegistry: '0x...',
    covenantImplementation: '0x...',
    covenantProxy: '0x...',
    covenantEvents: '0x...',
    taskMarket: '0x...',
    taskAuction: '0x...',
    taskEscrow: '0x...',
    taskReview: '0x...',
    taskDispute: '0x...',
    disputeDAO: '0x...',
    disputeResolution: '0x...',
    disputeJury: '0x...',
    disputeVoting: '0x...',
    disputeEvidence: '0x...',
    disputeAppeal: '0x...',
    reputationStake: '0x...',
    reputationOracle: '0x...',
    reputationBoost: '0x...',
    reputationDecay: '0x...',
    reputationHistory: '0x...',
    covenantGovernor: '0x...',
    covenantTimelock: '0x...',
    covenantToken: '0x...',
    covenantTreasury: '0x...',
    covenantBridge: '0x...',
    messageRelayer: '0x...',
    messageVerifier: '0x...',
    covenantMultiSig: '0x...',
    zkVerifier: '0x...',
    covenToken: '0x...',
    rewardDistributor: '0x...',
    stakingPool: '0x...',
  },
};

async function main() {
  const sdk = new CovenantSDK(config);

  console.log('=== COVENANT SDK Examples ===\n');

  // Get account info
  const address = await sdk.getAddress();
  const balance = await sdk.getBalance();
  console.log(`Connected as: ${address}`);
  console.log(`Balance: ${ethers.formatEther(balance)} ETH\n`);

  // Example 1: Create a Covenant
  console.log('1. Creating a Covenant...');
  try {
    const salt = ethers.encodeBytes32String('example-covenant');
    const initData = '0x'; // Empty for this example
    const predicted = await sdk.covenantFactory.predictCovenantAddress(salt, initData);
    console.log(`Predicted address: ${predicted}`);
    
    const tx = await sdk.covenantFactory.createCovenant(salt, initData);
    console.log(`Transaction hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Covenant created! Status: ${receipt.status}\n`);
  } catch (err: any) {
    console.error(`Failed: ${err.message}\n`);
  }

  // Example 2: Submit a Task
  console.log('2. Submitting a Task...');
  try {
    const covenantId = 1n;
    const reward = ethers.parseEther('0.5');
    const rewardToken = ethers.ZeroAddress; // ETH
    const deadline = BigInt(Math.floor(Date.now() / 1000) + 86400); // 1 day
    const metadataHash = ethers.encodeBytes32String('task-description');

    const tx = await sdk.taskMarket.createTask(
      covenantId,
      reward,
      rewardToken,
      deadline,
      metadataHash,
      { value: reward }
    );
    console.log(`Transaction hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Task submitted! Status: ${receipt.status}\n`);
  } catch (err: any) {
    console.error(`Failed: ${err.message}\n`);
  }

  // Example 3: Stake Reputation
  console.log('3. Staking Reputation...');
  try {
    const amount = ethers.parseEther('100');
    const lockDuration = 2592000n; // 30 days

    const tx = await sdk.reputationStake.stake(amount, lockDuration);
    console.log(`Transaction hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Staked! Status: ${receipt.status}`);

    const stakeInfo = await sdk.reputationStake.getStakeInfo(address);
    console.log(`Stake info: ${JSON.stringify(stakeInfo, (_, v) => typeof v === 'bigint' ? v.toString() : v)}\n`);
  } catch (err: any) {
    console.error(`Failed: ${err.message}\n`);
  }

  // Example 4: File a Dispute
  console.log('4. Filing a Dispute...');
  try {
    const taskId = 1n;
    const reasonHash = ethers.encodeBytes32String('dispute-reason');

    const tx = await sdk.taskDispute.initiateDispute(taskId, reasonHash);
    console.log(`Transaction hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Dispute filed! Status: ${receipt.status}\n`);
  } catch (err: any) {
    console.error(`Failed: ${err.message}\n`);
  }

  // Example 5: Governance Proposal
  console.log('5. Creating Governance Proposal...');
  try {
    const target = config.contractAddresses.covenantTreasury;
    const callData = '0x';
    const description = 'Example proposal for funding';

    const tx = await sdk.covenantGovernor.propose(target, callData, description);
    console.log(`Transaction hash: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`Proposal created! Status: ${receipt.status}\n`);
  } catch (err: any) {
    console.error(`Failed: ${err.message}\n`);
  }

  // Example 6: Read operations
  console.log('6. Reading Contract State...');
  try {
    const totalCovenants = await sdk.covenantRegistry.totalCovenants();
    console.log(`Total covenants: ${totalCovenants}`);

    const disputeParams = await sdk.disputeDAO.getParams();
    console.log(`Dispute params: ${JSON.stringify(disputeParams, (_, v) => typeof v === 'bigint' ? v.toString() : v)}`);

    const blockNumber = await sdk.getBlockNumber();
    console.log(`Current block: ${blockNumber}\n`);
  } catch (err: any) {
    console.error(`Failed: ${err.message}\n`);
  }

  console.log('=== Examples Complete ===');
}

main().catch(console.error);
