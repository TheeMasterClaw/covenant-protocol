import React, { useState } from 'react';
import { ethers } from 'ethers';

export function CovenantForm({ factory, account }) {
  const [counterparty, setCounterparty] = useState('');
  const [covenantType, setCovenantType] = useState('TASK');
  const [termsHash, setTermsHash] = useState('');
  const [duration, setDuration] = useState('7');
  const [stake, setStake] = useState('0.1');
  const [loading, setLoading] = useState(false);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!factory || !account) return;
    
    setLoading(true);
    try {
      const durationSeconds = parseInt(duration) * 24 * 60 * 60;
      const stakeWei = ethers.parseEther(stake);
      
      const tx = await factory.createCovenant(
        counterparty,
        ethers.encodeBytes32String(covenantType),
        termsHash || 'ipfs://QmDefault',
        durationSeconds,
        { value: stakeWei }
      );
      
      await tx.wait();
      alert('Covenant created successfully!');
      
      // Reset form
      setCounterparty('');
      setTermsHash('');
    } catch (error) {
      console.error('Error creating covenant:', error);
      alert('Failed to create covenant: ' + error.message);
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="covenant-form">
      <h3>Create New Covenant</h3>
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label className="form-label">Counterparty Address</label>
          <input
            type="text"
            className="form-input"
            placeholder="0x..."
            value={counterparty}
            onChange={(e) => setCounterparty(e.target.value)}
            required
          />
        </div>
        
        <div className="form-row">
          <div className="form-group">
            <label className="form-label">Covenant Type</label>
            <select
              className="form-input"
              value={covenantType}
              onChange={(e) => setCovenantType(e.target.value)}
            >
              <option value="TASK">Task Agreement</option>
              <option value="ALLIANCE">Strategic Alliance</option>
              <option value="ESCROW">Escrow Service</option>
              <option value="CUSTOM">Custom</option>
            </select>
          </div>
          
          <div className="form-group">
            <label className="form-label">Duration (days)</label>
            <input
              type="number"
              className="form-input"
              value={duration}
              onChange={(e) => setDuration(e.target.value)}
              min="1"
              required
            />
          </div>
        </div>
        
        <div className="form-group">
          <label className="form-label">Stake Amount (ETH)</label>
          <input
            type="number"
            step="0.001"
            className="form-input"
            value={stake}
            onChange={(e) => setStake(e.target.value)}
            min="0.01"
            required
          />
          <small className="form-hint">Minimum: 0.01 ETH + 1% protocol fee</small>
        </div>
        
        <div className="form-group">
          <label className="form-label">Terms IPFS Hash (optional)</label>
          <input
            type="text"
            className="form-input"
            placeholder="ipfs://Qm..."
            value={termsHash}
            onChange={(e) => setTermsHash(e.target.value)}
          />
        </div>
        
        <button
          type="submit"
          className="btn btn-primary"
          disabled={loading || !account}
        >
          {loading ? 'Creating...' : 'Create Covenant'}
        </button>
      </form>
    </div>
  );
}
