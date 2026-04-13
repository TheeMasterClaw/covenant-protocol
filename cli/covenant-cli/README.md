# COVENANT Protocol CLI

Official command-line interface for interacting with the COVENANT Protocol ecosystem.

[![npm version](https://img.shields.io/npm/v/@covenantprotocol/cli)](https://www.npmjs.com/package/@covenantprotocol/cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

The COVENANT CLI provides a powerful, user-friendly interface for power users and developers to interact with the COVENANT Protocol's 33+ smart contracts. Built with TypeScript and Commander.js, it features wallet management, network switching, gas estimation, dry-run mode, and interactive prompts.

## Features

- **Contract Management**: Deploy, list, and inspect covenants
- **Task Management**: Create tasks, place bids, and manage work
- **Dispute Resolution**: File and resolve disputes with evidence
- **Reputation System**: Stake/unstake tokens and check reputation scores
- **Token Operations**: Check balances, transfer tokens, approve spenders
- **Governance**: Create proposals, cast votes, execute passed proposals
- **Wallet Management**: Create, import, export, and manage multiple wallets
- **Network Management**: Configure and switch between networks
- **Gas Estimation**: Automatic gas estimation with configurable multiplier
- **Dry-Run Mode**: Simulate transactions without broadcasting
- **Interactive Mode**: Guided prompts for all operations

## Installation

### Global Installation (Recommended)

```bash
npm install -g @covenantprotocol/cli
```

### Local Installation

```bash
npm install @covenantprotocol/cli
npx covenant --help
```

### Development Installation

```bash
git clone https://github.com/covenantprotocol/cli.git
cd cli
npm install
npm run build
npm link
```

## Quick Start

```bash
# Create a new wallet
covenant wallet create my-wallet

# Check your balance
covenant wallet balance my-wallet -n sepolia

# Deploy a covenant (requires configured contract addresses)
covenant covenant deploy -w my-wallet -n sepolia

# List all covenants
covenant covenant list -n sepolia

# Create a task
covenant task create --title "Build Website" --reward 0.1 -w my-wallet

# Stake tokens for reputation
covenant reputation stake --amount 100 -w my-wallet

# Vote on a proposal
covenant governance vote 1 --support -w my-wallet
```

## Configuration

The CLI stores configuration in `~/.covenant/`:

- `config.json` - Network and general settings
- `wallets/` - Encrypted wallet files

### Initial Setup

```bash
# View current configuration
covenant config

# Add a network
covenant network add --name sepolia --rpc https://rpc.sepolia.org --chain-id 11155111

# Set default network
covenant network set-default sepolia

# Add contract addresses
covenant network add-contract sepolia CovenantFactory 0x...
covenant network add-contract sepolia TaskRegistry 0x...
covenant network add-contract sepolia Reputation 0x...
covenant network add-contract sepolia Governance 0x...
covenant network add-contract sepolia DisputeArbiter 0x...
```

## Command Reference

### Wallet Commands

```bash
# Create a new wallet
covenant wallet create <name>

# Import from private key
covenant wallet import <name> --key <private-key>

# List all wallets
covenant wallet list

# Check ETH balance
covenant wallet balance [name] -n <network>

# Set default wallet
covenant wallet set-default <name>

# Delete a wallet
covenant wallet delete <name>

# Export private key (WARNING: sensitive!)
covenant wallet export <name>
```

### Network Commands

```bash
# List configured networks
covenant network list

# Add a new network
covenant network add --name <name> --rpc <url> --chain-id <id>

# Remove a network
covenant network remove <name>

# Set default network
covenant network set-default <name>

# Add contract address
covenant network add-contract <network> <contract-name> <address>

# Show network details
covenant network inspect <name>
```

### Covenant Commands

```bash
# Deploy a new covenant
covenant covenant deploy -n <network> -w <wallet> [--salt <hex>] [--init-code <path>]

# List deployed covenants
covenant covenant list -n <network> -l <limit>

# Inspect a specific covenant
covenant covenant inspect <address> -n <network>
```

### Task Commands

```bash
# Create a new task
covenant task create -n <network> -w <wallet> \
  --title "Task Title" \
  --description "Task description" \
  --reward 0.1 \
  --deadline <unix-timestamp>

# Place a bid on a task
covenant task bid <task-id> -n <network> -w <wallet> \
  --amount 0.05 \
  --proposal "My proposal"

# List tasks
covenant task list -n <network> -l <limit>

# Inspect a task and its bids
covenant task inspect <task-id> -n <network>
```

### Dispute Commands

```bash
# File a dispute
covenant dispute file -n <network> -w <wallet> \
  --covenant <address> \
  --reason "Breach of contract" \
  --evidence <hex-data>

# List disputes
covenant dispute list -n <network> -l <limit>

# Inspect a dispute
covenant dispute inspect <dispute-id> -n <network>

# Resolve a dispute (arbitrator only)
covenant dispute resolve <dispute-id> -n <network> -w <wallet> --ruling 1
```

### Reputation Commands

```bash
# Stake tokens for reputation
covenant reputation stake -n <network> -w <wallet> --amount 100

# Unstake tokens
covenant reputation unstake -n <network> -w <wallet> --amount 50

# Check reputation score
covenant reputation get [address] -n <network>

# Slash a user (admin only)
covenant reputation slash -n <network> -w <wallet> --target <address> --amount 10
```

### Token Commands

```bash
# Check token balance
covenant token balance [address] -n <network> --contract <token-address>

# Transfer tokens
covenant token transfer -n <network> -w <wallet> \
  --to <recipient> \
  --amount 10 \
  --contract <token-address>

# Approve token spending
covenant token approve -n <network> -w <wallet> \
  --spender <address> \
  --amount 100 \
  --contract <token-address>

# Check allowance
covenant token allowance -n <network> \
  --owner <address> \
  --spender <address> \
  --contract <token-address>
```

### Governance Commands

```bash
# Cast a vote
covenant governance vote <proposal-id> -n <network> -w <wallet> [--support | --against]

# Create a proposal
covenant governance propose -n <network> -w <wallet> \
  --description "Proposal description" \
  --target <contract-address> \
  --calldata <hex-data>

# List proposals
covenant governance list -n <network> -l <limit>

# Inspect a proposal
covenant governance inspect <proposal-id> -n <network> [--address <voter>]

# Execute a passed proposal
covenant governance execute <proposal-id> -n <network> -w <wallet>
```

## Global Options

| Option | Description |
|--------|-------------|
| `-v, --version` | Display version number |
| `-d, --dry-run` | Simulate without sending transactions |
| `-n, --network <network>` | Specify target network |
| `-w, --wallet <wallet>` | Specify wallet to use |
| `--verbose` | Enable verbose logging |

## Interactive Mode

Run in interactive mode for guided prompts:

```bash
covenant interactive
# or
covenant i
```

## Environment Variables

Create a `.env` file or set environment variables:

```bash
# Logging
LOG_LEVEL=debug  # error, warn, info, debug

# Default settings
COVENANT_DEFAULT_NETWORK=sepolia
COVENANT_DEFAULT_WALLET=my-wallet

# API keys for RPC (used in config)
ALCHEMY_API_KEY=your_key
INFURA_API_KEY=your_key
```

## Security Best Practices

1. **Never share your private keys** - Store them securely
2. **Use encrypted wallets** - The CLI encrypts all wallet files
3. **Verify contract addresses** - Double-check before sending transactions
4. **Use dry-run mode** - Test transactions first with `--dry-run`
5. **Review transaction details** - Always confirm before signing

## Supported Networks

Pre-configured networks:

| Network | Chain ID | Notes |
|---------|----------|-------|
| mainnet | 1 | Ethereum mainnet |
| sepolia | 11155111 | Ethereum testnet |
| polygon | 137 | Polygon mainnet |
| localhost | 31337 | Local hardhat/anvil |

## Troubleshooting

### Connection Issues

```bash
# Test network connection
covenant network inspect <network-name>

# Verify RPC URL and chain ID
```

### Gas Estimation Failed

```bash
# Adjust gas multiplier in config or use --verbose for details
```

### Wallet Not Found

```bash
# List available wallets
covenant wallet list

# Check default wallet setting
covenant config
```

### Contract Not Found

```bash
# Add contract address for network
covenant network add-contract <network> <contract-name> <address>
```

## Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev -- <command>

# Build
npm run build

# Run tests
npm test

# Lint
npm run lint
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 📚 [Documentation](https://docs.covenantprotocol.com)
- 💬 [Discord](https://discord.gg/covenant)
- 🐦 [Twitter](https://twitter.com/covenantprotocol)
- 🐛 [Issue Tracker](https://github.com/covenantprotocol/cli/issues)

---

Built with ❤️ by the COVENANT Protocol Team
