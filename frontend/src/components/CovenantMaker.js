import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ethers } from 'ethers';
import AgentRegistryABI from '../abis/AgentRegistry.json';
import ReputationStakeABI from '../abis/ReputationStake.json';

const STEPS = ['Select Counterparty', 'Define Terms', 'Set Milestones', 'Review & Create'];

const AGENT_REGISTRY_ADDRESS = process.env.REACT_APP_AGENT_REGISTRY_ADDRESS;
const REPUTATION_STAKE_ADDRESS = process.env.REACT_APP_REPUTATION_STAKE_ADDRESS;

const COVENANT_TEMPLATES = [
  { id: 'development', name: 'Development Partnership', description: 'Collaborative development with milestone-based payments', icon: '💻' },
  { id: 'liquidity', name: 'Liquidity Provision', description: 'Joint liquidity provision for DeFi strategies', icon: '💧' },
  { id: 'arbitrage', name: 'Arbitrage Alliance', description: 'Cross-chain arbitrage opportunity sharing', icon: '⚡' },
  { id: 'analysis', name: 'Intelligence Sharing', description: 'Market analysis and signal sharing agreement', icon: '📊' },
  { id: 'custom', name: 'Custom Covenant', description: 'Define your own terms and conditions', icon: '⚙️' },
];

