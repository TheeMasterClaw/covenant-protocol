# COVENANT Protocol Developer Experience (DX) Improvement Plan 2025

## Executive Summary

This plan outlines a comprehensive upgrade to COVENANT's developer experience, bringing it in line with 2025 best practices observed at Uniswap, ENS, Aave, and Arbitrum. The goal is world-class DX for both internal teams and external builders.

**Current State**: Foundry initialized, some tests, manual SDK typing, Hardhat+ethers legacy setup
**Target State**: Hybrid Foundry+Hardhat 3.x, viem SDK, automated verification, comprehensive docs

## Research Findings: What Top Protocols Use in 2025

### Tooling Matrix

| Protocol | Contract Tool | Test Framework | Deployment | SDK | Verification |
|----------|--------------|----------------|------------|-----|--------------|
| **Uniswap v4** | Foundry | Foundry fuzz | Foundry scripts | viem | Etherscan |
| **ENS** | Hardhat 3 + Foundry | Hardhat 3 + vitest | hardhat-deploy + rocketh | viem 2.x | Etherscan |
| **Aave v3** | Hardhat | Hardhat | hardhat-deploy | ethers v5 | Etherscan |
| **Arbitrum** | Hardhat + Foundry | Both | Hardhat | ethers | Etherscan |
| **Safe** | Hardhat | Hardhat | hardhat-deploy | ethers | Etherscan |

### 2025 Trend: The Hybrid Approach
Top protocols are converging on a **hybrid setup**:
- **Foundry** for contract development, fuzzing, and gas optimization
- **Hardhat 3.x** for deployments, verification, and TypeScript integration
- **Viem** for SDK (ethers legacy only for older codebases)

---

## Phase 1: Tooling Migration (Weeks 1-2)

### 1.1 Upgrade Hardhat to 3.x (EDR)

**Why**: Hardhat 3.x uses the Rust-based EDR (Ethereum Development Runtime), making it 10-20x faster than the old JavaScript implementation.

**Migration Steps**:

```bash
# Backup current dependencies
npm shrinkwrap

# Install Hardhat 3.x
npm install --save-dev hardhat@^3.1.0

# Update to new Hardhat plugins
npm install --save-dev \
  @nomicfoundation/hardhat-toolbox@^5.0.0 \
  @nomicfoundation/hardhat-viem@^2.0.0 \
  @nomicfoundation/hardhat-verify@^2.0.0 \
  @nomicfoundation/hardhat-foundry@^2.0.0 \
  @nomicfoundation/hardhat-network-helpers@^2.0.0
```

**Update hardhat.config.js → hardhat.config.ts**:

```typescript
import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox-viem';
import '@nomicfoundation/hardhat-foundry';
import '@nomicfoundation/hardhat-verify';
import 'hardhat-deploy';
import dotenv from 'dotenv';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.24',
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 200,
      },
      metadata: {
        bytecodeHash: 'none', // Important for deterministic verification
      },
    },
  },
  networks: {
    hardhat: {
      type: 'edr-simulated', // New in Hardhat 3
      allowUnlimitedContractSize: false,
    },
    xlayer: {
      type: 'http',
      url: process.env.XLAYER_RPC || 'https://rpc.xlayer.tech',
      chainId: 196,
    },
    xlayerTestnet: {
      type: 'http', 
      url: 'https://testrpc.xlayer.tech',
      chainId: 1952,
    },
  },
  etherscan: {
    apiKey: {
      xlayer: process.env.OKLINK_API_KEY || '',
    },
    customChains: [
      {
        network: 'xlayer',
        chainId: 196,
        urls: {
          apiURL: 'https://www.oklink.com/api/v5/explorer/contract/verify-source',
          browserURL: 'https://www.oklink.com/xlayer',
        },
      },
    ],
  },
  sourcify: {
    enabled: true, // Auto-verify on Sourcify too
  },
  paths: {
    sources: './contracts-v2',
    tests: './tests',
    cache: './cache',
    artifacts: './artifacts',
    deployments: './deployments',
  },
  typechain: {
    outDir: 'types',
    target: 'viem', // Use viem target instead of ethers
  },
};

export default config;
```

### 1.2 Foundry Configuration Upgrade

**Update foundry.toml**:

