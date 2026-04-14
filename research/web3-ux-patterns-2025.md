# Modern Web3 UX Patterns for 2025: COVENANT Integration Guide

## Executive Summary

This document outlines modern Web3 UX patterns that reduce friction for COVENANT Protocol, focusing on account abstraction (ERC-4337), session keys, progressive onboarding, gasless transactions, and mobile-first design. All patterns are production-ready and specifically tailored for COVENANT's recurring covenant payments use case.

---

## 1. ERC-4337 Account Abstraction Implementations

### 1.1 Recommended Stack: Pimlico + permissionless.js

**Why Pimlico:**
- Most battle-tested ERC-4337 infrastructure (used by Coinbase, Rainbow, Family)
- Built on viem (same as COVENANT's current stack)
- Native support for EntryPoint 0.7
- 100+ chains supported including X Layer

**Installation:**
```bash
cd /home/azureuser/covenant/frontend-v2
npm install permissionless@0.2 viem@^2.0
```

**COVENANT Integration - Create Smart Account Client:**

```typescript
// lib/smart-account.ts
import { createSmartAccountClient } from "permissionless";
import { createPaymasterClient, toSimpleSmartAccount } from "viem/account-abstraction";
import { createWalletClient, http } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { xLayerTestnet } from "viem/chains";

const PIMLICO_API_KEY = process.env.NEXT_PUBLIC_PIMLICO_API_KEY;
const PAYMASTER_URL = `https://api.pimlico.io/v2/xlayer-testnet/rpc?apikey=${PIMLICO_API_KEY}`;
const BUNDLER_URL = `https://api.pimlico.io/v2/xlayer-testnet/rpc?apikey=${PIMLICO_API_KEY}`;

// Create smart account from EOA (RainbowKit connected wallet)
export async function createCovenantSmartAccount(eoaWalletClient: any) {
  const smartAccount = await toSimpleSmartAccount({
    client: eoaWalletClient,
    owner: eoaWalletClient.account,
  });

  const paymasterClient = createPaymasterClient({
    transport: http(PAYMASTER_URL),
  });

  const smartAccountClient = createSmartAccountClient({
    account: smartAccount,
    paymaster: paymasterClient,
    chain: xLayerTestnet,
    bundlerTransport: http(BUNDLER_URL),
    userOperation: {
      estimateFeesPerGas: async () => {
        return (await paymasterClient.getUserOperationGasPrice()).fast;
      },
    },
  });

  return smartAccountClient;
}
```

### 1.2 Alternative: Biconomy for Session-Heavy Use Cases

**Best for:** COVENANT's recurring payment flows requiring granular session permissions

```bash
npm install @biconomy/account @biconomy/modules
```

```typescript
// lib/biconomy-account.ts
import { createSmartAccountClient, createSession, createSessionSmartAccountClient } from "@biconomy/account";
import { PaymasterMode } from "@biconomy/paymaster";

export async function createBiconomySmartAccount(signer: any) {
  const smartAccount = await createSmartAccountClient({
    signer,
    bundlerUrl: process.env.NEXT_PUBLIC_BICONOMY_BUNDLER_URL!,
    paymasterUrl: process.env.NEXT_PUBLIC_BICONOMY_PAYMASTER_URL!,
  });
  
  return smartAccount;
}

// Create session for recurring covenant payments
export async function createCovenantPaymentSession(
  smartAccount: any,
  covenantContractAddress: string,
  maxAmountPerTx: bigint,
  validUntil: number
) {
  const policy = [
    {
      sessionKeyAddress: await smartAccount.getAddress(),
      contractAddress: covenantContractAddress,
      functionSelector: "processRecurringPayment(address,uint256)",
      rules: [
        {
          offset: 0, // recipient address
          condition: 0, // Equal
          referenceValue: smartAccount.address,
        },
        {
          offset: 32, // amount
          condition: 1, // Less than or equal
          referenceValue: maxAmountPerTx,
        },
      ],
      interval: {
        validUntil,
        validAfter: Math.floor(Date.now() / 1000),
      },
      valueLimit: 0n,
    },
  ];

  const { wait, session } = await createSession(
    smartAccount,
    policy,
    null,
    {
      paymasterServiceData: { mode: PaymasterMode.SPONSORED },
    }
  );

  return { wait, session };
}
```

### 1.3 ZeroDev Kernel for Advanced Use Cases

**Best for:** Complex permissioning, multi-sig covenants, or delegated execution

```bash
npm install @zerodev/sdk @zerodev/ecdsa-validator
```

```typescript
// lib/zerodev-account.ts
import { createKernelAccount, createZeroDevPaymasterClient } from "@zerodev/sdk";
import { signerToEcdsaValidator } from "@zerodev/ecdsa-validator";
import { http } from "viem";

export async function createZeroDevKernelAccount(signer: any) {
  const publicClient = createPublicClient({
    transport: http(process.env.NEXT_PUBLIC_RPC_URL),
  });

  const ecdsaValidator = await signerToEcdsaValidator(publicClient, {
    signer,
    entryPoint: ENTRYPOINT_ADDRESS_V07,
  });

  const kernelAccount = await createKernelAccount(publicClient, {
    plugins: {
      sudo: ecdsaValidator,
    },
    entryPoint: ENTRYPOINT_ADDRESS_V07,
  });

  return kernelAccount;
}
```

---

## 2. Session Keys for Recurring Covenant Payments

### 2.1 Problem: Manual Approvals for Every Recurring Payment

Traditional approach requires user to sign every transaction. Session keys enable:
- Pre-approved spending limits
- Time-bound authorizations  
- Specific function selectors only
- Automated execution without manual signing

### 2.2 Implementation: Biconomy Session Module

```typescript
// hooks/use-covenant-session.ts
import { useState, useCallback } from 'react';
import { createSession } from '@biconomy/account';

export function useCovenantSession() {
  const [sessionActive, setSessionActive] = useState(false);

  const createCovenantSession = useCallback(async (
    smartAccountClient: any,
    covenantAddress: string,
    paymentToken: string,
    maxAmount: bigint,
    durationDays = 30
  ) => {
    const validUntil = Math.floor(Date.now() / 1000) + (durationDays * 24 * 60 * 60);
    
    const policy = [{
      sessionKeyAddress: await smartAccountClient.getAddress(),
      contractAddress: covenantAddress,
      functionSelector: "processRecurringPayment(address,address,uint256)",
      rules: [
        {
          offset: 0,  // token address
          condition: 0, // Equal
          referenceValue: paymentToken,
        },
        {
          offset: 64, // amount (after 2 address params)
          condition: 1, // Less than or equal
          referenceValue: maxAmount,
        },
      ],
      interval: {
        validUntil,
        validAfter: Math.floor(Date.now() / 1000),
      },
      valueLimit: 0n,
    }];

    const { wait } = await createSession(
      smartAccountClient,
      policy,
      null,
      { paymasterServiceData: { mode: PaymasterMode.SPONSORED } }
    );

    await wait();
    setSessionActive(true);
  }, []);

  return { createCovenantSession, sessionActive };
}
```

### 2.3 Storage Options for Session Keys

**Option A: LocalStorage (Testing only)**
```typescript
const store = createStore("DEFAULT_STORE", StorageType.LOCAL_STORAGE);
```

**Option B: Secure Cloud / MPC (Production)**
```typescript
// Using Lit Protocol for decentralized key management
import { LitNodeClient } from '@lit-protocol/lit-node-client';

async function createMPCSessionKey(userWallet: any) {
  const litClient = new LitNodeClient({
    litNetwork: 'datil-dev',
  });
  await litClient.connect();
  // Generate session key that requires user's signature to use
}
```

---

## 3. Progressive Onboarding (Email/Social to Self-Custody)

### 3.1 Recommended: Dynamic.xyz Integration

```bash
npm install @dynamic-labs/sdk-react-core @dynamic-labs/wagmi-connector
```

```typescript
// app/providers.tsx - Updated for progressive onboarding
import { DynamicContextProvider } from "@dynamic-labs/sdk-react-core";
import { DynamicWagmiConnector } from "@dynamic-labs/wagmi-connector";
import { EthereumWalletConnectors } from "@dynamic-labs/ethereum";

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <DynamicContextProvider
      settings={{
        environmentId: process.env.NEXT_PUBLIC_DYNAMIC_ENV_ID!,
        walletConnectors: [EthereumWalletConnectors],
        eventsCallbacks: {
          onAuthSuccess: ({ user, primaryWallet }) => {
            if (primaryWallet.connector.type === 'embeddedWallet') {
              showWalletUpgradePrompt(user);
            }
          },
        },
      }}
    >
      <DynamicWagmiConnector>
        <WagmiProvider config={config}>
          <QueryClientProvider client={queryClient}>
            {children}
          </QueryClientProvider>
        </WagmiProvider>
      </DynamicWagmiConnector>
    </DynamicContextProvider>
  );
}
```

### 3.2 Migration Flow: Embedded → Self-Custody

```typescript
// components/wallet/upgrade-wallet.tsx
export function WalletUpgradePrompt() {
  const { user } = useDynamicContext();

  const handleUpgrade = async () => {
    const privateKey = await user?.embeddedWallet?.exportPrivateKey();
    showSecureBackupModal(privateKey);
    await migrateAssets(user.walletAddress, newWalletAddress);
    connect({ connector: injected() });
  };

  return (
    <Card className="bg-amber-50 border-amber-200">
      <CardHeader>
        <CardTitle>Upgrade to Full Self-Custody</CardTitle>
        <CardDescription>
          Your current wallet is managed for convenience. 
          Upgrade to have full control of your keys.
        </CardDescription>
      </CardHeader>
      <CardFooter>
        <Button onClick={handleUpgrade}>Upgrade Wallet</Button>
      </CardFooter>
    </Card>
  );
}
```

---

## 4. Gasless Transactions via Paymasters

### 4.1 Pimlico Paymaster Integration

```typescript
// lib/paymaster.ts
import { createPaymasterClient } from "viem/account-abstraction";
import { http } from "viem";

