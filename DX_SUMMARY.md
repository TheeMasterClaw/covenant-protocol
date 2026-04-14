# COVENANT DX Improvement Plan - Executive Summary

## What Was Researched

This research analyzed Web3 developer experience (DX) patterns across major protocols in 2025:
- **Uniswap v4**: Foundry-only for contracts, viem for SDK
- **ENS**: Hardhat 3.x + Foundry hybrid, viem + bun
- **Aave v3**: Hardhat + ethers legacy
- **Arbitrum**: Hardhat + Foundry hybrid
- **Safe**: Hardhat toolbox

## Key Findings

### 1. Hardhat vs Foundry Ecosystem (2025)
- **2025 Trend**: Hybrid setup is standard
  - Foundry for contracts, testing, fuzzing, gas optimization
  - Hardhat 3.x for deployments, verification, TypeScript integration
- **Hardhat 3.x**: New EDR (Rust EVM) makes it 10-20x faster
- **Foundry v1.3.6+**: Still the gold standard for contract testing

### 2. Viem vs Ethers v6
- **Viem 2.x** is the clear winner for new projects
  - 2-4x faster than ethers
  - Smaller bundle size (tree-shakeable)
  - Superior type inference from ABIs
  - Used by ENS, Uniswap, and most new protocols

### 3. Verification Automation
- **Sourcify**: Decentralized, open-source, growing adoption
- **Etherscan**: Still dominant for user trust
- **2025 Best Practice**: Verify on BOTH simultaneously
- **OKLink/XLayer**: Custom API endpoints supported

### 4. Local Node Simulation
- **Anvil** (Foundry): Fastest local node, standard for dev
- **Tenderly Virtual TestNets**: Production-like staging
- **Hardhat Network (EDR)**: Good for TS/JS integration tests

### 5. Code Generation from ABIs
- **wagmi-cli**: 2025 standard for viem projects
  - Generates type-safe React hooks + vanilla actions
  - Watches for changes and regenerates
- **TypeChain**: Still used for ethers projects

### 6. Documentation Generators
- **Natspec**: Standard for Solidity documentation
- **solidity-docgen**: Mature, widely used
- **typedoc**: TypeScript SDK documentation
- **GitHub Pages**: Standard hosting solution

## Recommended Tool Migrations for COVENANT

| Component | Current | Recommended | Priority |
|-----------|---------|-------------|----------|
| Contract Testing | Foundry | Foundry (enhanced) | High |
| Deployment | Hardhat 2.x | Hardhat 3.x | High |
| SDK | ethers 6.x | viem 2.x | High |
| Code Gen | Manual | wagmi-cli | Medium |
| Verification | Manual | Automated (both) | High |
| Local Node | Hardhat node | Anvil | Medium |
| Docs | Minimal | Natspec + docgen | Medium |

## Files Created

1. **DX_IMPROVEMENT_PLAN_2025.md** - Comprehensive plan with all phases
2. **scripts/migrate-to-2025.sh** - Automated migration script
3. **.github/workflows/ci-2025.yml** - Enhanced CI with parallel jobs
4. **research/dx-research-2025/RESEARCH_NOTES.md** - Raw research findings

## Quick Start (Post-Migration)

```bash
# Run the migration
bash scripts/migrate-to-2025.sh

# Start local dev environment
make dev

# Run all tests
make test

# Generate SDK
make generate-sdk

# Deploy and verify
make deploy-xlayer
make verify-all

# Generate docs
make docs
```

## Expected Improvements

| Metric | Before | After |
|--------|--------|-------|
| Build time | ~30s | <5s |
| Test suite | ~5min | <1min |
| SDK bundle | ~500KB | <200KB |
| Type coverage | ~60% | 100% |
| Doc coverage | ~20% | 100% |
| Setup time | ~30min | <5min |

## Timeline

- **Phase 1** (Weeks 1-2): Tooling migration (Hardhat 3.x, Foundry upgrade)
- **Phase 2** (Week 3): CI/CD automation
- **Phase 3** (Week 4): SDK migration to viem, wagmi-cli setup
- **Phase 4** (Weeks 4-5): Documentation automation
- **Phase 5** (Ongoing): Local dev environment optimization

## External Builder Benefits

1. **TypeScript SDK**: Full type safety with viem
2. **React Hooks**: Ready-to-use from wagmi-cli
3. **Auto-generated Docs**: Always up-to-date API reference
4. **Verified Contracts**: Automatically verified on deployment
5. **Clear Examples**: Working code samples in sdk/examples/

## Maintenance

- Review tooling versions quarterly
- Update wagmi-cli with new contract deployments
- Monitor CI performance metrics
- Collect developer feedback via GitHub issues
