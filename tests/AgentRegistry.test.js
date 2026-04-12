const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('AgentRegistry', function () {
  let agentRegistry, owner, agent1, agent2, agent3;
  
  beforeEach(async function () {
    [owner, agent1, agent2, agent3] = await ethers.getSigners();
    
    const AgentRegistry = await ethers.getContractFactory('AgentRegistry');
    agentRegistry = await AgentRegistry.deploy();
  });
  
  describe('Registration', function () {
    it('Should register a new agent', async function () {
      const fee = await agentRegistry.registrationFee();
      
      await expect(agentRegistry.connect(agent1).registerAgent(
        'ipfs://QmProfile1',
        [1, 2, 3], // Skill IDs
        { value: fee }
      )).to.emit(agentRegistry, 'AgentRegistered')
        .withArgs(agent1.address, 'ipfs://QmProfile1', [1, 2, 3], await ethers.provider.getBlock('latest').then(b => b.timestamp));
      
      const profile = await agentRegistry.getAgent(agent1.address);
      expect(profile.isActive).to.be.true;
      expect(profile.skills.length).to.equal(3);
    });
    
    it('Should prevent double registration', async function () {
      const fee = await agentRegistry.registrationFee();
      
      await agentRegistry.connect(agent1).registerAgent('ipfs://QmProfile', [1], { value: fee });
      
      await expect(
        agentRegistry.connect(agent1).registerAgent('ipfs://QmProfile2', [2], { value: fee })
      ).to.be.revertedWith('Already registered');
    });
    
    it('Should require sufficient fee', async function () {
      await expect(
        agentRegistry.connect(agent1).registerAgent('ipfs://QmProfile', [1], { value: 0 })
      ).to.be.revertedWith('Insufficient fee');
    });
    
    it('Should refund excess fee', async function () {
      const fee = await agentRegistry.registrationFee();
      const excess = ethers.parseEther('0.01');
      
      const beforeBalance = await ethers.provider.getBalance(agent1.address);
      
      const tx = await agentRegistry.connect(agent1).registerAgent(
        'ipfs://QmProfile', 
        [1], 
        { value: fee + excess }
      );
      const receipt = await tx.wait();
      const gasUsed = receipt.gasUsed * receipt.gasPrice;
      
      const afterBalance = await ethers.provider.getBalance(agent1.address);
      
      // Should only have spent fee + gas, not excess
      const spent = beforeBalance - afterBalance - gasUsed;
      expect(spent).to.be.closeTo(fee, 100n);
    });
  });
  
  describe('Discovery', function () {
    beforeEach(async function () {
      const fee = await agentRegistry.registrationFee();
      
      await agentRegistry.connect(agent1).registerAgent('ipfs://QmAgent1', [1, 2], { value: fee });
      await agentRegistry.connect(agent2).registerAgent('ipfs://QmAgent2', [2, 3], { value: fee });
      await agentRegistry.connect(agent3).registerAgent('ipfs://QmAgent3', [1, 3], { value: fee });
    });
    
    it('Should find agents by skill', async function () {
      const agentsWithSkill1 = await agentRegistry.findAgentsBySkill(1);
      expect(agentsWithSkill1.length).to.equal(2);
      expect(agentsWithSkill1).to.include(agent1.address);
      expect(agentsWithSkill1).to.include(agent3.address);
    });
    
    it('Should find agents by multiple skills', async function () {
      const agents = await agentRegistry.findAgentsBySkills([1, 2]);
      expect(agents.length).to.equal(1);
      expect(agents[0]).to.equal(agent1.address);
    });
    
    it('Should track total agents', async function () {
      expect(await agentRegistry.getAgentCount()).to.equal(3);
    });
    
    it('Should return all skills', async function () {
      const skills = await agentRegistry.getAllSkills();
      expect(skills.length).to.be.at.least(8); // 8 default skills
    });
  });
  
  describe('Profile Management', function () {
    beforeEach(async function () {
      const fee = await agentRegistry.registrationFee();
      await agentRegistry.connect(agent1).registerAgent('ipfs://QmProfile', [1, 2], { value: fee });
    });
    
    it('Should update profile', async function () {
      await expect(agentRegistry.connect(agent1).updateProfile(
        'ipfs://QmUpdated',
        [3, 4]
      )).to.emit(agentRegistry, 'AgentUpdated');
      
      const profile = await agentRegistry.getAgent(agent1.address);
      expect(profile.metadataURI).to.equal('ipfs://QmUpdated');
    });
    
    it('Should deactivate and reactivate', async function () {
      await agentRegistry.connect(agent1).deactivate();
      let profile = await agentRegistry.getAgent(agent1.address);
      expect(profile.isActive).to.be.false;
      
      await agentRegistry.connect(agent1).reactivate();
      profile = await agentRegistry.getAgent(agent1.address);
      expect(profile.isActive).to.be.true;
    });
    
    it('Should check registration status', async function () {
      expect(await agentRegistry.isRegistered(agent1.address)).to.be.true;
      expect(await agentRegistry.isRegistered(agent2.address)).to.be.false;
    });
  });
  
  describe('Activity Tracking', function () {
    beforeEach(async function () {
      const fee = await agentRegistry.registrationFee();
      await agentRegistry.connect(agent1).registerAgent('ipfs://QmProfile', [1], { value: fee });
    });
    
    it('Should record activity and increase reputation', async function () {
      const beforeRep = (await agentRegistry.getAgent(agent1.address)).reputationScore;
      
      await agentRegistry.recordActivity(agent1.address, 5, 10, ethers.parseEther('1'));
      
      const afterRep = (await agentRegistry.getAgent(agent1.address)).reputationScore;
      expect(afterRep).to.be.gt(beforeRep);
      
      const profile = await agentRegistry.getAgent(agent1.address);
      expect(profile.covenantsCompleted).to.equal(5);
      expect(profile.tasksCompleted).to.equal(10);
    });
  });
  
  describe('Admin Functions', function () {
    it('Should allow owner to add skills', async function () {
      await expect(agentRegistry.connect(owner).addSkill('New Skill', 'Description'))
        .to.emit(agentRegistry, 'SkillAdded');
    });
    
    it('Should prevent non-owner from adding skills', async function () {
      await expect(
        agentRegistry.connect(agent1).addSkill('New Skill', 'Description')
      ).to.be.revertedWith('Not owner');
    });
    
    it('Should allow owner to withdraw fees', async function () {
      const fee = await agentRegistry.registrationFee();
      await agentRegistry.connect(agent1).registerAgent('ipfs://QmProfile', [1], { value: fee });
      
      const beforeBalance = await ethers.provider.getBalance(owner.address);
      await agentRegistry.connect(owner).withdrawFees();
      const afterBalance = await ethers.provider.getBalance(owner.address);
      
      expect(afterBalance).to.be.gt(beforeBalance);
    });
  });
});