const PIMLICO_PAYMASTER_URL = `https://api.pimlico.io/v2/xlayer-testnet/rpc?apikey=${process.env.NEXT_PUBLIC_PIMLICO_API_KEY}`;

export const paymasterClient = createPaymasterClient({
  transport: http(PIMLICO_PAYMASTER_URL),
});

// Verify sponsor policy eligibility
export async function checkSponsorshipEligibility(
  userAddress: string,
  operation: string
): Promise<{ eligible: boolean; reason?: string }> {
  // Check if user has COVEN tokens staked
  // Check reputation score
  // Check if operation is whitelisted
  const eligibility = await fetch('/api/sponsor-check', {
    method: 'POST',
    body: JSON.stringify({ userAddress, operation }),
  }).then(r => r.json());
  
  return eligibility;
}
```

### 4.2 Custom Covenant Paymaster

```solidity
// contracts/CovenantPaymaster.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@account-abstraction/core/BasePaymaster.sol";

contract CovenantPaymaster is BasePaymaster {
    mapping(bytes4 => bool) public whitelistedMethods;
    mapping(address => bool) public whitelistedContracts;
    
    constructor(address _entryPoint) BasePaymaster(_entryPoint) {
        whitelistedMethods[bytes4(keccak256("createCovenant(bytes)"))] = true;
        whitelistedMethods[bytes4(keccak256("submitDispute(bytes32,bytes)"))] = true;
        whitelistedMethods[bytes4(keccak256("stakeReputation(uint256)"))] = true;
    }
}
```

---

## 5. WalletConnect v2 Improvements (2025)

### 5.1 RainbowKit 2.2.x Integration

Key improvements from RainbowKit 2.2.x:
- Coinbase Smart Wallet support with Passkeys
- ERC-6492 signature verification for smart contract wallets
- Base Account support with paymasters and sub-accounts
- Disabled third-party connector telemetry by default

```typescript
// lib/wagmi.ts - Updated configuration
import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { coinbaseWallet } from '@rainbow-me/rainbowkit/wallets';