```toml
[profile.default]
src = "contracts-v2"
test = "testing/foundry/test"
script = "testing/foundry/script"
out = "artifacts"
libs = ["node_modules", "lib"]
cache = true
cache_path = "cache/foundry"

# Remappings - ensure consistency
remappings = [
    "@openzeppelin/=node_modules/@openzeppelin/",
    "forge-std/=lib/forge-std/src/",
    "ds-test/=lib/forge-std/lib/ds-test/src/",
]

# Compiler settings
solc_version = "0.8.24"
evm_version = "cancun"
optimizer = true
optimizer_runs = 200
via_ir = true
bytecode_hash = "none"  # Critical for verification

# Fuzzing configuration
[profile.default.fuzz]
runs = 1000
seed = "0xc0venant"

# CI profile - more intensive fuzzing
[profile.ci]
fuzz = { runs = 10000 }
invariant = { runs = 1000, depth = 100 }

# Gas optimization profile
[profile.gas]
gas_limit = 30000000

# Console output
verbosity = 3

# FFI for advanced scripting
ffi = true
fs_permissions = [
    { access = "read-write", path = "./" },
    { access = "read", path = "./artifacts" },
]

# Formatter
[fmt]
line_length = 120
bracket_spacing = false
int_types = "long"
multiline_func_header = "attributes_first"
quote_style = "double"
tab_width = 4

# RPC endpoints for fork testing
[rpc_endpoints]
mainnet = "${MAINNET_RPC_URL}"
xlayer = "https://rpc.xlayer.tech"
xlayer_testnet = "https://testrpc.xlayer.tech"

# Etherscan verification
[etherscan]
xlayer = { key = "${OKLINK_API_KEY}", url = "https://www.oklink.com/api/v5/explorer/contract/verify-source" }
mainnet = { key = "${ETHERSCAN_API_KEY}" }
```

### 1.3 SDK Migration: Ethers → Viem

**Why migrate**: Viem is 2-4x faster, has better type inference, smaller bundle size, and is the 2025 standard (used by ENS, Uniswap, new protocols).

**Create new SDK structure** (sdk/viem/):

```typescript
// sdk/viem/src/config.ts
import { createPublicClient, createWalletClient, http, defineChain } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';

export const xLayer = defineChain({
  id: 196,
  name: 'X Layer',
  network: 'xlayer',
  nativeCurrency: { name: 'OKB', symbol: 'OKB', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://rpc.xlayer.tech'] },
    public: { http: ['https://rpc.xlayer.tech'] },
  },
  blockExplorers: {
    default: { name: 'OKLink', url: 'https://www.oklink.com/xlayer' },
  },
});

export const xLayerTestnet = defineChain({
  id: 1952,
  name: 'X Layer Testnet',
  network: 'xlayer-testnet',
  nativeCurrency: { name: 'OKB', symbol: 'OKB', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://testrpc.xlayer.tech'] },
    public: { http: ['https://testrpc.xlayer.tech'] },
  },
});

export const createCovenantClients = (config: {
  chain: typeof xLayer | typeof xLayerTestnet;
  rpcUrl?: string;
  privateKey?: `0x${string}`;
}) => {
  const transport = http(config.rpcUrl);
  
  const publicClient = createPublicClient({
    chain: config.chain,
    transport,
  });

  const walletClient = config.privateKey 
    ? createWalletClient({
        chain: config.chain,
        transport,
        account: privateKeyToAccount(config.privateKey),
      })
    : undefined;

  return { publicClient, walletClient };
};
```

**Contract abstraction**:

```typescript
// sdk/viem/src/contracts/CovenantFactory.ts
import { getContract, PublicClient, WalletClient } from 'viem';
import { CovenantFactoryABI } from '../abis';

export class CovenantFactory {
  private contract: ReturnType<typeof getContract>;

  constructor(
    address: `0x${string}`,
    publicClient: PublicClient,
    walletClient?: WalletClient
  ) {
    this.contract = getContract({
      address,
      abi: CovenantFactoryABI,
      client: {
        public: publicClient,
        wallet: walletClient,
      },
    });
  }

  async createCovenant(
    agent: `0x${string}`,
    terms: string,
    stakeAmount: bigint
  ) {
    return this.contract.write.createCovenant([agent, terms, stakeAmount]);
  }

  async getCovenant(id: bigint) {
    return this.contract.read.getCovenant([id]);
  }

  // ... other methods
}
```

---

## Phase 2: CI/CD & Automation (Week 3)

### 2.1 Enhanced GitHub Actions Workflow

