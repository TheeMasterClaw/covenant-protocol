import { Command } from 'commander';
import chalk from 'chalk';
import { listWallets, createWallet, importWallet, deleteWallet, setDefaultWallet, loadWalletData, getWallet } from '../utils/wallet.js';
import { loadConfig } from '../utils/config.js';
import { getProvider, getBalance } from '../utils/network.js';
import { getNetwork } from '../utils/config.js';
import { logSuccess, logError, logInfo, logTable, logDivider } from '../utils/logger.js';

export function registerWalletCommands(program: Command): void {
  const walletCmd = program
    .command('wallet')
    .description('Manage wallets');

  // wallet create
  walletCmd
    .command('create [name]')
    .description('Create a new wallet')
    .option('-p, --password <password>', 'Wallet password')
    .action(async (name, options) => {
      try {
        if (!name) {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'input',
            name: 'name',
            message: 'Wallet name:',
            validate: (input: string) => input.length > 0 || 'Name required'
          }]);
          name = answers.name;
        }
        
        const wallet = await createWallet(name, options.password);
        logSuccess(`Wallet "${wallet.name}" created`);
        logTable({
          Name: wallet.name,
          Address: wallet.address,
          'Created At': wallet.createdAt
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // wallet import
  walletCmd
    .command('import [name]')
    .description('Import a wallet from private key')
    .option('-k, --key <key>', 'Private key')
    .option('-p, --password <password>', 'Wallet password')
    .action(async (name, options) => {
      try {
        if (!name) {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'input',
            name: 'name',
            message: 'Wallet name:',
            validate: (input: string) => input.length > 0 || 'Name required'
          }]);
          name = answers.name;
        }
        
        let privateKey = options.key;
        if (!privateKey) {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'password',
            name: 'key',
            message: 'Private key:',
            mask: '*',
            validate: (input: string) => input.length > 0 || 'Private key required'
          }]);
          privateKey = answers.key;
        }
        
        const wallet = await importWallet(name, privateKey, options.password);
        logSuccess(`Wallet "${wallet.name}" imported`);
        logTable({
          Name: wallet.name,
          Address: wallet.address
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // wallet list
  walletCmd
    .command('list')
    .description('List all wallets')
    .action(async () => {
      const wallets = listWallets();
      const config = loadConfig();
      
      if (wallets.length === 0) {
        logInfo('No wallets found. Create one with "covenant wallet create".');
        return;
      }
      
      console.log('\n' + chalk.bold.cyan('Wallets'));
      logDivider();
      wallets.forEach(w => {
        const isDefault = w.name === config.defaultWallet;
        console.log(`  ${isDefault ? chalk.green('★') : ' '} ${chalk.bold(w.name)} ${chalk.gray(w.address)}`);
      });
    });

  // wallet balance
  walletCmd
    .command('balance [name]')
    .description('Check wallet ETH balance')
    .option('-n, --network <network>', 'Target network')
    .action(async (name, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        let walletsToCheck;
        if (name) {
          const data = loadWalletData(name);
          if (!data) {
            throw new Error(`Wallet "${name}" not found.`);
          }
          walletsToCheck = [data];
        } else {
          walletsToCheck = listWallets();
        }
        
        console.log('\n' + chalk.bold.cyan(`Balances on ${network.name}`));
        logDivider();
        
        for (const w of walletsToCheck) {
          const balance = await getBalance(provider, w.address);
          console.log(`  ${chalk.bold(w.name)} ${chalk.gray(w.address)}: ${chalk.green(balance)} ETH`);
        }
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // wallet set-default
  walletCmd
    .command('set-default <name>')
    .description('Set default wallet')
    .action(async (name) => {
      try {
        setDefaultWallet(name);
        logSuccess(`Default wallet set to "${name}"`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // wallet delete
  walletCmd
    .command('delete <name>')
    .description('Delete a wallet')
    .action(async (name) => {
      try {
        const inquirer = await import('inquirer');
        const answers = await inquirer.default.prompt([{
          type: 'confirm',
          name: 'confirm',
          message: `Are you sure you want to delete wallet "${name}"?`,
          default: false
        }]);
        
        if (!answers.confirm) {
          logInfo('Deletion cancelled.');
          return;
        }
        
        deleteWallet(name);
        logSuccess(`Wallet "${name}" deleted`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // wallet export
  walletCmd
    .command('export <name>')
    .description('Export wallet private key (WARNING: sensitive)')
    .option('-p, --password <password>', 'Wallet password')
    .action(async (name, options) => {
      try {
        const wallet = await getWallet(name, options.password);
        
        const inquirer = await import('inquirer');
        const answers = await inquirer.default.prompt([{
          type: 'confirm',
          name: 'confirm',
          message: 'WARNING: This will display your private key. Continue?',
          default: false
        }]);
        
        if (!answers.confirm) {
          logInfo('Export cancelled.');
          return;
        }
        
        console.log('\n' + chalk.bold.red('PRIVATE KEY'));
        logDivider();
        console.log(`  Address: ${wallet.address}`);
        console.log(`  Private Key: ${wallet.privateKey}`);
        console.log(chalk.yellow('  Keep this secret and secure!'));
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });
}