export const config = getDefaultConfig({
  appName: 'COVENANT Protocol',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID!,
  chains: [xLayerTestnet, xLayer],
  ssr: true,
  walletConnectParameters: {
    telemetryEnabled: false, // User privacy by default
  },
});

// Coinbase Smart Wallet with Paymasters
coinbaseWallet.paymasterUrls = {
  [baseSepolia.id]: process.env.NEXT_PUBLIC_COINBASE_PAYMASTER_URL!,
};

// Enable Sub Accounts for session-based operations
coinbaseWallet.subAccounts = {
  enableAutoSubAccounts: true,
  defaultSpendLimits: {},
};
```

---

## 6. Mobile-First dApp Design

### 6.1 PWA Configuration

```typescript
// app/manifest.ts
import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'COVENANT Protocol',
    short_name: 'COVENANT',
    description: 'Decentralized infrastructure for AI agent covenants',
    start_url: '/',
    display: 'standalone',
    background_color: '#000000',
    theme_color: '#000000',
    orientation: 'portrait',
    icons: [
      { src: '/icon-192x192.png', sizes: '192x192', type: 'image/png' },
      { src: '/icon-512x512.png', sizes: '512x512', type: 'image/png' },
    ],
    shortcuts: [
      {
        name: 'Create Covenant',
        short_name: 'Create',
        description: 'Create a new covenant',
        url: '/covenants/create',
      },
      {
        name: 'Active Tasks',
        short_name: 'Tasks',
        url: '/tasks',
      },
    ],
  };
}
```

### 6.2 Mobile-Optimized Transaction Flow

```typescript
// components/covenant/mobile-covenant-flow.tsx
export function MobileCovenantFlow() {
  const [step, setStep] = useState(1);
  const totalSteps = 4;

  return (
    <div className="flex flex-col h-screen">
      <div className="px-4 py-3 bg-background border-b">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium">
            Step {step} of {totalSteps}
          </span>
        </div>
        <Progress value={(step / totalSteps) * 100} />
      </div>

      <div className="flex-1 overflow-y-auto p-4">
        {step === 1 && <SelectCounterpartyStep />}
        {step === 2 && <DefineTermsStep />}
        {step === 3 && <ReviewAndSignStep />}
        {step === 4 && <SuccessStep />}
      </div>

      <div className="p-4 border-t bg-background safe-area-bottom">
        <Button className="w-full h-12 text-lg">
          {step === totalSteps ? 'Done' : 'Continue'}
        </Button>
      </div>
    </div>
  );
}
```

---

## 7. Key Integration Steps Summary

### Step 1: Install Dependencies
```bash
cd /home/azureuser/covenant/frontend-v2
npm install permissionless@0.2 viem@^2.0 @biconomy/account
npm install @dynamic-labs/sdk-react-core @dynamic-labs/wagmi-connector
```

### Step 2: Environment Variables
```bash
# .env.local
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id
NEXT_PUBLIC_PIMLICO_API_KEY=your_pimlico_key
NEXT_PUBLIC_DYNAMIC_ENV_ID=your_dynamic_env_id
NEXT_PUBLIC_BICONOMY_BUNDLER_URL=...
NEXT_PUBLIC_BICONOMY_PAYMASTER_URL=...
```

### Step 3: Update Providers
Replace RainbowKit-only setup with Dynamic + Wagmi + RainbowKit hybrid for progressive onboarding.

### Step 4: Create Smart Account Hook
Implement `useCovenantAccount` hook to manage EOA + Smart Account relationship.

### Step 5: Implement Session Keys
Use Biconomy's session module for recurring covenant payments.

### Step 6: Add Gasless Transactions
Integrate Pimlico paymaster for sponsored covenant creation.

---

## 8. Production Checklist

1. **Session Key Storage:** Use secure enclaves or MPC (Lit Protocol), never localStorage
2. **Paymaster Validation:** Implement server-side eligibility checks
3. **Smart Account Recovery:** Implement social recovery mechanisms
4. **Audit:** Audit custom paymaster contracts
5. **Performance:** Batch operations, cache paymaster responses

---

## References

- [Pimlico Documentation](https://docs.pimlico.io/permissionless)
- [Biconomy SDK](https://docs.biconomy.io)
- [ZeroDev SDK](https://docs.zerodev.app)
- [RainbowKit Changelog](https://github.com/rainbow-me/rainbowkit/blob/main/packages/rainbowkit/CHANGELOG.md)
- [ERC-4337 Specification](https://eips.ethereum.org/EIPS/eip-4337)
- [Dynamic.xyz Docs](https://docs.dynamic.xyz)