**Update .github/workflows/ci.yml**:

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  # Solidity linting and formatting
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
        with:
          version: v1.3.6
      
      - name: Check formatting
        run: forge fmt --check
      
      - name: Run solhint
        run: |
          npm ci
          npx solhint 'contracts-v2/**/*.sol'

  # Foundry tests (fast)
  test-foundry:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
        with:
          version: v1.3.6
      
      - name: Run Forge build
        run: forge build
        env:
          FOUNDRY_PROFILE: ci
      
      - name: Run Forge tests
        run: forge test --isolate -vvv
        env:
          FOUNDRY_PROFILE: ci
      
      - name: Run gas snapshot check
        run: forge snapshot --check
        continue-on-error: true

  # Hardhat + viem tests (integration)
  test-hardhat:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      
      - name: Install dependencies
        run: npm ci
      
      - name: Compile contracts
        run: npx hardhat compile
      
      - name: Run Hardhat tests
        run: npx hardhat test

  # Coverage reporting
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      
      - name: Run coverage
        run: forge coverage --report lcov
      
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./lcov.info
          fail_ci_if_error: false

  # SDK build and test
  sdk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
      
      - name: Install dependencies
        run: |
          npm ci
          cd sdk/viem && npm ci
      
      - name: Build SDK
        run: cd sdk/viem && npm run build
      
      - name: Test SDK
        run: cd sdk/viem && npm test
      
      - name: Type check SDK
        run: cd sdk/viem && npx tsc --noEmit

  # Documentation build
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      
      - name: Generate contract docs
        run: |
          forge doc --build
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
      
      - name: Build TypeScript docs
        run: |
          cd sdk/viem && npm ci && npm run docs
```

### 2.2 Automated Deployment & Verification

**Create deployment scripts**:

```typescript
// scripts/deploy/001_deploy_core.ts
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  // Deploy implementation
  const implementation = await deploy('CovenantImplementation', {
    from: deployer,
    log: true,
    skipIfAlreadyDeployed: true,
  });

  // Deploy factory
  const factory = await deploy('CovenantFactory', {
    from: deployer,
    args: [implementation.address],
    log: true,
    skipIfAlreadyDeployed: true,
  });

  // Deploy registry
  const registry = await deploy('CovenantRegistry', {
    from: deployer,
    args: [factory.address],
    log: true,
    skipIfAlreadyDeployed: true,
  });

  // Save deployment addresses for SDK
  await hre.run('export', {
    exportAll: './deployments/exports.json',
  });
};

func.tags = ['core'];
export default func;
```

**Automated verification script**:

```bash
#!/bin/bash
# scripts/verify-all.sh

set -e

NETWORK=$1

if [ -z "$NETWORK" ]; then
  echo "Usage: ./verify-all.sh <network>"
  exit 1
fi

echo "Verifying contracts on $NETWORK..."

# Verify on Etherscan/OKLink
npx hardhat etherscan-verify --network $NETWORK

# Verify on Sourcify (decentralized)
npx hardhat sourcify --network $NETWORK

echo "Verification complete!"
```

---

## Phase 3: Code Generation & SDK (Week 4)

### 3.1 wagmi-cli Setup

**Install wagmi-cli**:

```bash
cd sdk/viem
npm install --save-dev @wagmi/cli @wagmi/connectors viem
```

**Create wagmi.config.ts**:

```typescript
import { defineConfig } from '@wagmi/cli';
import { foundry, react } from '@wagmi/cli/plugins';
import { actions } from '@wagmi/cli/plugins';

export default defineConfig({
  out: 'src/generated.ts',
  contracts: [],
  plugins: [
    // Generate from Foundry/Hardhat artifacts
    foundry({
      deployments: {
        CovenantFactory: {
          196: '0x...', // X Layer mainnet
          1952: '0x...', // X Layer testnet
        },
        CovenantRegistry: {
          196: '0x...',
          1952: '0x...',
        },
        // ... other contracts
      },
    }),
    // Generate React hooks
    react(),
    // Generate vanilla actions
    actions(),
  ],
});
```

**Add to package.json**:

```json
{
  "scripts": {
    "generate": "wagmi generate",
    "generate:watch": "wagmi generate --watch",
    "build": "npm run generate && tsc",
    "prepublishOnly": "npm run build"
  }
}
```

### 3.2 Type Generation from ABIs

Generated output provides:
- Type-safe contract instances
- React hooks (useReadContract, useWriteContract, etc.)
- Vanilla actions for non-React usage
- Full TypeScript inference from ABIs

Example usage after generation:

```typescript
// React usage
import { useCovenantFactoryCreateCovenant } from '@covenant/sdk/generated';

