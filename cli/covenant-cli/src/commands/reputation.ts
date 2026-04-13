import { Command } from 'commander';
import { ethers } from 'ethers';
import chalk from 'chalk';
import { loadConfig, getNetwork } from '../utils/config.js';
import { getProvider, validateNetwork } from '../utils/network.js';
import { getWallet } from '../utils/wallet.js';
import { getContractAddress, getContract, REPUTATION_ABI } from '../utils/contracts.js';
import { estimateGas, checkBalance } from '../utils/gas.js';
import { confirmWithGas, displaySpinner } from '../utils/interactive.js';
import { logError, logInfo, logTable, logDivider } from '../utils/logger.js';

export function registerReputationCommands(program: Command): void {
  const reputation = program
    .command('reputation')
    .description('Manage reputation and staking');

  // reputation stake
  reputation
    .command('stake')
    .description('Stake tokens for reputation')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--amount <amount>', 'Amount to stake in tokens')
    .option('--dry-run', 'Simulate without sending')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        
        let amount: bigint;
        if (options.amount) {
          amount = ethers.parseUnits(options.amount, 18);
        } else {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'input',
            name: 'amount',
            message: 'Amount to stake:',
            validate: (input: string) => {
              try {
                ethers.parseUnits(input, 18);
                return true;
              } catch {
                return 'Invalid amount';
              }
            }
          }]);
          amount = ethers.parseUnits(answers.amount, 18);
        }
        
        const reputationAddress = getContractAddress(network, 'Reputation');
        const reputationContract = getContract(reputationAddress, REPUTATION_ABI, wallet);
        
        const txRequest = await reputationContract.stake.populateTransaction(amount);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Stake for Reputation',
          {
            Amount: ethers.formatUnits(amount, 18),
            Contract: reputationAddress,
            Network: network.name
          },
          gasEstimate,
          options.dryRun || config.dryRun
        );
        
        if (!confirmed) {
          logInfo('Cancelled or dry-run.');
          return;
        }
        
        await checkBalance(provider, wallet.address, gasEstimate.estimatedCost);
        
        const spinner = displaySpinner('Staking tokens...');
        const tx = await reputationContract.stake(amount);
        await tx.wait();
        spinner.succeed('Tokens staked successfully');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // reputation unstake
  reputation
    .command('unstake')
    .description('Unstake tokens')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--amount <amount>', 'Amount to unstake in tokens')
    .option('--dry-run', 'Simulate without sending')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        
        let amount: bigint;
        if (options.amount) {
          amount = ethers.parseUnits(options.amount, 18);
        } else {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'input',
            name: 'amount',
            message: 'Amount to unstake:',
            validate: (input: string) => {
              try {
                ethers.parseUnits(input, 18);
                return true;
              } catch {
                return 'Invalid amount';
              }
            }
          }]);
          amount = ethers.parseUnits(answers.amount, 18);
        }
        
        const reputationAddress = getContractAddress(network, 'Reputation');
        const reputationContract = getContract(reputationAddress, REPUTATION_ABI, wallet);
        
        const txRequest = await reputationContract.unstake.populateTransaction(amount);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Unstake Tokens',
          {
            Amount: ethers.formatUnits(amount, 18),
            Contract: reputationAddress,
            Network: network.name
          },
          gasEstimate,
          options.dryRun || config.dryRun
        );
        
        if (!confirmed) {
          logInfo('Cancelled or dry-run.');
          return;
        }
        
        await checkBalance(provider, wallet.address, gasEstimate.estimatedCost);
        
        const spinner = displaySpinner('Unstaking tokens...');
        const tx = await reputationContract.unstake(amount);
        await tx.wait();
        spinner.succeed('Tokens unstaked successfully');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // reputation get
  reputation
    .command('get [address]')
    .description('Get reputation score for an address')
    .option('-n, --network <network>', 'Target network')
    .action(async (address, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        let targetAddress = address;
        if (!targetAddress) {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'input',
            name: 'address',
            message: 'Address to check:',
            validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
          }]);
          targetAddress = answers.address;
        }
        
        const reputationAddress = getContractAddress(network, 'Reputation');
        const reputationContract = getContract(reputationAddress, REPUTATION_ABI, provider);
        
        const spinner = displaySpinner('Fetching reputation...');
        const [score, staked] = await reputationContract.getReputation(targetAddress);
        const totalStaked = await reputationContract.totalStaked();
        spinner.succeed('Reputation loaded');
        
        console.log('\n' + chalk.bold.cyan('Reputation Info'));
        logDivider();
        logTable({
          Address: targetAddress,
          'Reputation Score': score.toString(),
          'Staked Amount': ethers.formatUnits(staked, 18),
          'Total Staked': ethers.formatUnits(totalStaked, 18)
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // reputation slash
  reputation
    .command('slash')
    .description('Slash a user\'s reputation (admin only)')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--target <address>', 'Address to slash')
    .option('--amount <amount>', 'Amount to slash')
    .option('--dry-run', 'Simulate without sending')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        
        const inquirer = await import('inquirer');
        const answers = await inquirer.default.prompt([
          {
            type: 'input',
            name: 'target',
            message: 'Address to slash:',
            when: !options.target,
            validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
          },
          {
            type: 'input',
            name: 'amount',
            message: 'Amount to slash:',
            when: !options.amount,
            validate: (input: string) => {
              try {
                ethers.parseUnits(input, 18);
                return true;
              } catch {
                return 'Invalid amount';
              }
            }
          }
        ]);
        
        const target = options.target || answers.target;
        const amount = ethers.parseUnits(options.amount || answers.amount, 18);
        
        const reputationAddress = getContractAddress(network, 'Reputation');
        const reputationContract = getContract(reputationAddress, REPUTATION_ABI, wallet);
        
        const txRequest = await reputationContract.slash.populateTransaction(target, amount);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Slash Reputation',
          {
            Target: target,
            Amount: ethers.formatUnits(amount, 18),
            Network: network.name
          },
          gasEstimate,
          options.dryRun || config.dryRun
        );
        
        if (!confirmed) {
          logInfo('Cancelled or dry-run.');
          return;
        }
        
        const spinner = displaySpinner('Slashing...');
        const tx = await reputationContract.slash(target, amount);
        await tx.wait();
        spinner.succeed('Slash completed');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });
}
