# @covenant/sdk

TypeScript SDK for COVENANT Protocol - A decentralized agreement framework.

## Installation

```bash
npm install @covenant/sdk ethers viem
# or
yarn add @covenant/sdk ethers viem
```

## Quick Start

```typescript
import { CovenantSDK, SdkConfig } from '@covenant/sdk';

const config: SdkConfig = {
  rpcUrl: 'https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY',
  chainId: 11155111,
  privateKey: '0x...', // Optional: for write operations
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

const sdk = new CovenantSDK(config);
```

## Core Features

### Create a Covenant

```typescript
const salt = ethers.encodeBytes32String('my-covenant');
const initData = '0x'; // Your initialization params
const tx = await sdk.covenantFactory.createCovenant(salt, initData);
const receipt = await tx.wait();
console.log('Covenant created at:', receipt.contractAddress);
```

### Submit a Task

```typescript
const tx = await sdk.taskMarket.createTask(
  1n, // covenantId
  ethers.parseEther('1.0'), // reward
  '0x...', // rewardToken (ERC20 address or 0x0 for ETH)
  BigInt(Math.floor(Date.now() / 1000) + 86400), // deadline
  ethers.encodeBytes32String('task-metadata')
);
const receipt = await tx.wait();
```

### Stake Reputation

```typescript
const tx = await sdk.reputationStake.stake(
  ethers.parseEther('100'), // amount
  2592000n // lockDuration in seconds (30 days)
);
const receipt = await tx.wait();
```

### File a Dispute

```typescript
const tx = await sdk.disputeAppeal.fileAppeal(
  1n, // disputeId
  { value: ethers.parseEther('0.5') } // appeal bond
);
const receipt = await tx.wait();
```

## Contract Coverage

This SDK supports all 33+ contracts in the COVENANT Protocol:

- **Core**: `CovenantFactory`, `CovenantRegistry`, `CovenantImplementation`, `CovenantProxy`, `CovenantEvents`
- **Task**: `TaskMarket`, `TaskAuction`, `TaskEscrow`, `TaskReview`, `TaskDispute`
- **Dispute**: `DisputeDAO`, `DisputeResolution`, `DisputeJury`, `DisputeVoting`, `DisputeEvidence`, `DisputeAppeal`
- **Reputation**: `ReputationStake`, `ReputationOracle`, `ReputationBoost`, `ReputationDecay`, `ReputationHistory`
- **Governance**: `CovenantGovernor`, `CovenantTimelock`, `CovenantToken`, `CovenantTreasury`
- **Cross-chain**: `CovenantBridge`, `MessageRelayer`, `MessageVerifier`
- **Security**: `CovenantMultiSig`, `ZKVerifier`
- **Tokenomics**: `COVEN`, `RewardDistributor`, `StakingPool`

## Error Handling

```typescript
import { ContractCallError, TransactionError, ValidationError } from '@covenant/sdk';

try {
  await sdk.covenantFactory.createCovenant(salt, initData);
} catch (err) {
  if (err instanceof ContractCallError) {
    console.error('Contract call failed:', err.message);
  } else if (err instanceof TransactionError) {
    console.error('Transaction failed:', err.message);
  } else if (err instanceof ValidationError) {
    console.error('Invalid input:', err.message);
  }
}
```

## License

MIT