function CreateCovenantButton() {
  const { write, isLoading } = useCovenantFactoryCreateCovenant();
  
  return (
    <button onClick={() => write({ args: [agent, terms, stake] })}>
      Create Covenant
    </button>
  );
}

// Vanilla usage
import { createCovenantFactoryCreateCovenant } from '@covenant/sdk/generated';

const hash = await createCovenantFactoryCreateCovenant(walletClient, {
  address: factoryAddress,
  args: [agent, terms, stake],
});
```

---

## Phase 4: Documentation (Week 4-5)

### 4.1 Natspec Documentation Standards

**Add comprehensive Natspec to all contracts**:

```solidity
// contracts-v2/core/CovenantFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ICovenantFactory} from "../interfaces/ICovenantFactory.sol";

/**
 * @title CovenantFactory
 * @author COVENANT Protocol
 * @notice Factory contract for creating new Covenant agreements
 * @dev Uses CREATE2 for deterministic addresses. Upgradeable via proxy pattern.
 * @custom:security-contact security@covenant.io
 */
contract CovenantFactory is ICovenantFactory {
    
    /**
     * @notice Creates a new Covenant between an agent and principal
     * @dev Emits CovenantCreated event. Requires implementation to be set.
     * @param agent The AI agent or service provider address
     * @param termsURI IPFS hash pointing to covenant terms
     * @param stakeAmount Amount of COVEN tokens to stake
     * @return covenantId The unique identifier for the created covenant
     * @return covenantAddress The address of the deployed covenant proxy
     */
    function createCovenant(
        address agent,
        string calldata termsURI,
        uint256 stakeAmount
    ) external returns (uint256 covenantId, address covenantAddress);
    
    /**
     * @notice Gets covenant details by ID
     * @param id The covenant identifier
     * @return covenant The covenant data struct
     */
    function getCovenant(uint256 id) 
        external 
        view 
        returns (Covenant memory covenant);
}
```

### 4.2 Documentation Generation Pipeline

**Install tools**:

```bash
npm install --save-dev solidity-docgen typedoc
```

**Create docgen config**:

```javascript
// docgen.config.js
module.exports = {
  outputDir: './docs/contracts',
  templates: 'docs/templates',
  pages: 'files',
  exclude: ['mocks', 'test'],
  theme: 'markdown',
};
```

**Add to package.json**:

```json
{
  "scripts": {
    "docs:solidity": "solidity-docgen --config docgen.config.js",
    "docs:ts": "typedoc --out docs/sdk sdk/viem/src",
    "docs:build": "npm run docs:solidity && npm run docs:ts",
    "docs:serve": "npx serve docs"
  }
}
```

### 4.3 GitHub Pages Documentation Site

Create `.github/workflows/docs.yml`:

```yaml
name: Documentation

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      
      - name: Generate contract docs
        run: forge doc --build
      
      - name: Setup Node
        uses: actions/setup-node@v4
      
      - name: Generate SDK docs
        run: |
          cd sdk/viem && npm ci && npm run docs
      
      - name: Copy SDK docs
        run: |
          mkdir -p docs/site/sdk
          cp -r sdk/viem/docs/* docs/site/sdk/
      
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs/site
```

---

## Phase 5: Local Development Environment (Ongoing)

### 5.1 Anvil Integration

**Create local dev setup**:

```bash
#!/bin/bash
# scripts/dev-node.sh

# Start Anvil with X Layer fork (optional)
if [ "$FORK" = "true" ]; then
  anvil --fork-url https://rpc.xlayer.tech \
    --chain-id 31337 \
    --block-time 2 \
    --accounts 10 \
    --balance 10000
else
  anvil --chain-id 31337 \
    --accounts 10 \
    --balance 10000 \
    --block-time 2
fi
```

**Makefile targets**:

```makefile
# Makefile additions
.PHONY: dev test foundry-test anvil deploy-local

dev: anvil deploy-local

anvil:
	@anvil --fork-url https://rpc.xlayer.tech --chain-id 31337 &
	@sleep 3

deploy-local:
	npx hardhat deploy --network localhost

test:
	forge test -vv

test-gas:
	forge test --gas-report

snapshot:
	forge snapshot

lint:
	forge fmt
	npx solhint 'contracts-v2/**/*.sol'
```

### 5.2 Environment Templates

**Create .env.template**:

```bash
# RPC Endpoints
XLAYER_RPC=https://rpc.xlayer.tech
XLAYER_TESTNET_RPC=https://testrpc.xlayer.tech
MAINNET_RPC=https://eth.merkle.io

