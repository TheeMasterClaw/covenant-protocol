import { Command } from 'commander';
import { ethers } from 'ethers';
import chalk from 'chalk';
import { loadConfig, getNetwork } from '../utils/config.js';
import { getProvider, validateNetwork } from '../utils/network.js';
import { getWallet } from '../utils/wallet.js';
import { getContractAddress, getContract, TASK_REGISTRY_ABI } from '../utils/contracts.js';
import { estimateGas, checkBalance } from '../utils/gas.js';
import { confirmWithGas, displaySpinner } from '../utils/interactive.js';
import { logSuccess, logError, logInfo, logTable, logDivider } from '../utils/logger.js';

export function registerTaskCommands(program: Command): void {
  const task = program
    .command('task')
    .description('Manage tasks and bids');

  // task create
  task
    .command('create')
    .description('Create a new task')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--title <title>', 'Task title')
    .option('--description <desc>', 'Task description')
    .option('--reward <reward>', 'Task reward in ETH')
    .option('--deadline <timestamp>', 'Deadline as Unix timestamp')
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
            name: 'title',
            message: 'Task title:',
            when: !options.title,
            validate: (input: string) => input.length > 0 || 'Title required'
          },
          {
            type: 'input',
            name: 'description',
            message: 'Task description:',
            when: !options.description,
            validate: (input: string) => input.length > 0 || 'Description required'
          },
          {
            type: 'input',
            name: 'reward',
            message: 'Reward (ETH):',
            when: !options.reward,
            validate: (input: string) => {
              try {
                ethers.parseEther(input);
                return true;
              } catch {
                return 'Invalid amount';
              }
            }
          },
          {
            type: 'input',
            name: 'deadline',
            message: 'Deadline (Unix timestamp):',
            when: !options.deadline,
            validate: (input: string) => !isNaN(Number(input)) || 'Invalid timestamp'
          }
        ]);
        
        const title = options.title || answers.title;
        const description = options.description || answers.description;
        const reward = ethers.parseEther(options.reward || answers.reward);
        const deadline = BigInt(options.deadline || answers.deadline);
        
        const registryAddress = getContractAddress(network, 'TaskRegistry');
        const registry = getContract(registryAddress, TASK_REGISTRY_ABI, wallet);
        
        const txRequest = await registry.createTask.populateTransaction(title, description, reward, deadline);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address, value: reward }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Create Task',
          {
            Title: title,
            Reward: ethers.formatEther(reward) + ' ETH',
            Deadline: new Date(Number(deadline) * 1000).toISOString(),
            Network: network.name
          },
          gasEstimate,
          options.dryRun || config.dryRun
        );
        
        if (!confirmed) {
          logInfo('Cancelled or dry-run.');
          return;
        }
        
        await checkBalance(provider, wallet.address, gasEstimate.estimatedCost + reward);
        
        const spinner = displaySpinner('Creating task...');
        const tx = await registry.createTask(title, description, reward, deadline, { value: reward });
        const receipt = await tx.wait();
        spinner.succeed('Task created');
        
        const event = receipt?.logs
          .map((log: any) => {
            try { return registry.interface.parseLog(log); } catch { return null; }
          })
          .find((e: any) => e?.name === 'TaskCreated');
        
        if (event) {
          logSuccess(`Task ID: ${event.args.taskId.toString()}`);
        }
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // task bid
  task
    .command('bid <taskId>')
    .description('Place a bid on a task')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--amount <amount>', 'Bid amount in ETH')
    .option('--proposal <proposal>', 'Bid proposal text')
    .option('--dry-run', 'Simulate without sending')
    .action(async (taskId, options) => {
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
            name: 'amount',
            message: 'Bid amount (ETH):',
            when: !options.amount,
            validate: (input: string) => {
              try { ethers.parseEther(input); return true; } catch { return 'Invalid amount'; }
            }
          },
          {
            type: 'input',
            name: 'proposal',
            message: 'Proposal:',
            when: !options.proposal,
            validate: (input: string) => input.length > 0 || 'Proposal required'
          }
        ]);
        
        const amount = ethers.parseEther(options.amount || answers.amount);
        const proposal = options.proposal || answers.proposal;
        
        const registryAddress = getContractAddress(network, 'TaskRegistry');
        const registry = getContract(registryAddress, TASK_REGISTRY_ABI, wallet);
        
        const txRequest = await registry.bid.populateTransaction(taskId, amount, proposal);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Submit Bid',
          {
            'Task ID': taskId,
            Amount: ethers.formatEther(amount) + ' ETH',
            Proposal: proposal,
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
        
        const spinner = displaySpinner('Submitting bid...');
        const tx = await registry.bid(taskId, amount, proposal);
        await tx.wait();
        spinner.succeed('Bid submitted');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // task list
  task
    .command('list')
    .description('List tasks')
    .option('-n, --network <network>', 'Target network')
    .option('-l, --limit <limit>', 'Number of results', '20')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        const registryAddress = getContractAddress(network, 'TaskRegistry');
        const registry = getContract(registryAddress, TASK_REGISTRY_ABI, provider);
        
        const spinner = displaySpinner('Fetching tasks...');
        const count = await registry.taskCount();
        const limit = Math.min(parseInt(options.limit), Number(count));
        
        const tasks = [];
        for (let i = 1; i <= limit; i++) {
          try {
            const t = await registry.tasks(i);
            const statusStr = ['Open', 'Bidding', 'Assigned', 'Completed', 'Cancelled'][t.status] || 'Unknown';
            tasks.push({
              id: t.id.toString(),
              creator: t.creator,
              title: t.title,
              reward: ethers.formatEther(t.reward),
              deadline: new Date(Number(t.deadline) * 1000).toISOString(),
              status: statusStr
            });
          } catch {
            // skip
          }
        }
        
        spinner.succeed(`Found ${count} tasks (showing ${limit})`);
        
        console.log('\n' + chalk.bold.cyan('Tasks'));
        logDivider();
        tasks.forEach((t: any) => {
          console.log(`  ${chalk.gray('#' + t.id)} ${chalk.bold(t.title)} ${chalk.green(t.reward + ' ETH')}`);
          console.log(`     Creator: ${t.creator} | Status: ${chalk.yellow(t.status)} | Due: ${t.deadline}`);
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // task inspect
  task
    .command('inspect <taskId>')
    .description('Inspect a task and its bids')
    .option('-n, --network <network>', 'Target network')
    .action(async (taskId, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        const registryAddress = getContractAddress(network, 'TaskRegistry');
        const registry = getContract(registryAddress, TASK_REGISTRY_ABI, provider);
        
        const spinner = displaySpinner('Loading task...');
        const t = await registry.tasks(taskId);
        const bids = await registry.getBids(taskId);
        spinner.succeed('Task loaded');
        
        const statusStr = ['Open', 'Bidding', 'Assigned', 'Completed', 'Cancelled'][t.status] || 'Unknown';
        
        console.log('\n' + chalk.bold.cyan('Task Details'));
        logDivider();
        logTable({
          ID: taskId,
          Title: t.title,
          Creator: t.creator,
          Reward: ethers.formatEther(t.reward) + ' ETH',
          Deadline: new Date(Number(t.deadline) * 1000).toISOString(),
          Status: statusStr
        });
        
        console.log('\n' + chalk.bold('Bids:'));
        if (bids.length === 0) {
          console.log('  No bids yet.');
        } else {
          bids.forEach((bid: any, idx: number) => {
            const bidStatus = ['Pending', 'Accepted', 'Rejected'][bid.status] || 'Unknown';
            console.log(`  ${chalk.gray('#' + idx)} ${bid.bidder} | ${ethers.formatEther(bid.amount)} ETH | ${bidStatus}`);
            console.log(`     Proposal: ${bid.proposal}`);
          });
        }
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });
}
