const hre = require('hardhat');
const fs = require('fs');
const path = require('path');

async function main() {
  console.log('🚀 Deploying COVENANT Protocol...\n');

  const [deployer] = await hre.ethers.getSigners();
  console.log('Deploying with account:', deployer.address);
  
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log('Account balance:', hre.ethers.formatEther(balance), 'ETH\n');

  const deployedContracts = {};

  // Deploy AgentRegistry
  console.log('📜 Deploying AgentRegistry...');
  const AgentRegistry = await hre.ethers.getContractFactory('AgentRegistry');
  const agentRegistry = await AgentRegistry.deploy();
  await agentRegistry.waitForDeployment();
  deployedContracts.agentRegistry = await agentRegistry.getAddress();
  console.log('✅ AgentRegistry deployed to:', deployedContracts.agentRegistry);

  // Deploy CovenantFactory
  console.log('\n📜 Deploying CovenantFactory...');
  const CovenantFactory = await hre.ethers.getContractFactory('CovenantFactory');
  const factory = await CovenantFactory.deploy(deployer.address);
  await factory.waitForDeployment();
  deployedContracts.factory = await factory.getAddress();
  console.log('✅ CovenantFactory deployed to:', deployedContracts.factory);

  // Deploy TaskMarket
  console.log('\n📜 Deploying TaskMarket...');
  const TaskMarket = await hre.ethers.getContractFactory('TaskMarket');
  const taskMarket = await TaskMarket.deploy(deployer.address);
  await taskMarket.waitForDeployment();
  deployedContracts.taskMarket = await taskMarket.getAddress();
  console.log('✅ TaskMarket deployed to:', deployedContracts.taskMarket);

  // Deploy ReputationStake (needs a mock token for now)
  console.log('\n📜 Deploying Mock Stake Token...');
  const MockToken = await hre.ethers.getContractFactory('MockERC20');
  let stakeToken;
  
  try {
    stakeToken = await MockToken.deploy('Covenant Token', 'COV', 1000000);
    await stakeToken.waitForDeployment();
    deployedContracts.stakeToken = await stakeToken.getAddress();
    console.log('✅ Mock Token deployed to:', deployedContracts.stakeToken);
  } catch (e) {
    console.log('⚠️  Mock token not found, skipping ReputationStake deployment');
    console.log('   Create contracts/MockERC20.sol for full deployment\n');
  }

  if (deployedContracts.stakeToken) {
    console.log('\n📜 Deploying ReputationStake...');
    const ReputationStake = await hre.ethers.getContractFactory('ReputationStake');
    const reputationStake = await ReputationStake.deploy(
      deployedContracts.stakeToken,
      deployer.address
    );
    await reputationStake.waitForDeployment();
    deployedContracts.reputationStake = await reputationStake.getAddress();
    console.log('✅ ReputationStake deployed to:', deployedContracts.reputationStake);

    // Deploy DisputeDAO
    console.log('\n📜 Deploying DisputeDAO...');
    const DisputeDAO = await hre.ethers.getContractFactory('DisputeDAO');
    const disputeDAO = await DisputeDAO.deploy(
      deployedContracts.stakeToken,
      deployedContracts.reputationStake
    );
    await disputeDAO.waitForDeployment();
    deployedContracts.disputeDAO = await disputeDAO.getAddress();
    console.log('✅ DisputeDAO deployed to:', deployedContracts.disputeDAO);

    // Authorize DisputeDAO as a slasher in ReputationStake
    console.log('\n⚙️  Configuring permissions...');
    await reputationStake.addSlasher(deployedContracts.disputeDAO);
    console.log('✅ DisputeDAO authorized as slasher');
  }

  // Save deployment info
  const deploymentInfo = {
    network: hre.network.name,
    chainId: (await hre.ethers.provider.getNetwork()).chainId.toString(),
    deployer: deployer.address,
    contracts: deployedContracts,
    timestamp: new Date().toISOString(),
  };

  const deploymentPath = path.join(__dirname, '..', 'deployments');
  if (!fs.existsSync(deploymentPath)) {
    fs.mkdirSync(deploymentPath, { recursive: true });
  }

  const filename = `${hre.network.name}-${Date.now()}.json`;
  fs.writeFileSync(
    path.join(deploymentPath, filename),
    JSON.stringify(deploymentInfo, null, 2)
  );

  // Also save as latest
  fs.writeFileSync(
    path.join(deploymentPath, 'latest.json'),
    JSON.stringify(deploymentInfo, null, 2)
  );

  console.log('\n📁 Deployment info saved to:', `deployments/${filename}`);
  console.log('\n🎉 COVENANT Protocol deployed successfully!\n');

  // Print summary
  console.log('═══════════════════════════════════════════════════');
  console.log('              DEPLOYMENT SUMMARY                   ');
  console.log('═══════════════════════════════════════════════════');
  console.log('Network:', hre.network.name);
  console.log('Chain ID:', deploymentInfo.chainId);
  console.log('\nContracts:');
  Object.entries(deployedContracts).forEach(([name, address]) => {
    console.log(`  ${name}: ${address}`);
  });
  console.log('═══════════════════════════════════════════════════\n');

  return deployedContracts;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