# Private Keys (for deployments - use keystore in production!)
PRIVATE_KEY=0x...
DEPLOYER_KEY=0x...

# API Keys
ETHERSCAN_API_KEY=...
OKLINK_API_KEY=...
TENDERLY_API_KEY=...

# Verification
VERIFY_ON_DEPLOY=true
```

---

## Migration Scripts

### Quick Migration Checklist

```bash
#!/bin/bash
# scripts/migrate-to-2025.sh

echo "=== COVENANT DX Migration to 2025 Standards ==="

# 1. Backup
echo "[1/8] Creating backup..."
git checkout -b dx-migration-backup-$(date +%Y%m%d)

# 2. Install Hardhat 3.x
echo "[2/8] Installing Hardhat 3.x..."
npm install hardhat@^3.1.0

# 3. Install new plugins
echo "[3/8] Installing Hardhat 3.x plugins..."
npm install @nomicfoundation/hardhat-toolbox-viem \
  @nomicfoundation/hardhat-foundry \
  @nomicfoundation/hardhat-verify \
  @nomicfoundation/hardhat-viem

# 4. Update Foundry
echo "[4/8] Updating Foundry..."
foundryup

# 5. Update foundry.toml
echo "[5/8] Updating Foundry config..."
cp foundry.toml foundry.toml.bak
cat > foundry.toml << 'TOML'
[profile.default]
src = "contracts-v2"
test = "testing/foundry/test"
out = "artifacts"
libs = ["node_modules", "lib"]
solc_version = "0.8.24"
evm_version = "cancun"
optimizer = true
optimizer_runs = 200
via_ir = true
bytecode_hash = "none"

[profile.ci]
fuzz = { runs = 10000 }

[fmt]
line_length = 120
TOML

# 6. Install SDK dependencies
echo "[6/8] Setting up viem SDK..."
mkdir -p sdk/viem
cd sdk/viem
npm init -y
npm install viem @wagmi/cli
npm install -D typescript @types/node typedoc

# 7. Install docgen
echo "[7/8] Installing documentation tools..."
cd ../..
npm install -D solidity-docgen

# 8. Verify
echo "[8/8] Verifying installation..."
forge --version
npx hardhat --version
echo "viem version: $(cd sdk/viem && npm list viem)"

echo "=== Migration Complete ==="
echo "Next steps:"
echo "1. Update hardhat.config.js to hardhat.config.ts"
echo "2. Run 'make test' to verify everything works"
echo "3. See DX_IMPROVEMENT_PLAN_2025.md for full details"
```

---

## Expected Outcomes

### Performance Improvements
- **Build times**: 10-20x faster with Hardhat 3.x EDR
- **Test execution**: 2-4x faster with Foundry native runner
- **Bundle size**: 30-50% smaller SDK with viem
- **Type safety**: 100% type inference from ABIs (no manual typing)

### Developer Experience
- **One-command setup**: `make dev` starts local environment
- **Hot reload**: wagmi-cli watches contracts and regenerates SDK
- **Auto-verification**: Deployments automatically verified on Sourcify + Etherscan
- **Instant feedback**: Fast CI with parallel Foundry/Hardhat tests
- **Rich documentation**: Auto-generated from Natspec comments

### External Builder Onboarding
- **TypeScript SDK**: Full type safety, autocomplete, inline docs
- **React hooks**: Ready-to-use hooks for frontend integration
- **Clear examples**: Working examples in sdk/examples/
- **Interactive docs**: GitHub Pages with searchable API reference

---

## Success Metrics

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Contract build time | ~30s | <5s | `forge build` time |
| Test suite runtime | ~5min | <1min | CI time |
| SDK bundle size | ~500KB | <200KB | Bundle analyzer |
| Type coverage | ~60% | 100% | `tsc --noEmit` |
| Doc coverage | ~20% | 100% | Natspec parsing |
| Setup time | ~30min | <5min | New dev onboarding |

---

## Appendix: Tool Versions (2025)

| Tool | Version | Purpose |
|------|---------|---------|
| Foundry | v1.3.6+ | Contract dev, testing |
| Hardhat | v3.1.0+ | Deployment, verification |
| Viem | v2.7.0+ | TypeScript SDK |
| wagmi-cli | v2.10.0+ | Code generation |
| Solidity | 0.8.24+ | Contract language |
| Node | 20+ | JS runtime |
| Bun | 1.2+ | Alternative runtime (ENS uses) |

---

*Plan created: April 2025*
*Next review: After Phase 1 completion*
