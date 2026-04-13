import { Command } from 'commander';
import { ethers } from 'ethers';
import chalk from 'chalk';
import { loadConfig, getNetwork } from '../utils/config.js';
import { getProvider, validateNetwork, getBalance } from '../utils/network.js';
import { getWallet } from '../utils/wallet.js';
import { getContractAddress, getContract, ERC20_ABI } from '../utils/contracts.js';
import { estimateGas, checkBalance } from '../utils/gas.js';
import { confirmWithGas, displaySpinner } from '../utils/interactive.js';
import { logError, logInfo, logTable, logDivider } from '../utils/logger.js';

export function registerTokenCommands(program: Command): void {
  const token = program
    .command('token')
    .description('Manage ERC20 tokens');

  // token balance
  token
    .command('balance [address]')
    .description('Check token balance')
    .option('-n, --network <network>', 'Target network')
    .option('--contract <address>', 'Token contract address')
    .action(async (address, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        // Get token address
        let tokenAddress: string;
        if (options.contract) {
          tokenAddress = options.contract;
        } else {
          try {
            tokenAddress = getContractAddress(network, 'CovenantToken');
          } catch {
            const inquirer = await import('inquirer');
            const answers = await inquirer.default.prompt([{
              type: 'input',
              name: 'contract',
              message: 'Token contract address:',
              validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
            }]);
            tokenAddress = answers.contract;
          }
        }
        
        // Get target address
        let targetAddress = address;
        if (!targetAddress) {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'input',
            name: 'address',
            message: 'Address to check (leave empty for wallet list):',
          }]);
          targetAddress = answers.address;
        }
        
        const tokenContract = getContract(tokenAddress, ERC20_ABI, provider);
        
        const spinner = displaySpinner('Fetching token info...');
        const [name, symbol, decimals, totalSupply] = await Promise.all([
          tokenContract.name().catch(() => 'Unknown'),
          tokenContract.symbol().catch(() => '???'),
          tokenContract.decimals().catch(() => 18),
          tokenContract.totalSupply().catch(() => 0n)
        ]);
        spinner.succeed('Token info loaded');
        
        console.log('\n' + chalk.bold.cyan(`${name} (${symbol})`));
        logDivider();
        logTable({
          Address: tokenAddress,
          Decimals: decimals,
          'Total Supply': ethers.formatUnits(totalSupply, decimals)
        });
        
        if (targetAddress && ethers.isAddress(targetAddress)) {
          const balance = await tokenContract.balanceOf(targetAddress);
          console.log('\n' + chalk.bold('Balance:'));
          logTable({
            Address: targetAddress,
            Balance: ethers.formatUnits(balance, decimals)
          });
        } else {
          // Show ETH balance as well
          const { listWallets } = await import('../utils/wallet.js');
          const wallets = listWallets();
          
          if (wallets.length > 0) {
            console.log('\n' + chalk.bold('Wallet Balances:'));
            for (const w of wallets) {
              const bal = await tokenContract.balanceOf(w.address);
              const ethBal = await getBalance(provider, w.address);
              console.log(`  ${w.name}: ${ethers.formatUnits(bal, decimals)} ${symbol} | ${ethBal} ETH`);
            }
          }
        }
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // token transfer
  token
    .command('transfer')
    .description('Transfer tokens')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--to <address>', 'Recipient address')
    .option('--amount <amount>', 'Amount to transfer')
    .option('--contract <address>', 'Token contract address')
    .option('--dry-run', 'Simulate without sending')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        
        // Get token address
        let tokenAddress: string;
        if (options.contract) {
          tokenAddress = options.contract;
        } else {
          try {
            tokenAddress = getContractAddress(network, 'CovenantToken');
          } catch {
            const inquirer = await import('inquirer');
            const answers = await inquirer.default.prompt([{
              type: 'input',
              name: 'contract',
              message: 'Token contract address:',
              validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
            }]);
            tokenAddress = answers.contract;
          }
        }
        
        const tokenContract = getContract(tokenAddress, ERC20_ABI, wallet);
        const decimals = await tokenContract.decimals().catch(() => 18);
        const symbol = await tokenContract.symbol().catch(() => '???');
        
        const inquirer = await import('inquirer');
        const answers = await inquirer.default.prompt([
          {
            type: 'input',
            name: 'to',
            message: 'Recipient address:',
            when: !options.to,
            validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
          },
          {
            type: 'input',
            name: 'amount',
            message: `Amount (${symbol}):`,
            when: !options.amount,
            validate: (input: string) => {
              try {
                ethers.parseUnits(input, decimals);
                return true;
              } catch {
                return 'Invalid amount';
              }
            }
          }
        ]);
        
        const to = options.to || answers.to;
        const amount = ethers.parseUnits(options.amount || answers.amount, decimals);
        
        const txRequest = await tokenContract.transfer.populateTransaction(to, amount);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Transfer Tokens',
          {
            Token: `${symbol} (${tokenAddress})`,
            To: to,
            Amount: ethers.formatUnits(amount, decimals),
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
        
        const spinner = displaySpinner('Transferring tokens...');
        const tx = await tokenContract.transfer(to, amount);
        await tx.wait();
        spinner.succeed('Transfer completed');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // token approve
  token
    .command('approve')
    .description('Approve token spending')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--spender <address>', 'Spender address')
    .option('--amount <amount>', 'Amount to approve (use "max" for unlimited)')
    .option('--contract <address>', 'Token contract address')
    .option('--dry-run', 'Simulate without sending')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        
        // Get token address
        let tokenAddress: string;
        if (options.contract) {
          tokenAddress = options.contract;
        } else {
          try {
            tokenAddress = getContractAddress(network, 'CovenantToken');
          } catch {
            const inquirer = await import('inquirer');
            const answers = await inquirer.default.prompt([{
              type: 'input',
              name: 'contract',
              message: 'Token contract address:',
              validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
            }]);
            tokenAddress = answers.contract;
          }
        }
        
        const tokenContract = getContract(tokenAddress, ERC20_ABI, wallet);
        const decimals = await tokenContract.decimals().catch(() => 18);
        const symbol = await tokenContract.symbol().catch(() => '???');
        
        const inquirer = await import('inquirer');
        const answers = await inquirer.default.prompt([
          {
            type: 'input',
            name: 'spender',
            message: 'Spender address:',
            when: !options.spender,
            validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
          },
          {
            type: 'input',
            name: 'amount',
            message: `Amount to approve (${symbol} or "max"):`,
            when: !options.amount,
            validate: (input: string) => input.toLowerCase() === 'max' || (() => {
              try {
                ethers.parseUnits(input, decimals);
                return true;
              } catch {
                return 'Invalid amount or use "max"';
              }
            })()
          }
        ]);
        
        const spender = options.spender || answers.spender;
        const amountStr = (options.amount || answers.amount).toLowerCase();
        const amount = amountStr === 'max' 
          ? ethers.MaxUint256 
          : ethers.parseUnits(amountStr, decimals);
        
        const txRequest = await tokenContract.approve.populateTransaction(spender, amount);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Approve Token Spending',
          {
            Token: `${symbol} (${tokenAddress})`,
            Spender: spender,
            Amount: amountStr === 'max' ? 'Unlimited' : ethers.formatUnits(amount, decimals),
            Network: network.name
          },
          gasEstimate,
          options.dryRun || config.dryRun
        );
        
        if (!confirmed) {
          logInfo('Cancelled or dry-run.');
          return;
        }
        
        const spinner = displaySpinner('Approving...');
        const tx = await tokenContract.approve(spender, amount);
        await tx.wait();
        spinner.succeed('Approval granted');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // token allowance
  token
    .command('allowance')
    .description('Check token allowance')
    .option('-n, --network <network>', 'Target network')
    .option('--owner <address>', 'Owner address')
    .option('--spender <address>', 'Spender address')
    .option('--contract <address>', 'Token contract address')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        // Get token address
        let tokenAddress: string;
        if (options.contract) {
          tokenAddress = options.contract;
        } else {
          try {
            tokenAddress = getContractAddress(network, 'CovenantToken');
          } catch {
            const inquirer = await import('inquirer');
            const answers = await inquirer.default.prompt([{
              type: 'input',
              name: 'contract',
              message: 'Token contract address:',
              validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
            }]);
            tokenAddress = answers.contract;
          }
        }
        
        const tokenContract = getContract(tokenAddress, ERC20_ABI, provider);
        const decimals = await tokenContract.decimals().catch(() => 18);
        const symbol = await tokenContract.symbol().catch(() => '???');
        
        const inquirer = await import('inquirer');
        const answers = await inquirer.default.prompt([
          {
            type: 'input',
            name: 'owner',
            message: 'Owner address:',
            when: !options.owner,
            validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
          },
          {
            type: 'input',
            name: 'spender',
            message: 'Spender address:',
            when: !options.spender,
            validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
          }
        ]);
        
        const owner = options.owner || answers.owner;
        const spender = options.spender || answers.spender;
        
        const spinner = displaySpinner('Fetching allowance...');
        const allowance = await tokenContract.allowance(owner, spender);
        spinner.succeed('Allowance fetched');
        
        console.log('\n' + chalk.bold.cyan('Token Allowance'));
        logDivider();
        logTable({
          Token: `${symbol} (${tokenAddress})`,
          Owner: owner,
          Spender: spender,
          Allowance: ethers.formatUnits(allowance, decimals)
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });
}