export function CovenantMaker({ contracts, account, onSuccess }) {
  const [currentStep, setCurrentStep] = useState(0);
  const [agents, setAgents] = useState([]);
  const [agentsLoading, setAgentsLoading] = useState(true);
  const [formData, setFormData] = useState({
    counterparty: '',
    covenantType: 'development',
    title: '',
    description: '',
    totalValue: '',
    duration: '30',
    milestones: [
      { title: 'Kickoff', description: 'Initial setup and planning', amount: '20', deadline: '7' },
      { title: 'Milestone 1', description: '', amount: '40', deadline: '14' },
      { title: 'Completion', description: 'Final delivery', amount: '40', deadline: '30' },
    ],
    disputeResolver: 'dao',
    earlyTermination: true,
    collateral: '',
  });
  const [isCreating, setIsCreating] = useState(false);
  const [createError, setCreateError] = useState(null);

  useEffect(() => {
    const fetchAgents = async () => {
      setAgentsLoading(true);
      try {
        let provider;
        let registry;
        let reputation;

        if (contracts?.agentRegistry && contracts?.reputationStake) {
          registry = contracts.agentRegistry;
          reputation = contracts.reputationStake;
        } else if (window.ethereum) {
          provider = new ethers.BrowserProvider(window.ethereum);
          if (AGENT_REGISTRY_ADDRESS) {
            registry = new ethers.Contract(AGENT_REGISTRY_ADDRESS, AgentRegistryABI, provider);
          }
          if (REPUTATION_STAKE_ADDRESS) {
            reputation = new ethers.Contract(REPUTATION_STAKE_ADDRESS, ReputationStakeABI, provider);
          }
        }

        if (!registry) {
          setAgents([]);
          setAgentsLoading(false);
          return;
        }

        const totalAgents = await registry.totalAgents();
        const limit = totalAgents > 0 ? Number(totalAgents) : 0;

        let agentAddresses = [];
        if (limit > 0) {
          try {
            agentAddresses = await registry.getTopAgents(limit);
          } catch {
            const calls = [];
            for (let i = 0; i < limit; i++) {
              calls.push(registry.allAgents(i).catch(() => null));
            }
            const results = await Promise.all(calls);
            agentAddresses = results.filter(addr => addr !== null);
          }
        }

        const agentData = await Promise.all(
          agentAddresses.map(async (address) => {
            try {
              const profile = await registry.getAgent(address);
              let stakeInfo = { totalStaked: 0n, reputationScore: 0n };
              if (reputation) {
                try {
                  stakeInfo = await reputation.agents(address);
                } catch (e) {
                  // ignore
                }
              }
              return {
                address,
                name: profile.metadataURI || `Agent ${address.slice(0, 6)}`,
                reputation: Number(profile.reputationScore || stakeInfo.reputationScore || 0),
                skills: profile.skillNames?.length > 0 ? profile.skillNames : profile.skills?.map(s => `Skill ${s}`) || [],
              };
            } catch (e) {
              return null;
            }
          })
        );

        setAgents(agentData.filter(a => a !== null));
      } catch (err) {
        console.error('Error fetching agents:', err);
        setAgents([]);
      } finally {
        setAgentsLoading(false);
      }
    };

    fetchAgents();
  }, [contracts]);

  const updateForm = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const updateMilestone = (index, field, value) => {
    const newMilestones = [...formData.milestones];
    newMilestones[index] = { ...newMilestones[index], [field]: value };
    setFormData(prev => ({ ...prev, milestones: newMilestones }));
  };

  const addMilestone = () => {
    setFormData(prev => ({
      ...prev,
      milestones: [...prev.milestones, { title: '', description: '', amount: '0', deadline: '' }]
    }));
  };

  const removeMilestone = (index) => {
    if (formData.milestones.length > 1) {
      setFormData(prev => ({
        ...prev,
        milestones: prev.milestones.filter((_, i) => i !== index)
      }));
    }
  };

  const handleCreate = async () => {
    setCreateError(null);
    if (!contracts?.factory) {
      setCreateError('Factory contract not connected. Please connect your wallet.');
      return;
    }
    if (!account) {
      setCreateError('Please connect your wallet.');
      return;
    }
    if (!formData.counterparty || !ethers.isAddress(formData.counterparty)) {
      setCreateError('Please enter a valid counterparty address.');
      return;
    }
    if (!formData.title || !formData.description || !formData.totalValue || !formData.duration) {
      setCreateError('Please fill in all required fields.');
      return;
    }

    setIsCreating(true);
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const factory = contracts.factory.connect(signer);

      const durationSeconds = parseInt(formData.duration) * 24 * 60 * 60;
      const stakeWei = ethers.parseEther(formData.totalValue);
      const typeBytes = ethers.encodeBytes32String(formData.covenantType.slice(0, 31));

      // Build a terms hash from the form data (ideally this would be uploaded to IPFS)
      const termsObj = {
        title: formData.title,
        description: formData.description,
        milestones: formData.milestones,
        disputeResolver: formData.disputeResolver,
        earlyTermination: formData.earlyTermination,
        createdAt: new Date().toISOString(),
      };
      const termsHash = 'data:application/json;base64,' + btoa(JSON.stringify(termsObj));

      const tx = await factory.createCovenant(
        formData.counterparty,
        typeBytes,
        termsHash,
        durationSeconds,
        { value: stakeWei }
      );

      await tx.wait();
      onSuccess?.();
    } catch (error) {
      console.error('Error creating covenant:', error);
      setCreateError(error?.reason || error?.message || 'Transaction failed');
    } finally {
      setIsCreating(false);
    }
  };

  const canProceed = () => {
    switch (currentStep) {
      case 0: return formData.counterparty !== '' && ethers.isAddress(formData.counterparty);
      case 1: return formData.title && formData.description && formData.totalValue && formData.duration;
      case 2: return formData.milestones.every(m => m.title && m.amount && m.deadline);
      case 3: return true;
      default: return false;
    }
  };

  const totalMilestoneAmount = formData.milestones.reduce((sum, m) => sum + (parseFloat(m.amount) || 0), 0);

  return (
    <div className="covenant-maker">
      <div className="maker-header">
        <h2>Create New Covenant</h2>
        <p>Establish a binding agreement with another AI agent</p>
      </div>

      {/* Progress Steps */}
      <div className="step-indicator">
        {STEPS.map((step, index) => (
          <div key={step} className={`step ${index <= currentStep ? 'active' : ''} ${index < currentStep ? 'completed' : ''}`}>
            <div className="step-number">
              {index < currentStep ? '✓' : index + 1}
            </div>
            <div className="step-label">{step}</div>
          </div>
        ))}
      </div>

      {createError && (
        <div className="form-error" style={{ color: '#ff4757', marginBottom: '16px', padding: '12px', background: 'rgba(255,71,87,0.1)', borderRadius: '8px' }}>
          {createError}
        </div>
      )}

      <div className="maker-content">
        <AnimatePresence mode="wait">
          {currentStep === 0 && (
            <motion.div
              key="step0"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="step-content"
            >
              <h3>Select Counterparty</h3>
              <p>Choose an agent to form a covenant with</p>

              {agentsLoading ? (
                <div className="agent-selection">
                  <p>Loading agents from blockchain...</p>
                </div>
              ) : agents.length === 0 ? (
                <div className="agent-selection">
                  <p>No registered agents found. Enter a custom address below.</p>
                </div>
              ) : (
                <div className="agent-selection">
                  {agents.map(agent => (
                    <div
                      key={agent.address}
                      className={`agent-option ${formData.counterparty === agent.address ? 'selected' : ''}`}
                      onClick={() => updateForm('counterparty', agent.address)}
                    >
                      <div className="agent-avatar">{agent.name[0]}</div>
                      <div className="agent-details">
                        <h4>{agent.name}</h4>
                        <p>{agent.address.slice(0, 6)}...{agent.address.slice(-4)}</p>
                        <div className="agent-meta">
                          <span className="reputation">★ {agent.reputation}</span>
                          <span className="skills">{agent.skills.join(', ')}</span>
                        </div>
                      </div>
                      <div className="selection-indicator">
                        {formData.counterparty === agent.address && '✓'}
                      </div>
                    </div>
                  ))}
                </div>
              )}

              <div className="form-group">
                <label>Or enter custom address:</label>
                <input
                  type="text"
                  placeholder="0x..."
                  value={ethers.isAddress(formData.counterparty) && !agents.find(a => a.address === formData.counterparty) ? formData.counterparty : ''}
                  onChange={(e) => updateForm('counterparty', e.target.value)}
                />
              </div>
            </motion.div>
          )}

          {currentStep === 1 && (
            <motion.div
              key="step1"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="step-content"
            >
              <h3>Define Terms</h3>
              <p>Configure the covenant parameters</p>

              <div className="template-selection">
                <label>Covenant Template</label>
                <div className="template-grid">
                  {COVENANT_TEMPLATES.map(template => (
                    <div
                      key={template.id}
                      className={`template-card ${formData.covenantType === template.id ? 'selected' : ''}`}
                      onClick={() => updateForm('covenantType', template.id)}
                    >
                      <span className="template-icon">{template.icon}</span>
                      <h4>{template.name}</h4>
                      <p>{template.description}</p>
                    </div>
                  ))}
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Covenant Title *</label>
                  <input
                    type="text"
                    placeholder="e.g., Cross-Chain Arbitrage Partnership"
                    value={formData.title}
                    onChange={(e) => updateForm('title', e.target.value)}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Total Value (ETH) *</label>
                  <input
                    type="number"
                    step="0.01"
                    placeholder="0.00"
                    value={formData.totalValue}
                    onChange={(e) => updateForm('totalValue', e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Description *</label>
                <textarea
                  rows="4"
                  placeholder="Describe the covenant terms, deliverables, and expectations..."
                  value={formData.description}
                  onChange={(e) => updateForm('description', e.target.value)}
                  required
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Duration (days) *</label>
                  <input
                    type="number"
                    value={formData.duration}
                    onChange={(e) => updateForm('duration', e.target.value)}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Collateral Required (ETH)</label>
                  <input
                    type="number"
                    step="0.01"
                    placeholder="Optional"
                    value={formData.collateral}
                    onChange={(e) => updateForm('collateral', e.target.value)}
                  />
                </div>
              </div>

              <div className="form-group checkbox">
                <label>
                  <input
                    type="checkbox"
                    checked={formData.earlyTermination}
                    onChange={(e) => updateForm('earlyTermination', e.target.checked)}
                  />
                  Allow early termination with mutual consent
                </label>
              </div>
            </motion.div>
          )}

          {currentStep === 2 && (
            <motion.div
              key="step2"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="step-content"
            >
              <h3>Set Milestones</h3>
              <p>Define payment milestones and deadlines</p>

              <div className="milestones-summary">
                <div className="summary-item">
                  <span>Total Value:</span>
                  <strong>{formData.totalValue || '0'} ETH</strong>
                </div>
                <div className={`summary-item ${Math.abs(totalMilestoneAmount - parseFloat(formData.totalValue || 0)) > 0.01 ? 'warning' : ''}`}>
                  <span>Milestone Total:</span>
                  <strong>{totalMilestoneAmount.toFixed(2)} ETH</strong>
                </div>
              </div>

              <div className="milestones-list">
                {formData.milestones.map((milestone, index) => (
                  <div key={index} className="milestone-card">
                    <div className="milestone-header">
                      <span className="milestone-number">#{index + 1}</span>
                      {formData.milestones.length > 1 && (
                        <button
                          className="remove-btn"
                          onClick={() => removeMilestone(index)}
                        >
                          ×
                        </button>
                      )}
                    </div>
                    <div className="form-row">
                      <div className="form-group">
                        <label>Title *</label>
                        <input
                          type="text"
                          value={milestone.title}
                          onChange={(e) => updateMilestone(index, 'title', e.target.value)}
                          placeholder="Milestone title"
                          required
                        />
                      </div>
                      <div className="form-group small">
                        <label>Amount (%) *</label>
                        <input
                          type="number"
                          value={milestone.amount}
                          onChange={(e) => updateMilestone(index, 'amount', e.target.value)}
                          placeholder="0"
                          required
                        />
                      </div>
                      <div className="form-group small">
                        <label>Days *</label>
                        <input
                          type="number"
                          value={milestone.deadline}
                          onChange={(e) => updateMilestone(index, 'deadline', e.target.value)}
                          placeholder="0"
                          required
                        />
                      </div>
                    </div>
                    <div className="form-group">
                      <label>Description</label>
                      <input
                        type="text"
                        value={milestone.description}
                        onChange={(e) => updateMilestone(index, 'description', e.target.value)}
                        placeholder="What needs to be delivered..."
                      />
                    </div>
                  </div>
                ))}
              </div>

              <button className="add-milestone-btn" onClick={addMilestone}>
                + Add Milestone
              </button>

              <div className="dispute-settings">
                <h4>Dispute Resolution</h4>
                <div className="radio-group">
                  <label className="radio-option">
                    <input
                      type="radio"
                      name="disputeResolver"
                      value="dao"
                      checked={formData.disputeResolver === 'dao'}
                      onChange={(e) => updateForm('disputeResolver', e.target.value)}
                    />
                    <div>
                      <strong>DisputeDAO</strong>
                      <p>Decentralized arbitration by staked jurors</p>
                    </div>
                  </label>
                  <label className="radio-option">
                    <input
                      type="radio"
                      name="disputeResolver"
                      value="mediator"
                      checked={formData.disputeResolver === 'mediator'}
                      onChange={(e) => updateForm('disputeResolver', e.target.value)}
                    />
                    <div>
                      <strong>Trusted Mediator</strong>
                      <p>Mutually agreed third-party arbitrator</p>
                    </div>
                  </label>
                </div>
              </div>
            </motion.div>
          )}

          {currentStep === 3 && (
            <motion.div
              key="step3"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              className="step-content"
            >
              <h3>Review Covenant</h3>
              <p>Verify all details before creating</p>

              <div className="review-card">
                <div className="review-section">
                  <h4>👥 Parties</h4>
                  <div className="review-row">
                    <span>Initiator:</span>
                    <strong>{account ? `${account.slice(0, 6)}...${account.slice(-4)}` : 'You'}</strong>
                  </div>
                  <div className="review-row">
                    <span>Counterparty:</span>
                    <strong>{formData.counterparty || 'Not selected'}</strong>
                  </div>
                </div>

                <div className="review-section">
                  <h4>📋 Terms</h4>
                  <div className="review-row">
                    <span>Type:</span>
                    <strong>{COVENANT_TEMPLATES.find(t => t.id === formData.covenantType)?.name}</strong>
                  </div>
                  <div className="review-row">
                    <span>Title:</span>
                    <strong>{formData.title || 'Untitled'}</strong>
                  </div>
                  <div className="review-row">
                    <span>Total Value:</span>
                    <strong>{formData.totalValue || '0'} ETH</strong>
                  </div>
                  <div className="review-row">
                    <span>Duration:</span>
                    <strong>{formData.duration} days</strong>
                  </div>
                </div>

                <div className="review-section">
                  <h4>🎯 Milestones</h4>
                  {formData.milestones.map((m, i) => (
                    <div key={i} className="milestone-review">
                      <span>#{i + 1} {m.title}</span>
                      <strong>{m.amount}%</strong>
                    </div>
                  ))}
                </div>

                <div className="review-section">
                  <h4>⚖️ Dispute Resolution</h4>
                  <div className="review-row">
                    <span>Resolver:</span>
                    <strong>{formData.disputeResolver === 'dao' ? 'DisputeDAO' : 'Trusted Mediator'}</strong>
                  </div>
                </div>

                <div className="creation-cost">
                  <h4>💰 Estimated Costs</h4>
                  <div className="cost-row">
                    <span>Platform Fee (1%):</span>
                    <strong>{(parseFloat(formData.totalValue || 0) * 0.01).toFixed(4)} ETH</strong>
                  </div>
                  <div className="cost-row">
                    <span>Gas Estimate:</span>
                    <strong>~0.003 ETH</strong>
                  </div>
                  <div className="cost-row total">
                    <span>Total Required:</span>
                    <strong>{(parseFloat(formData.totalValue || 0) + (parseFloat(formData.totalValue || 0) * 0.01) + 0.003).toFixed(4)} ETH</strong>
                  </div>
                </div>
              </div>

              <button
                className="create-covenant-btn"
                onClick={handleCreate}
                disabled={isCreating || !canProceed()}
              >
                {isCreating ? (
                  <>
                    <span className="spinner"></span>
                    Creating Covenant...
                  </>
                ) : (
                  'Create Covenant'
                )}
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div className="maker-footer">
        <button
          className="btn btn-secondary"
          onClick={() => setCurrentStep(prev => prev - 1)}
          disabled={currentStep === 0}
        >
          ← Back
        </button>
        <div className="step-dots">
          {STEPS.map((_, index) => (
            <span key={index} className={index === currentStep ? 'active' : ''} />
          ))}
        </div>
        {currentStep < STEPS.length - 1 ? (
          <button
            className="btn btn-primary"
            onClick={() => setCurrentStep(prev => prev + 1)}
            disabled={!canProceed()}
          >
            Next →
          </button>
        ) : null}
      </div>
    </div>
  );
}
