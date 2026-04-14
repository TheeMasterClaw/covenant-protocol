#!/bin/bash
# COVENANT DX Migration Script - 2025 Standards
set -e

echo "=== COVENANT DX Migration to 2025 Standards ==="

# Backup
echo "[1/8] Creating backup branch..."
git checkout -b dx-migration-backup-$(date +%Y%m%d) 2>/dev/null || true
git checkout - 2>/dev/null || true

# Install Hardhat 3.x
echo "[2/8] Installing Hardhat 3.x..."
npm install --save-dev hardhat@^3.1.0

# Install plugins
echo "[3/8] Installing Hardhat 3.x plugins..."
npm install --save-dev \
  @nomicfoundation/hardhat-toolbox-viem@^5.0.0 \
  @nomicfoundation/hardhat-foundry@^2.0.0 \
  @nomicfoundation/hardhat-verify@^2.0.0 \
  @nomicfoundation/hardhat-viem@^2.0.0 \
  @nomicfoundation/hardhat-network-helpers@^2.0.0

# Update Foundry
echo "[4/8] Updating Foundry..."
foundryup 2>/dev/null || echo "Please install foundryup manually"

# Update foundry.toml
echo "[5/8] Updating Foundry config..."
cp foundry.toml foundry.toml.bak
cat > foundry.toml << 'TOML'
[profile.default]
src = "contracts-v2"
test = "testing/foundry/test"
script = "testing/foundry/script"
out = "artifacts"
libs = ["node_modules", "lib"]
cache = true
cache_path = "cache/foundry"
remappings = [
    "@openzeppelin/=node_modules/@openzeppelin/",
    "forge-std/=lib/forge-std/src/",
]
solc_version = "0.8.24"
evm_version = "cancun"
optimizer = true
optimizer_runs = 200
via_ir = true
bytecode_hash = "none"
verbosity = 3
ffi = true
fs_permissions = [
    { access = "read-write", path = "./" },
    { access = "read", path = "./artifacts" },
]

[profile.default.fuzz]
runs = 1000
seed = "0xc0venant"

[profile.ci]
fuzz = { runs = 10000 }

[fmt]
line_length = 120

[rpc_endpoints]
xlayer = "https://rpc.xlayer.tech"
xlayer_testnet = "https://testrpc.xlayer.tech"

[etherscan]
xlayer = { key = "${OKLINK_API_KEY}", url = "https://www.oklink.com/api/v5/explorer/contract/verify-source" }
TOML

# SDK workspace
echo "[6/8] Setting up viem SDK workspace..."
mkdir -p sdk/viem/src sdk/viem/abis

# Install docgen
echo "[7/8] Installing documentation tools..."
npm install -D solidity-docgen typedoc

# Verify
echo "[8/8] Verifying installation..."
forge --version
npx hardhat --version

echo "=== Migration Complete ==="
echo "See DX_IMPROVEMENT_PLAN_2025.md for next steps"
