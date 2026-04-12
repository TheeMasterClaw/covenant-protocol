const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('COVENANT Protocol', function () {
  let factory, taskMarket, reputationStake, stakeToken;
  let owner, initiator, counterparty, bidder1, bidder2, slasher;
  
  beforeEach(async function () {
    [owner, initiator, counterparty, bidder1, bidder2, slasher] = await ethers.getSigners();
    
    // Deploy Factory
    const CovenantFactory = await ethers.getContractFactory('CovenantFactory');
    factory = await CovenantFactory.deploy(owner.address);
    
    // Deploy TaskMarket
    const TaskMarket = await ethers.getContractFactory('TaskMarket');
    taskMarket = await TaskMarket.deploy(owner.address);
    
    // Deploy Mock Token
    const MockToken = await ethers.getContractFactory('MockERC20');
    stakeToken = await MockToken.deploy('Covenant Token', 'COV', 1000000);
    
    // Deploy ReputationStake
    const ReputationStake = await ethers.getContractFactory('ReputationStake');
    reputationStake = await ReputationStake.deploy(
      await stakeToken.getAddress(),
      owner.address
    );
    
    // Distribute tokens
    await stakeToken.transfer(initiator.address, ethers.parseEther('10000'));
    await stakeToken.transfer(counterparty.address, ethers.parseEther('10000'));
    await stakeToken.transfer(bidder1.address, ethers.parseEther('10000'));
    await stakeToken.transfer(bidder2.address, ethers.parseEther('10000'));
  });

  describe('CovenantFactory', function () {
    it('Should create a new covenant', async function () {
      const stakeAmount = ethers.parseEther('1');
      
      await expect(
        factory.connect(initiator).createCovenant(
          counterparty.address,
          ethers.encodeBytes32String('TASK'),
          'ipfs://QmTest',
          86400, // 1 day
          { value: stakeAmount }
        )
      )
        .to.emit(factory, 'CovenantCreated')
        .withArgs(
          await factory.covenants(0),
          initiator.address,
          counterparty.address,
          ethers.encodeBytes32String('TASK'),
          stakeAmount - stakeAmount / 100, // After 1% fee
          await ethers.provider.getBlock('latest').then(b => b.timestamp)
        );
      
      expect(await factory.getCovenantCount()).to.equal(1);
    });

    it('Should prevent duplicate covenants', async function () {
      const stakeAmount = ethers.parseEther('1');
      
      await factory.connect(initiator).createCovenant(
        counterparty.address,
        ethers.encodeBytes32String('TASK'),
        'ipfs://QmTest',
        86400,
        { value: stakeAmount }
      );
      
      await expect(
        factory.connect(initiator).createCovenant(
          counterparty.address,
          ethers.encodeBytes32String('TASK'),
          'ipfs://QmTest2',
          86400,
          { value: stakeAmount }
        )
      ).to.be.revertedWithCustomError(factory, 'CovenantAlreadyExists');
    });

    it('Should enforce minimum stake', async function () {
      await expect(
        factory.connect(initiator).createCovenant(
          counterparty.address,
          ethers.encodeBytes32String('TASK'),
          'ipfs://QmTest',
          86400,
          { value: ethers.parseEther('0.001') }
        )
      ).to.be.revertedWithCustomError(factory, 'InsufficientStake');
    });
  });

  describe('AgentCovenant', function () {
    let covenant;
    
    beforeEach(async function () {
      const stakeAmount = ethers.parseEther('1');
      
      await factory.connect(initiator).createCovenant(
        counterparty.address,
        ethers.encodeBytes32String('TASK'),
        'ipfs://QmTest',
        86400,
        { value: stakeAmount }
      );
      
      const covenantAddress = await factory.covenants(0);
      covenant = await ethers.getContractAt('AgentCovenant', covenantAddress);
    });

    it('Should start in PENDING status', async function () {
      expect(await covenant.status()).to.equal(0); // PENDING
    });

    it('Should allow counterparty to accept', async function () {
      await expect(covenant.connect(counterparty).acceptCovenant())
        .to.emit(covenant, 'CovenantAccepted')
        .withArgs(counterparty.address);
      
      expect(await covenant.status()).to.equal(1); // ACTIVE
    });

    it('Should add and complete milestones', async function () {
      await covenant.connect(counterparty).acceptCovenant();
      
      await covenant.connect(initiator).addMilestone(
        'Complete task phase 1',
        ethers.parseEther('0.3')
      );
      
      expect(await covenant.getMilestoneCount()).to.equal(1);
      
      await covenant.connect(counterparty).completeMilestone(0);
      
      const milestone = await covenant.getMilestone(0);
      expect(milestone.completed).to.be.true;
    });

    it('Should pay completed milestones', async function () {
      await covenant.connect(counterparty).acceptCovenant();
      
      await covenant.connect(initiator).addMilestone(
        'Complete task',
        ethers.parseEther('0.5')
      );
      
      await covenant.connect(counterparty).completeMilestone(0);
      
      const beforeBalance = await ethers.provider.getBalance(counterparty.address);
      
      await covenant.connect(initiator).payMilestone(0);
      
      const afterBalance = await ethers.provider.getBalance(counterparty.address);
      expect(afterBalance).to.be.gt(beforeBalance);
    });

    it('Should handle disputes', async function () {
      await covenant.connect(counterparty).acceptCovenant();
      
      await expect(covenant.connect(initiator).raiseDispute('Counterparty not responding'))
        .to.emit(covenant, 'DisputeRaised');
      
      expect(await covenant.status()).to.equal(3); // DISPUTED
    });
  });

  describe('TaskMarket', function () {
    it('Should post a task', async function () {
      const reward = ethers.parseEther('1');
      
      await expect(
        taskMarket.connect(initiator).postTask(
          'Analyze market data',
          'Detailed analysis of X Layer trends',
          'ipfs://QmRequirements',
          reward,
          1, // MEDIUM priority
          { value: reward }
        )
      )
        .to.emit(taskMarket, 'TaskPosted')
        .withArgs(
          1,
          initiator.address,
          'Analyze market data',
          reward,
          1,
          await ethers.provider.getBlock('latest').then(b => b.timestamp + 86400)
        );
    });

    it('Should accept bids', async function () {
      // Post task
      await taskMarket.connect(initiator).postTask(
        'Test task',
        'Description',
        'ipfs://QmReq',
        ethers.parseEther('1'),
        1,
        { value: ethers.parseEther('1') }
      );
      
      // Bid
      await taskMarket.connect(bidder1).bidOnTask(
        1,
        ethers.parseEther('0.8'),
        3600,
        'ipfs://QmProposal'
      );
      
      expect(await taskMarket.getBidCount(1)).to.equal(1);
      
      // Accept bid
      await taskMarket.connect(initiator).acceptBid(1, 0);
      
      const task = await taskMarket.getTask(1);
      expect(task.assignedTo).to.equal(bidder1.address);
    });

    it('Should complete task workflow', async function () {
      // Post and assign
      await taskMarket.connect(initiator).postTask(
        'Complete workflow',
        'Description',
        'ipfs://QmReq',
        ethers.parseEther('1'),
        1,
        { value: ethers.parseEther('1') }
      );
      
      await taskMarket.connect(bidder1).bidOnTask(
        1,
        ethers.parseEther('0.9'),
        3600,
        'ipfs://QmProposal'
      );
      
      await taskMarket.connect(initiator).acceptBid(1, 0);
      
      // Start work
      await taskMarket.connect(bidder1).startWork(1);
      
      // Submit work
      await taskMarket.connect(bidder1).submitWork(1, 'ipfs://QmResult');
      
      // Approve
      const beforeRep = await taskMarket.agentReputation(bidder1.address);
      await taskMarket.connect(initiator).approveWork(1);
      const afterRep = await taskMarket.agentReputation(bidder1.address);
      
      expect(afterRep).to.be.gt(beforeRep);
      
      const stats = await taskMarket.getAgentStats(bidder1.address);
      expect(stats.completed).to.equal(1);
    });

    it('Should track agent stats', async function () {
      await taskMarket.connect(initiator).postTask(
        'Stats test',
        'Description',
        'ipfs://QmReq',
        ethers.parseEther('1'),
        1,
        { value: ethers.parseEther('1') }
      );
      
      const stats = await taskMarket.getAgentStats(initiator.address);
      expect(stats.reputation).to.equal(0);
      expect(stats.completed).to.equal(0);
    });
  });

  describe('ReputationStake', function () {
    beforeEach(async function () {
      // Approve tokens
      await stakeToken.connect(initiator).approve(
        await reputationStake.getAddress(),
        ethers.parseEther('10000')
      );
    });

    it('Should register agent', async function () {
      await expect(reputationStake.connect(initiator).registerAgent('ipfs://QmProfile'))
        .to.emit(reputationStake, 'AgentRegistered')
        .withArgs(initiator.address, 'ipfs://QmProfile');
      
      const profile = await reputationStake.getAgentProfile(initiator.address);
      expect(profile.isActive).to.be.true;
    });

    it('Should stake tokens', async function () {
      await reputationStake.connect(initiator).registerAgent('ipfs://QmProfile');
      
      await expect(reputationStake.connect(initiator).stake(ethers.parseEther('100')))
        .to.emit(reputationStake, 'StakeDeposited');
      
      const profile = await reputationStake.getAgentProfile(initiator.address);
      expect(profile.totalStaked).to.equal(ethers.parseEther('100'));
    });

    it('Should calculate reputation', async function () {
      await reputationStake.connect(initiator).registerAgent('ipfs://QmProfile');
      await reputationStake.connect(initiator).stake(ethers.parseEther('100'));
      
      const rep = await reputationStake.calculateReputation(initiator.address);
      expect(rep).to.be.gt(0);
    });

    it('Should record successes', async function () {
      await reputationStake.connect(initiator).registerAgent('ipfs://QmProfile');
      await reputationStake.connect(initiator).stake(ethers.parseEther('100'));
      
      await reputationStake.connect(owner).recordSuccess(initiator.address);
      
      const profile = await reputationStake.getAgentProfile(initiator.address);
      expect(profile.successfulCovenants).to.equal(1);
    });

    it('Should slash on breach', async function () {
      await reputationStake.connect(initiator).registerAgent('ipfs://QmProfile');
      await reputationStake.connect(initiator).stake(ethers.parseEther('100'));
      
      const beforeStake = (await reputationStake.getAgentProfile(initiator.address)).totalStaked;
      
      await reputationStake.connect(owner).recordBreach(
        initiator.address,
        1,
        'Missed deadline'
      );
      
      const afterStake = (await reputationStake.getAgentProfile(initiator.address)).totalStaked;
      expect(afterStake).to.be.lt(beforeStake);
    });
  });

  describe('Protocol Integration', function () {
    it('Should handle full workflow: covenant -> task -> reputation', async function () {
      // 1. Create covenant
      await factory.connect(initiator).createCovenant(
        counterparty.address,
        ethers.encodeBytes32String('ALLIANCE'),
        'ipfs://QmAlliance',
        7 * 86400,
        { value: ethers.parseEther('2') }
      );
      
      // 2. Counterparty accepts
      const covenantAddress = await factory.covenants(0);
      const covenant = await ethers.getContractAt('AgentCovenant', covenantAddress);
      await covenant.connect(counterparty).acceptCovenant();
      
      // 3. Post task within covenant
      await taskMarket.connect(initiator).postTask(
        'Covenant task',
        'Task within alliance',
        'ipfs://QmTaskReq',
        ethers.parseEther('0.5'),
        1,
        { value: ethers.parseEther('0.5') }
      );
      
      // 4. Bid and complete
      await taskMarket.connect(counterparty).bidOnTask(
        1,
        ethers.parseEther('0.4'),
        3600,
        'ipfs://QmBid'
      );
      
      await taskMarket.connect(initiator).acceptBid(1, 0);
      await taskMarket.connect(counterparty).startWork(1);
      await taskMarket.connect(counterparty).submitWork(1, 'ipfs://QmResult');
      await taskMarket.connect(initiator).approveWork(1);
      
      // 5. Verify reputation gain
      const stats = await taskMarket.getAgentStats(counterparty.address);
      expect(stats.reputation).to.be.gt(0);
      expect(stats.completed).to.equal(1);
      
      console.log('\n✅ Full integration workflow completed successfully!');
      console.log('   - Covenant created and accepted');
      console.log('   - Task posted, bid, and completed');
      console.log('   - Reputation earned:', stats.reputation.toString());
    });
  });
});
