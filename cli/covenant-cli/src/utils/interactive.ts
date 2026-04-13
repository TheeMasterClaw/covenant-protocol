import inquirer from 'inquirer';
import chalk from 'chalk';
import { ethers } from 'ethers';
import ora from 'ora';
import { listWallets } from './wallet.js';
import { loadConfig } from './config.js';
import { GasEstimate } from './gas.js';

export async function confirmTransaction(
  description: string,
  details: Record<string, string | number | undefined>,
  dryRun: boolean = false
): Promise<boolean> {
  console.log('\n' + chalk.bold.cyan('Transaction Summary'));
  console.log(chalk.gray('─'.repeat(50)));
  console.log(chalk.bold('Action:'), description);
  console.log(chalk.gray('─'.repeat(50)));
  
  Object.entries(details).forEach(([key, value]) => {
    const formattedValue = value === undefined ? chalk.gray('N/A') : String(value);
    console.log(`  ${chalk.cyan(key)}: ${formattedValue}`);
  });
  
  console.log(chalk.gray('─'.repeat(50)));
  
  if (dryRun) {
    console.log(chalk.yellow('🧪 DRY RUN MODE - No transaction will be sent'));
    return false;
  }
  
  const { confirm } = await inquirer.prompt([{
    type: 'confirm',
    name: 'confirm',
    message: 'Proceed with this transaction?',
    default: false
  }]);
  
  return confirm;
}

export async function confirmWithGas(
  description: string,
  details: Record<string, string | number | undefined>,
  gasEstimate: GasEstimate,
  dryRun: boolean = false
): Promise<boolean> {
  console.log('\n' + chalk.bold.cyan('Transaction Summary'));
  console.log(chalk.gray('─'.repeat(50)));
  console.log(chalk.bold('Action:'), description);
  console.log(chalk.gray('─'.repeat(50)));
  
  Object.entries(details).forEach(([key, value]) => {
    const formattedValue = value === undefined ? chalk.gray('N/A') : String(value);
    console.log(`  ${chalk.cyan(key)}: ${formattedValue}`);
  });
  
  console.log(chalk.gray('─'.repeat(50)));
  console.log(chalk.bold.yellow('Gas Estimate:'));
  console.log(`  Gas Limit: ${gasEstimate.gasLimit.toString()}`);
  console.log(`  Gas Price: ${ethers.formatUnits(gasEstimate.gasPrice, 'gwei')} gwei`);
  console.log(`  Est. Cost: ${chalk.bold(gasEstimate.estimatedCostEth)} ETH`);
  console.log(chalk.gray('─'.repeat(50)));
  
  if (dryRun) {
    console.log(chalk.yellow('🧪 DRY RUN MODE - No transaction will be sent'));
    return false;
  }
  
  const { confirm } = await inquirer.prompt([{
    type: 'confirm',
    name: 'confirm',
    message: 'Proceed with this transaction?',
    default: false
  }]);
  
  return confirm;
}

export async function selectWallet(): Promise<string> {
  const wallets = listWallets();
  
  if (wallets.length === 0) {
    throw new Error('No wallets found. Create one first.');
  }
  
  const { wallet } = await inquirer.prompt([{
    type: 'list',
    name: 'wallet',
    message: 'Select wallet:',
    choices: wallets.map(w => ({
      name: `${w.name} (${w.address})`,
      value: w.name
    }))
  }]);
  
  return wallet;
}

export async function selectNetwork(): Promise<string> {
  const config = loadConfig();
  
  const { network } = await inquirer.prompt([{
    type: 'list',
    name: 'network',
    message: 'Select network:',
    default: config.defaultNetwork,
    choices: config.networks.map(n => ({
      name: `${n.name} (chainId: ${n.chainId})`,
      value: n.name
    }))
  }]);
  
  return network;
}

export async function inputAddress(message: string, required: boolean = true): Promise<string> {
  const { address } = await inquirer.prompt([{
    type: 'input',
    name: 'address',
    message,
    validate: (input: string) => {
      if (!required && !input) return true;
      if (!ethers.isAddress(input)) return 'Invalid Ethereum address';
      return true;
    }
  }]);
  
  return address;
}

export async function inputAmount(message: string, required: boolean = true): Promise<string> {
  const { amount } = await inquirer.prompt([{
    type: 'input',
    name: 'amount',
    message,
    validate: (input: string) => {
      if (!required && !input) return true;
      try {
        const parsed = ethers.parseEther(input);
        if (parsed <= 0n) return 'Amount must be greater than 0';
        return true;
      } catch {
        return 'Invalid amount (e.g., 0.1, 1.5)';
      }
    }
  }]);
  
  return amount;
}

export async function inputBigInt(message: string, required: boolean = true): Promise<string> {
  const { value } = await inquirer.prompt([{
    type: 'input',
    name: 'value',
    message,
    validate: (input: string) => {
      if (!required && !input) return true;
      try {
        BigInt(input);
        return true;
      } catch {
        return 'Invalid number';
      }
    }
  }]);
  
  return value;
}

export async function inputJson(message: string, required: boolean = true): Promise<Record<string, unknown>> {
  const { json } = await inquirer.prompt([{
    type: 'editor',
    name: 'json',
    message: `${message} (JSON format):`,
    validate: (input: string) => {
      if (!required && !input) return true;
      try {
        JSON.parse(input);
        return true;
      } catch {
        return 'Invalid JSON';
      }
    }
  }]);
  
  return JSON.parse(json || '{}');
}

export function displaySpinner(message: string): { succeed: (msg?: string) => void; fail: (msg?: string) => void } {
  const spinner = ora(message).start();
  
  return {
    succeed: (msg?: string) => spinner.succeed(msg),
    fail: (msg?: string) => spinner.fail(msg)
  };
}

export async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
