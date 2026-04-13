import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const STEPS = ['Select Counterparty', 'Define Terms', 'Set Milestones', 'Review & Create'];

const MOCK_AGENTS = [
  { address: '0x1234...5678', name: 'AlphaAgent', reputation: 947, skills: ['Solidity', 'Security'] },
  { address: '0xabcd...efgh', name: 'BetaBot', reputation: 823, skills: ['AI/ML', 'Data'] },
  { address: '0x9876...5432', name: 'GammaGuard', reputation: 756, skills: ['DevOps', 'Monitoring'] },
];

const COVENANT_TEMPLATES = [
  { id: 'development', name: 'Development Partnership', description: 'Collaborative development with milestone-based payments', icon: '💻' },
  { id: 'liquidity', name: 'Liquidity Provision', description: 'Joint liquidity provision for DeFi strategies', icon: '💧' },
  { id: 'arbitrage', name: 'Arbitrage Alliance', description: 'Cross-chain arbitrage opportunity sharing', icon: '⚡' },
  { id: 'analysis', name: 'Intelligence Sharing', description: 'Market analysis and signal sharing agreement', icon: '📊' },
  { id: 'custom', name: 'Custom Covenant', description: 'Define your own terms and conditions', icon: '⚙️' },
];

export function CovenantMaker({ contracts, account, onSuccess }) {
  const [currentStep, setCurrentStep] = useState(0);
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
    setIsCreating(true);
    // Simulate contract call
    await new Promise(r => setTimeout(r, 2000));
    setIsCreating(false);
    onSuccess?.();
  };

  const canProceed = () => {
    switch (currentStep) {
      case 0: return formData.counterparty !== '';
      case 1: return formData.title && formData.description && formData.totalValue;
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

              <div className="agent-selection">
                {MOCK_AGENTS.map(agent => (
                  <div
                    key={agent.address}
                    className={`agent-option ${formData.counterparty === agent.address ? 'selected' : ''}`}
                    onClick={() => updateForm('counterparty', agent.address)}
                  >
                    <div className="agent-avatar">{agent.name[0]}</div>
                    <div className="agent-details">
                      <h4>{agent.name}</h4>
                      <p>{agent.address}</p>
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

              <div className="form-group">
                <label>Or enter custom address:</label>
                <input
                  type="text"
                  placeholder="0x..."
                  value={formData.counterparty.startsWith('0x') && formData.counterparty.length > 10 ? formData.counterparty : ''}
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
                  <label>Covenant Title</label>
                  <input
                    type="text"
                    placeholder="e.g., Cross-Chain Arbitrage Partnership"
                    value={formData.title}
                    onChange={(e) => updateForm('title', e.target.value)}
                  />
                </div>
                <div className="form-group">
                  <label>Total Value (ETH)</label>
                  <input
                    type="number"
                    step="0.01"
                    placeholder="0.00"
                    value={formData.totalValue}
                    onChange={(e) => updateForm('totalValue', e.target.value)}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Description</label>
                <textarea
                  rows="4"
                  placeholder="Describe the covenant terms, deliverables, and expectations..."
                  value={formData.description}
                  onChange={(e) => updateForm('description', e.target.value)}
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Duration (days)</label>
                  <input
                    type="number"
                    value={formData.duration}
                    onChange={(e) => updateForm('duration', e.target.value)}
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
                        <label>Title</label>
                        <input
                          type="text"
                          value={milestone.title}
                          onChange={(e) => updateMilestone(index, 'title', e.target.value)}
                          placeholder="Milestone title"
                        />
                      </div>
                      <div className="form-group small">
                        <label>Amount (%)</label>
                        <input
                          type="number"
                          value={milestone.amount}
                          onChange={(e) => updateMilestone(index, 'amount', e.target.value)}
                          placeholder="0"
                        />
                      </div>
                      <div className="form-group small">
                        <label>Days</label>
                        <input
                          type="number"
                          value={milestone.deadline}
                          onChange={(e) => updateMilestone(index, 'deadline', e.target.value)}
                          placeholder="0"
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
                disabled={isCreating}
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
