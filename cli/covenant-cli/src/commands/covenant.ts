import { Command } from 'commander';
import { ethers } from 'ethers';
import chalk from 'chalk';
import { loadConfig, getNetwork } from '../utils/config.js';
import { getProvider, validateNetwork } from '../utils/network.js';
import { getWallet } from '../utils/wallet.js';
import { getContractAddress, getContract, COVENANT_FACTORY_ABI, COVENANT_ABI } from '../utils/contracts.js';
import { estimateGas, checkBalance } from '../utils/gas.js';
import { confirmWithGas, displaySpinner } from '../utils/interactive.js';
import { logSuccess, logError, logInfo, logTable, logDivider } from '../utils/logger.js';

export function registerCovenantCommands(program: Command): void {
  const covenant = program
    .command('covenant')
    .description('Manage COVENANT contracts');

  // covenant deploy
  covenant
    .command('deploy')
    .description('Deploy a new covenant contract')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--salt <salt>', 'Deployment salt (hex string)', ethers.ZeroHash)
    .option('--init-code <path>', 'Path to init code file')
    .option('--dry-run', 'Simulate without sending')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        logInfo(`Using wallet: ${wallet.address}`);
        
        // Interactive prompts if not provided
        let initCode: string;
        if (options.initCode) {
          const fs = await import('fs-extra');
          initCode = fs.readFileSync(options.initCode, 'hex');
        } else {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'input',
            name: 'initCode',
            message: 'Enter initialization bytecode (hex):',
            validate: (input: string) => input.startsWith('0x') || 'Must be hex string starting with 0x'
          }]);
          initCode = answers.initCode;
        }
        
        const factoryAddress = getContractAddress(network, 'CovenantFactory');
        const factory = getContract(factoryAddress, COVENANT_FACTORY_ABI, wallet);
        
        const txRequest = await factory.deployCovenant.populateTransaction(initCode, options.salt);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Deploy Covenant',
          {
            Network: network.name,
            Wallet: wallet.address,
            Factory: factoryAddress,
            Salt: options.salt
          },
          gasEstimate,
          options.dryRun || config.dryRun
        );
        
        if (!confirmed) {
          logInfo('Deployment cancelled or dry-run.');
          return;
        }
        
        await checkBalance(provider, wallet.address, gasEstimate.estimatedCost);
        
        const spinner = displaySpinner('Deploying covenant...');
        const tx = await factory.deployCovenant(initCode, options.salt);
        const receipt = await tx.wait();
        spinner.succeed('Covenant deployed successfully');
        
        // Parse event for deployed address
        const event = receipt?.logs
          .map((log: any) => {
            try { return factory.interface.parseLog(log); } catch { return null; }
          })
          .find((e: any) => e?.name === 'CovenantDeployed');
        
        if (event) {
          logSuccess(`Covenant address: ${chalk.bold(event.args.covenant)}`);
          logInfo(`Transaction: ${tx.hash}`);
        }
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // covenant list
  covenant
    .command('list')
    .description('List deployed covenants')
    .option('-n, --network <network>', 'Target network')
    .option('-l, --limit <limit>', 'Number of results', '20')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        const factoryAddress = getContractAddress(network, 'CovenantFactory');
        const factory = getContract(factoryAddress, COVENANT_FACTORY_ABI, provider);
        
        const spinner = displaySpinner('Fetching covenants...');
        const count = await factory.covenantCount();
        const limit = Math.min(parseInt(options.limit), Number(count));
        
        const covenants = [];
        for (let i = 0; i < limit; i++) {
          try {
            const addr = await factory.covenants(i);
            const covenant = getContract(addr, COVENANT_ABI, provider);
            const [name, owner, status] = await Promise.all([
              covenant.name().catch(() => 'Unknown'),
              covenant.owner().catch(() => ethers.ZeroAddress),
              covenant.status().catch(() => 0)
            ]);
            covenants.push({ index: i, address: addr, name, owner, status });
          } catch {
            covenants.push({ index: i, address: 'Error', name: 'Error', owner: 'Error', status: 0 });
          }
        }
        
        spinner.succeed(`Found ${count} covenants (showing ${limit})`);
        
        console.log('\n' + chalk.bold.cyan('Covenants'));
        logDivider();
        covenants.forEach((c: any) => {
          const statusStr = ['Pending', 'Active', 'Executed', 'Terminated'][c.status] || 'Unknown';
          console.log(`  ${chalk.gray('#' + c.index)} ${chalk.bold(c.name)} ${chalk.gray(c.address)}`);
          console.log(`     Owner: ${c.owner} | Status: ${chalk.yellow(statusStr)}`);
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // covenant inspect
  covenant
    .command('inspect <address>')
    .description('Inspect a specific covenant')
    .option('-n, --network <network>', 'Target network')
    .action(async (address, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        const covenant = getContract(address, COVENANT_ABI, provider);
        
        const spinner = displaySpinner('Fetching covenant details...');
        const [name, version, owner, termsHash, status] = await Promise.all([
          covenant.name().catch(() => 'Unknown'),
          covenant.version().catch(() => 'Unknown'),
          covenant.owner().catch(() => ethers.ZeroAddress),
          covenant.termsHash().catch(() => ethers.ZeroHash),
          covenant.status().catch(() => 0)
        ]);
        spinner.succeed('Covenant details loaded');
        
        const statusStr = ['Pending', 'Active', 'Executed', 'Terminated'][status] || 'Unknown';
        
        console.log('\n' + chalk.bold.cyan('Covenant Details'));
        logDivider();
        logTable({
          Address: address,
          Name: name,
          Version: version,
          Owner: owner,
          'Terms Hash': termsHash,
          Status: statusStr,
          Network: network.name
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });
}
