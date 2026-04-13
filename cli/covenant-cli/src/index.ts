#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { registerCovenantCommands } from './commands/covenant.js';
import { registerTaskCommands } from './commands/task.js';
import { registerDisputeCommands } from './commands/dispute.js';
import { registerReputationCommands } from './commands/reputation.js';
import { registerTokenCommands } from './commands/token.js';
import { registerGovernanceCommands } from './commands/governance.js';
import { registerWalletCommands } from './commands/wallet.js';
import { registerNetworkCommands } from './commands/network.js';
import { loadConfig } from './utils/config.js';
import { logger, logDivider } from './utils/logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const pkgPath = path.join(__dirname, '..', 'package.json');
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));

const program = new Command()
  .name('covenant')
  .description('CLI tool for interacting with COVENANT Protocol')
  .version(pkg.version, '-v, --version', 'Display version number')
  .option('-d, --dry-run', 'Run in simulation mode without sending transactions')
  .option('-n, --network <network>', 'Specify target network')
  .option('-w, --wallet <wallet>', 'Specify wallet to use')
  .option('--verbose', 'Enable verbose logging')
  .hook('preAction', (thisCommand) => {
    const opts = thisCommand.opts();
    if (opts.verbose) {
      logger.level = 'debug';
    }
  });

// Register all command groups
registerWalletCommands(program);
registerNetworkCommands(program);
registerCovenantCommands(program);
registerTaskCommands(program);
registerDisputeCommands(program);
registerReputationCommands(program);
registerTokenCommands(program);
registerGovernanceCommands(program);

// Config command
program
  .command('config')
  .description('Show current configuration')
  .action(() => {
    const config = loadConfig();
    console.log('\n' + chalk.bold.cyan('COVENANT CLI Configuration'));
    logDivider();
    console.log(`  Version: ${pkg.version}`);
    console.log(`  Default Network: ${config.defaultNetwork}`);
    console.log(`  Default Wallet: ${config.defaultWallet || 'Not set'}`);
    console.log(`  Log Level: ${config.logLevel}`);
    console.log(`  Dry Run Default: ${config.dryRun}`);
    console.log(`  Gas Multiplier: ${config.gasMultiplier}`);
    console.log(`  Networks: ${config.networks.length}`);
    console.log(`  Config Path: ~/.covenant/config.json`);
  });

// Interactive mode
program
  .command('interactive')
  .alias('i')
  .description('Start interactive mode')
  .action(async () => {
    const inquirer = await import('inquirer');
    
    console.log(chalk.bold.cyan('\n🛡️  COVENANT Protocol CLI - Interactive Mode\n'));
    
    const choices = [
      { name: '📜 Covenant - Deploy/List/Inspect', value: 'covenant' },
      { name: '📋 Task - Create/Bid/Manage', value: 'task' },
      { name: '⚖️  Dispute - File/Resolve', value: 'dispute' },
      { name: '⭐ Reputation - Stake/Unstake', value: 'reputation' },
      { name: '💰 Token - Balance/Transfer', value: 'token' },
      { name: '🏛️  Governance - Vote/Propose', value: 'governance' },
      { name: '👛 Wallet - Create/Import/List', value: 'wallet' },
      { name: '🌐 Network - Switch/Configure', value: 'network' },
      { name: '❌ Exit', value: 'exit' }
    ];
    
    let running = true;
    while (running) {
      const { action } = await inquirer.default.prompt([{
        type: 'list',
        name: 'action',
        message: 'What would you like to do?',
        choices
      }]);
      
      if (action === 'exit') {
        running = false;
        console.log(chalk.green('Goodbye! 👋'));
        continue;
      }
      
      console.log(chalk.gray(`\nRun 'covenant ${action} --help' for available commands\n`));
    }
  });

// Error handling and main
async function main() {
  program.exitOverride();
  
  try {
    await program.parseAsync();
  } catch (err: any) {
    if (err.code !== 'commander.helpDisplayed' && err.code !== 'commander.version') {
      logger.error(err.message || 'Unknown error');
      process.exit(1);
    }
  }
}

main();
