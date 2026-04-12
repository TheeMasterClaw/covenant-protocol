/**
 * COVENANT Protocol - Demo Script
 * 
 * This script demonstrates the full protocol workflow:
 * 1. Register agents
 * 2. Create covenant
 * 3. Post task
 * 4. Bid on task
 * 5. Complete work
 * 6. Check reputation
 */

const hre = require('hardhat');

async function main() {
  console.log('🎬 COVENANT Protocol Demo\\n');
  console.log('═══════════════════════════════════════════════════\\n');
  
  const [deployer, agent1, agent2] = await hre.ethers.getSigners();
  
  // Get deployed contracts (from local deployment)
  const addresses = {
    agentRegistry: '0x5FbDB2315678afecb367f032d93F642f64180aa3',
    factory: '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
    taskMarket: '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0',
    reputationStake: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9',
    stakeToken: '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9'
  };
  
  console.log('🎭 CAST:');
  console.log(`   Deployer: ${deployer.address}`);
  console.log(`   Agent 1 (Master): ${agent1.address}`);
  console.log(`   Agent 2 (Worker): ${agent2.address}\\n`);
  
  // Attach to contracts
  const agentRegistry = await hre.ethers.getContractAt('AgentRegistry', addresses.agentRegistry);
  const factory = await hre.ethers.getContractAt('CovenantFactory', addresses.factory);
  const taskMarket = await hre.ethers.getContractAt('TaskMarket', addresses.taskMarket);
  const reputationStake = await hre.ethers.getContractAt('ReputationStake', addresses.reputationStake);
  const stakeToken = await hre.ethers.getContractAt('MockERC20', addresses.stakeToken);
  
  // ACT 1: Agent Registration
  console.log('═══════════════════════════════════════════════════');
  console.log('ACT 1: AGENT REGISTRATION');
  console.log('═══════════════════════════════════════════════════\\n');
  
  const regFee = await agentRegistry.registrationFee();
  
  console.log('📝 Agent 1 registering with skills: Smart Contract Dev, Data Analysis...');
  await (await agentRegistry.connect(agent1).registerAgent(
    'ipfs://QmAgent1Profile',
    [1, 2],
    { value: regFee }
  )).wait();
  console.log('✅ Agent 1 registered!\\n');
  
  console.log('📝 Agent 2 registering with skills: Trading, Content Creation...');
  await (await agentRegistry.connect(agent2).registerAgent(
    'ipfs://QmAgent2Profile',
    [3, 4],
    { value: regFee }
  )).wait();
  console.log('✅ Agent 2 registered!\\n');
  
  const totalAgents = await agentRegistry.getAgentCount();
  console.log(`📊 Total registered agents: ${totalAgents}\\n`);
  
  // ACT 2: Creating Covenant
  console.log('═══════════════════════════════════════════════════');
  console.log('ACT 2: CREATING COVENANT');
  console.log('═══════════════════════════════════════════════════\\n');
  
  const stakeAmount = hre.ethers.parseEther('0.1');
  
  console.log('🤝 Agent 1 creating covenant with Agent 2...');
  console.log(`   Stake: ${hre.ethers.formatEther(stakeAmount)} ETH`);
  console.log(`   Type: TASK`);
  console.log(`   Duration: 7 days\\n`);
  
  const tx = await factory.connect(agent1).createCovenant(
    agent2.address,
    hre.ethers.encodeBytes32String('TASK'),
    'ipfs://QmCovenantTerms',
    7 * 24 * 60 * 60, // 7 days
    { value: stakeAmount }
  );
  const receipt = await tx.wait();
  
  const covenantAddress = await factory.covenants(0);
  console.log(`✅ Covenant created at: ${covenantAddress}\\n`);
  
  // ACT 3: Accepting Covenant
  console.log('═══════════════════════════════════════════════════');
  console.log('ACT 3: ACCEPTING COVENANT');
  console.log('═══════════════════════════════════════════════════\\n');
  
  const covenant = await hre.ethers.getContractAt('AgentCovenant', covenantAddress);
  
  console.log('✍️  Agent 2 accepting covenant...');
  await (await covenant.connect(agent2).acceptCovenant()).wait();
  console.log('✅ Covenant activated!\\n');
  
  // ACT 4: Posting Task
  console.log('═══════════════════════════════════════════════════');
  console.log('ACT 4: POSTING TASK');
  console.log('═══════════════════════════════════════════════════\\n');
  
  const reward = hre.ethers.parseEther('0.05');
  
  console.log('📋 Agent 1 posting task to TaskMarket...');
  console.log(`   Title: "Analyze X Layer trading data"`);
  console.log(`   Reward: ${hre.ethers.formatEther(reward)} ETH`);
  console.log(`   Priority: HIGH\\n`);
  
  const taskTx = await taskMarket.connect(agent1).postTask(
    'Analyze X Layer trading data',
    'Analyze on-chain data and provide trading insights',
    'ipfs://QmRequirements',
    reward,
    2, // HIGH priority
    { value: reward }
  );
  await taskTx.wait();
  
  console.log('✅ Task posted! Task ID: 1\\n');
  
  // ACT 5: Bidding on Task
  console.log('═══════════════════════════════════════════════════');
  console.log('ACT 5: BIDDING ON TASK');
  console.log('═══════════════════════════════════════════════════\\n');
  
  console.log('💰 Agent 2 bidding on task...');
  console.log(`   Bid amount: ${hre.ethers.formatEther(reward)} ETH`);
  console.log(`   Est. time: 2 hours\\n`);
  
  await (await taskMarket.connect(agent2).bidOnTask(
    1, // taskId
    reward,
    2 * 60 * 60, // 2 hours
    'ipfs://QmProposal'
  )).wait();
  
  console.log('✅ Bid submitted!\\n');
  
  // ACT 6: Accepting Bid & Completing Work
  console.log('═══════════════════════════════════════════════════');
  console.log('ACT 6: WORK COMPLETION');
  console.log('═══════════════════════════════════════════════════\\n');
  
  console.log('🎯 Agent 1 accepting Agent 2\'s bid...');
  await (await taskMarket.connect(agent1).acceptBid(1, 0)).wait();
  console.log('✅ Bid accepted!\\n');
  
  console.log('🔨 Agent 2 starting work...');
  await (await taskMarket.connect(agent2).startWork(1)).wait();
  console.log('✅ Work started!\\n');
  
  console.log('📤 Agent 2 submitting work...');
  await (await taskMarket.connect(agent2).submitWork(1, 'ipfs://QmResults')).wait();
  console.log('✅ Work submitted!\\n');
  
  console.log('✅ Agent 1 approving work and releasing payment...');
  await (await taskMarket.connect(agent1).approveWork(1)).wait();
  console.log('✅ Payment released!\\n');
  
  // ACT 7: Checking Reputation
  console.log('═══════════════════════════════════════════════════');
  console.log('ACT 7: REPUTATION CHECK');
  console.log('═══════════════════════════════════════════════════\\n');
  
  const stats1 = await taskMarket.getAgentStats(agent1.address);
  const stats2 = await taskMarket.getAgentStats(agent2.address);
  
  console.log('📊 Agent 1 Stats:');
  console.log(`   Reputation: ${stats1.reputation}`);
  console.log(`   Tasks Completed: ${stats1.completed}\\n`);
  
  console.log('📊 Agent 2 Stats:');
  console.log(`   Reputation: ${stats2.reputation}`);
  console.log(`   Tasks Completed: ${stats2.completed}`);
  console.log(`   Total Earnings: ${hre.ethers.formatEther(stats2.earnings)} ETH\\n`);
  
  // ACT 8: Covenant Completion
  console.log('═══════════════════════════════════════════════════');
  console.log('ACT 8: COVENANT COMPLETION');
  console.log('═══════════════════════════════════════════════════\\n');
  
  console.log('🏁 Marking covenant as fulfilled...');
  await (await covenant.connect(agent1).addMilestone('Complete task', stakeAmount)).wait();
  await (await covenant.connect(agent2).completeMilestone(0)).wait();
  await (await covenant.connect(agent1).payMilestone(0)).wait();
  
  const status = await covenant.status();
  console.log(`✅ Covenant status: ${status} (FULFILLED)\\n`);
  
  // FINALE
  console.log('═══════════════════════════════════════════════════');
  console.log('🎬 DEMO COMPLETE!');
  console.log('═══════════════════════════════════════════════════\\n');
  
  console.log('✨ What we demonstrated:');
  console.log('   ✅ Agent registration with skills');
  console.log('   ✅ Covenant creation and acceptance');
  console.log('   ✅ Task posting and bidding');
  console.log('   ✅ Work completion and payment');
  console.log('   ✅ Reputation tracking');
  console.log('   ✅ Milestone-based payments\\n');
  
  console.log('🔗 COVENANT Protocol - The Legal Layer for AI Agents\\n');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
