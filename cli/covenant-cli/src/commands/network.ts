import { Command } from 'commander';
import chalk from 'chalk';
import { loadConfig, saveConfig, getNetwork, addNetwork, removeNetwork, setDefaultNetwork, NetworkConfig } from '../utils/config.js';
import { getProvider, validateNetwork } from '../utils/network.js';
import { logSuccess, logError, logInfo, logTable, logDivider } from '../utils/logger.js';

export function registerNetworkCommands(program: Command): void {
  const networkCmd = program
    .command('network')
    .description('Manage network configurations');

  // network list
  networkCmd
    .command('list')
    .description('List configured networks')
    .action(async () => {
      const config = loadConfig();
      
      console.log('\n' + chalk.bold.cyan('Configured Networks'));
      logDivider();
      
      for (const net of config.networks) {
        const isDefault = net.name === config.defaultNetwork;
        console.log(`${isDefault ? chalk.green('★') : ' '} ${chalk.bold(net.name)}`);
        logTable({
          'RPC URL': net.rpcUrl,
          'Chain ID': net.chainId,
          Explorer: net.explorer || 'N/A',
          Contracts: Object.keys(net.contracts).length
        });
      }
    });

  // network add
  networkCmd
    .command('add')
    .description('Add a new network')
    .option('--name <name>', 'Network name')
    .option('--rpc <url>', 'RPC URL')
    .option('--chain-id <id>', 'Chain ID')
    .option('--explorer <url>', 'Block explorer URL')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const inquirer = await import('inquirer');
        
        const answers = await inquirer.default.prompt([
          {
            type: 'input',
            name: 'name',
            message: 'Network name:',
            when: !options.name,
            validate: (input: string) => input.length > 0 || 'Name required'
          },
          {
            type: 'input',
            name: 'rpcUrl',
            message: 'RPC URL:',
            when: !options.rpc,
            validate: (input: string) => input.startsWith('http') || 'Must be a valid URL'
          },
          {
            type: 'input',
            name: 'chainId',
            message: 'Chain ID:',
            when: !options.chainId,
            validate: (input: string) => !isNaN(Number(input)) || 'Must be a number'
          },
          {
            type: 'input',
            name: 'explorer',
            message: 'Block explorer URL (optional):',
            when: !options.explorer
          }
        ]);
        
        const network: NetworkConfig = {
          name: options.name || answers.name,
          rpcUrl: options.rpc || answers.rpcUrl,
          chainId: Number(options.chainId || answers.chainId),
          explorer: options.explorer || answers.explorer || undefined,
          contracts: {}
        };
        
        // Test connection
        const spinner = (await import('ora')).default('Testing connection...').start();
        try {
          const provider = await getProvider(network);
          await validateNetwork(provider, network.chainId);
          spinner.succeed(`Connected to ${network.name} (chainId: ${network.chainId})`);
        } catch (err) {
          spinner.fail(`Connection failed: ${(err as Error).message}`);
          const { proceed } = await inquirer.default.prompt([{
            type: 'confirm',
            name: 'proceed',
            message: 'Save anyway?',
            default: false
          }]);
          if (!proceed) {
            logInfo('Network not saved.');
            return;
          }
        }
        
        addNetwork(config, network);
        logSuccess(`Network "${network.name}" added`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // network remove
  networkCmd
    .command('remove <name>')
    .description('Remove a network')
    .action(async (name) => {
      try {
        const config = loadConfig();
        removeNetwork(config, name);
        logSuccess(`Network "${name}" removed`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // network set-default
  networkCmd
    .command('set-default <name>')
    .description('Set default network')
    .action(async (name) => {
      try {
        const config = loadConfig();
        setDefaultNetwork(config, name);
        logSuccess(`Default network set to "${name}"`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // network add-contract
  networkCmd
    .command('add-contract <network> <name> <address>')
    .description('Add or update a contract address for a network')
    .action(async (networkName, contractName, address) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, networkName);
        network.contracts[contractName] = address;
        
        const idx = config.networks.findIndex(n => n.name === networkName);
        config.networks[idx] = network;
        saveConfig(config);
        
        logSuccess(`Contract "${contractName}" set to ${address} on ${networkName}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // network inspect
  networkCmd
    .command('inspect <name>')
    .description('Show network details')
    .action(async (name) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, name);
        const isDefault = network.name === config.defaultNetwork;
        
        console.log('\n' + chalk.bold.cyan(`Network: ${network.name}`));
        logDivider();
        logTable({
          Name: network.name,
          'RPC URL': network.rpcUrl,
          'Chain ID': network.chainId,
          Explorer: network.explorer || 'N/A',
          Default: isDefault ? 'Yes' : 'No'
        });
        
        console.log('\n' + chalk.bold('Contracts:'));
        const entries = Object.entries(network.contracts);
        if (entries.length === 0) {
          console.log('  No contracts configured.');
        } else {
          entries.forEach(([cName, cAddr]) => {
            console.log(`  ${chalk.cyan(cName)}: ${cAddr}`);
          });
        }
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });
}
