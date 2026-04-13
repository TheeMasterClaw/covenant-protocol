import { Command } from 'commander';
import { ethers } from 'ethers';
import chalk from 'chalk';
import { loadConfig, getNetwork } from '../utils/config.js';
import { getProvider, validateNetwork } from '../utils/network.js';
import { getWallet } from '../utils/wallet.js';
import { getContractAddress, getContract, DISPUTE_ARBITER_ABI } from '../utils/contracts.js';
import { estimateGas, checkBalance } from '../utils/gas.js';
import { confirmWithGas, displaySpinner } from '../utils/interactive.js';
import { logSuccess, logError, logInfo, logTable, logDivider } from '../utils/logger.js';

export function registerDisputeCommands(program: Command): void {
  const dispute = program
    .command('dispute')
    .description('Manage disputes');

  // dispute file
  dispute
    .command('file')
    .description('File a dispute against a covenant')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--covenant <address>', 'Covenant address')
    .option('--reason <reason>', 'Reason for dispute')
    .option('--evidence <hex>', 'Evidence as hex data', '0x')
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
            name: 'covenant',
            message: 'Covenant address:',
            when: !options.covenant,
            validate: (input: string) => ethers.isAddress(input) || 'Invalid address'
          },
          {
            type: 'input',
            name: 'reason',
            message: 'Reason for dispute:',
            when: !options.reason,
            validate: (input: string) => input.length > 0 || 'Reason required'
          }
        ]);
        
        const covenant = options.covenant || answers.covenant;
        const reason = options.reason || answers.reason;
        const evidence = options.evidence || '0x';
        
        const arbiterAddress = getContractAddress(network, 'DisputeArbiter');
        const arbiter = getContract(arbiterAddress, DISPUTE_ARBITER_ABI, wallet);
        
        const txRequest = await arbiter.fileDispute.populateTransaction(covenant, reason, evidence);
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'File Dispute',
          {
            Covenant: covenant,
            Reason: reason,
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
        
        const spinner = displaySpinner('Filing dispute...');
        const tx = await arbiter.fileDispute(covenant, reason, evidence);
        const receipt = await tx.wait();
        spinner.succeed('Dispute filed');
        
        const event = receipt?.logs
          .map((log: any) => {
            try { return arbiter.interface.parseLog(log); } catch { return null; }
          })
          .find((e: any) => e?.name === 'DisputeFiled');
        
        if (event) {
          logSuccess(`Dispute ID: ${event.args.disputeId.toString()}`);
        }
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // dispute list
  dispute
    .command('list')
    .description('List disputes')
    .option('-n, --network <network>', 'Target network')
    .option('-l, --limit <limit>', 'Number of results', '20')
    .action(async (options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        const arbiterAddress = getContractAddress(network, 'DisputeArbiter');
        const arbiter = getContract(arbiterAddress, DISPUTE_ARBITER_ABI, provider);
        
        const spinner = displaySpinner('Fetching disputes...');
        const count = await arbiter.disputeCount();
        const limit = Math.min(parseInt(options.limit), Number(count));
        
        const disputes = [];
        for (let i = 1; i <= limit; i++) {
          try {
            const d = await arbiter.disputes(i);
            const statusStr = ['Pending', 'Resolved', 'Appealed', 'Dismissed'][d.status] || 'Unknown';
            const rulingStr = ['None', 'ForComplainant', 'ForDefendant'][d.ruling] || 'None';
            disputes.push({
              id: d.id.toString(),
              covenant: d.covenant,
              complainant: d.complainant,
              reason: d.reason,
              status: statusStr,
              ruling: rulingStr
            });
          } catch {
            // skip
          }
        }
        
        spinner.succeed(`Found ${count} disputes (showing ${limit})`);
        
        console.log('\n' + chalk.bold.cyan('Disputes'));
        logDivider();
        disputes.forEach((d: any) => {
          console.log(`  ${chalk.gray('#' + d.id)} ${chalk.bold(d.reason)}`);
          console.log(`     Covenant: ${d.covenant} | Complainant: ${d.complainant}`);
          console.log(`     Status: ${chalk.yellow(d.status)} | Ruling: ${d.ruling}`);
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // dispute inspect
  dispute
    .command('inspect <disputeId>')
    .description('Inspect a dispute')
    .option('-n, --network <network>', 'Target network')
    .action(async (disputeId, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        
        const arbiterAddress = getContractAddress(network, 'DisputeArbiter');
        const arbiter = getContract(arbiterAddress, DISPUTE_ARBITER_ABI, provider);
        
        const spinner = displaySpinner('Loading dispute...');
        const d = await arbiter.disputes(disputeId);
        spinner.succeed('Dispute loaded');
        
        const statusStr = ['Pending', 'Resolved', 'Appealed', 'Dismissed'][d.status] || 'Unknown';
        const rulingStr = ['None', 'ForComplainant', 'ForDefendant'][d.ruling] || 'None';
        
        console.log('\n' + chalk.bold.cyan('Dispute Details'));
        logDivider();
        logTable({
          ID: disputeId,
          Covenant: d.covenant,
          Complainant: d.complainant,
          Reason: d.reason,
          Status: statusStr,
          Ruling: rulingStr,
          Network: network.name
        });
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });

  // dispute resolve
  dispute
    .command('resolve <disputeId>')
    .description('Resolve a dispute (arbitrator only)')
    .option('-n, --network <network>', 'Target network')
    .option('-w, --wallet <wallet>', 'Wallet to use')
    .option('--ruling <ruling>', 'Ruling: 1=ForComplainant, 2=ForDefendant')
    .option('--dry-run', 'Simulate without sending')
    .action(async (disputeId, options) => {
      try {
        const config = loadConfig();
        const network = getNetwork(config, options.network);
        const provider = await getProvider(network);
        await validateNetwork(provider, network.chainId);
        
        const wallet = await getWallet(options.wallet, undefined, provider);
        
        let ruling = options.ruling;
        if (!ruling) {
          const inquirer = await import('inquirer');
          const answers = await inquirer.default.prompt([{
            type: 'list',
            name: 'ruling',
            message: 'Select ruling:',
            choices: [
              { name: 'For Complainant', value: '1' },
              { name: 'For Defendant', value: '2' }
            ]
          }]);
          ruling = answers.ruling;
        }
        
        const arbiterAddress = getContractAddress(network, 'DisputeArbiter');
        const arbiter = getContract(arbiterAddress, DISPUTE_ARBITER_ABI, wallet);
        
        const txRequest = await arbiter.resolveDispute.populateTransaction(disputeId, Number(ruling));
        const gasEstimate = await estimateGas(provider, { ...txRequest, from: wallet.address }, config.gasMultiplier);
        
        const confirmed = await confirmWithGas(
          'Resolve Dispute',
          {
            'Dispute ID': disputeId,
            Ruling: Number(ruling) === 1 ? 'For Complainant' : 'For Defendant',
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
        
        const spinner = displaySpinner('Resolving dispute...');
        const tx = await arbiter.resolveDispute(disputeId, Number(ruling));
        await tx.wait();
        spinner.succeed('Dispute resolved');
        logInfo(`Transaction: ${tx.hash}`);
      } catch (err) {
        logError((err as Error).message);
        process.exit(1);
      }
    });
}
