import { Command } from 'commander';
import { ethers } from 'ethers';
import chalk from 'chalk';
import { loadConfig, getNetwork } from '../utils/config.js';
import { getProvider, validateNetwork } from '../utils/network.js';
import { getWallet } from '../utils/wallet.js';
import { getContractAddress, getContract, GOVERNANCE_ABI } from '../utils/contracts.js';
import { estimateGas, checkBalance } from '../utils/gas.js';
import { confirmWithGas, displaySpinner } from '../utils/interactive.js';
import { logSuccess, logError, logInfo, logTable, logDivider } from '../utils/logger.js';

export function registerGovernanceCommands(program: Command): void {
  const governance = program
    .command('governance')
    .description('Participate in protocol governance');

  // governance vote
  governance
    .command('vote <proposalId>')
    .description('Vote on a proposal')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--support', 'Vote in favor')
    .option('--against', 'Vote against')
    .option('--dry-run', 'Simulate without sending')
    .action(async (proposalId, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        
        let support: boolean;
        if (options.support) {
          support = true;
        } else if (options.against) {
          support = false;
        } else {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'list',
            name: 'vote',
            message: 'Your vote:',
            choices: [
              { name: 'For', value: true },
              { name: 'Against', value: false }
            ]
          }]);
          support = answers.vote;
        }
        
        const governanceAddress = getContractAddress(network, 'Governance');
        const gov = getContract(governanceAddress, GOVERNANCE_ABI, wallet);
        
        const txRequest = await gov.vote.populateTransaction(proposalId, support);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Cast Vote',
          {
            'Proposal ID': proposalId,
            Vote: support ? 'For' : 'Against',
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
        
        const spinner = displaySpinner('Casting vote...');
        const tx = await gov.vote(proposalId, support);
        await tx.wait();
        spinner.succeed('Vote cast successfully');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // governance propose
  governance
    .command('propose')
    .description('Create a new proposal')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--description <text>', 'Proposal description')
    .option('--target <address>', 'Target contract address')
    .option('--calldata <hex>', 'Call data (hex)')
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
            name: 'description',
            message: 'Proposal description:',
            when: !options.description,
            validate: (input: string) => input.length > 0 || 'Description required'
          },
          {
            type: 'input',
            name: 'target',
            message: 'Target contract address:',
            when: !options.target,
            validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
          },
          {
            type: 'input',
            name: 'calldata',
            message: 'Call data (hex, optional):',
            when: !options.calldata,
            default: '0x'
          }
        ]);
        
        const description = options.description || answers.description;
        const target = options.target || answers.target;
        const calldata = options.calldata || answers.calldata || '0x';
        
        const governanceAddress = getContractAddress(network, 'Governance');
        const gov = getContract(governanceAddress, GOVERNANCE_ABI, wallet);
        
        const txRequest = await gov.propose.populateTransaction(description, target, calldata);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Create Proposal',
          {
            Description: description,
            Target: target,
            'Call Data': calldata.length > 20 ? calldata.slice(0, 20) + '...' : calldata,
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
        
        const spinner = displaySpinner('Creating proposal...');
        const tx = await gov.propose(description, target, calldata);
        const receipt = await tx.wait();
        spinner.succeed('Proposal created');
        
        const event = receipt?.logs
          .map((log: any) => {
            try { return gov.interface.parseLog(log); } catch { return null; }
          })
          .find((e: any) => e?.name === 'ProposalCreated');
        
        if (event) {
          logSuccess(`Proposal ID: ${event.args.proposalId.toString()}`);
        }
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // governance list
  governance
    .command('list')
    .description('List proposals')
    .option('-n, --network <network>', 'Target network')
    .option('-l, --limit <limit>', 'Number of results', '20')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        const governanceAddress = getContractAddress(network, 'Governance');
        const gov = getContract(governanceAddress, GOVERNANCE_ABI, provider);
        
        const spinner = displaySpinner('Fetching proposals...');
        const count = await gov.proposalCount();
        const limit = Math.min(parseInt(options.limit), Number(count));
        
        const proposals = [];
        for (let i = 1; i <= limit; i++) {
          try {
            const p = await gov.proposals(i);
            const statusStr = ['Pending', 'Active', 'Canceled', 'Defeated', 'Succeeded', 'Queued', 'Executed'][p.status] || 'Unknown';
            proposals.push({
              id: p.id.toString(),
              description: p.description,
              proposer: p.proposer,
              forVotes: p.forVotes.toString(),
              againstVotes: p.againstVotes.toString(),
              status: statusStr
            });
          } catch {
            // skip
          }
        }
        
        spinner.succeed(`Found ${count} proposals (showing ${limit})`);
        
        console.log('\n' + chalk.bold.cyan('Proposals'));
        logDivider();
        proposals.forEach((p: any) => {
          console.log(`  ${chalk.gray('#' + p.id)} ${chalk.bold(p.description.slice(0, 50))}${p.description.length > 50 ? '...' : ''}`);
          console.log(`     Proposer: ${p.proposer} | Status: ${chalk.yellow(p.status)}`);
          console.log(`     For: ${chalk.green(p.forVotes)} | Against: ${chalk.red(p.againstVotes)}`);
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // governance inspect
  governance
    .command('inspect <proposalId>')
    .description('Inspect a proposal')
    .option('-n, --network <network>', 'Target network')
    .option('-a, --address <address>', 'Address to check vote status for')
    .action(async (proposalId, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        const governanceAddress = getContractAddress(network, 'Governance');
        const gov = getContract(governanceAddress, GOVERNANCE_ABI, provider);
        
        const spinner = displaySpinner('Loading proposal...');
        const p = await gov.proposals(proposalId);
        spinner.succeed('Proposal loaded');
        
        const statusStr = ['Pending', 'Active', 'Canceled', 'Defeated', 'Succeeded', 'Queued', 'Executed'][p.status] || 'Unknown';
        
        console.log('\n' + chalk.bold.cyan('Proposal Details'));
        logDivider();
        logTable({
          ID: proposalId,
          Description: p.description,
          Proposer: p.proposer,
          'For Votes': p.forVotes.toString(),
          'Against Votes': p.againstVotes.toString(),
          Status: statusStr,
          Network: network.name
        });
        
        if (options.address) {
          const hasVoted = await gov.hasVoted(proposalId, options.address);
          console.log(`\n  ${options.address} has voted: ${hasVoted ? chalk.green('Yes') : chalk.red('No')}`);
        }
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // governance execute
  governance
    .command('execute <proposalId>')
    .description('Execute a passed proposal')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--dry-run', 'Simulate without sending')
    .action(async (proposalId, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        
        const governanceAddress = getContractAddress(network, 'Governance');
        const gov = getContract(governanceAddress, GOVERNANCE_ABI, wallet);
        
        const txRequest = await gov.execute.populateTransaction(proposalId);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Execute Proposal',
          {
            'Proposal ID': proposalId,
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
        
        const spinner = displaySpinner('Executing proposal...');
        const tx = await gov.execute(proposalId);
        await tx.wait();
        spinner.succeed('Proposal executed');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });
}
