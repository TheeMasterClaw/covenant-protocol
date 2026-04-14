import React, { useState } from 'react';
import { ethers } from 'ethers';

function isValidHash(value) {
  if (!value || value.trim().length === 0) return false;
  if (value.startsWith('ipfs://')) return true;
  // Accept hex strings (with or without 0x) of reasonable hash length
  const hexPattern = /^(0x)?[0-9a-fA-F]{46,64}$/;
  // Accept base58 / base32 style CIDs (Qm... or bafy...)
  const cidPattern = /^(Qm[1-9A-HJ-NP-Za-km-z]{44}|bafy[1-9A-HJ-NP-Za-km-z]{55,})$/;
  return hexPattern.test(value) || cidPattern.test(value);
}

export function CovenantForm({ factory, account }) {
  const [counterparty, setCounterparty] = useState('');
  const [covenantType, setCovenantType] = useState('TASK');
  const [termsHash, setTermsHash] = useState('');
  const [duration, setDuration] = useState('7');
  const [stake, setStake] = useState('0.1');
  const [loading, setLoading] = useState(false);
  const [validationError, setValidationError] = useState(null);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!factory || !account) {
      alert('Please connect your wallet and ensure the factory contract is available.');
      return;
    }

    setValidationError(null);

    if (!ethers.isAddress(counterparty)) {
      setValidationError('Please enter a valid counterparty Ethereum address.');
      return;
    }

    if (!isValidHash(termsHash)) {
      setValidationError('Terms hash is required and must be a valid IPFS hash (ipfs://...) or CID.');
      return;
    }

    setLoading(true);
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const factoryWithSigner = factory.connect(signer);

      const durationSeconds = parseInt(duration) * 24 * 60 * 60;
      const stakeWei = ethers.parseEther(stake);
      
      const tx = await factoryWithSigner.createCovenant(
        counterparty,
        ethers.encodeBytes32String(covenantType),
        termsHash.trim(),
        durationSeconds,
        { value: stakeWei }
      );
      
      await tx.wait();
      alert('Covenant created successfully!');
      
      // Reset form
      setCounterparty('');
      setTermsHash('');
      setDuration('7');
      setStake('0.1');
    } catch (error) {
      console.error('Error creating covenant:', error);
      alert('Failed to create covenant: ' + (error?.reason || error?.message || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="covenant-form">
      <h3>Create New Covenant</h3>
      <form onSubmit={handleSubmit}>
        {validationError && (
          <div className="form-error" style={{ color: '#ff4757', marginBottom: '16px', padding: '12px', background: 'rgba(255,71,87,0.1)', borderRadius: '8px' }}>
            {validationError}
          </div>
        )}

        <div className="form-group">
          <label className="form-label">Counterparty Address *</label>
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
            <label className="form-label">Covenant Type *</label>
            <select
              className="form-input"
              value={covenantType}
              onChange={(e) => setCovenantType(e.target.value)}
              required
            >
              <option value="TASK">Task Agreement</option>
              <option value="ALLIANCE">Strategic Alliance</option>
              <option value="ESCROW">Escrow Service</option>
              <option value="CUSTOM">Custom</option>
            </select>
          </div>
          
          <div className="form-group">
            <label className="form-label">Duration (days) *</label>
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
          <label className="form-label">Stake Amount (ETH) *</label>
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
          <label className="form-label">Terms IPFS Hash *</label>
          <input
            type="text"
            className="form-input"
            placeholder="ipfs://Qm..."
            value={termsHash}
            onChange={(e) => setTermsHash(e.target.value)}
            required
          />
          <small className="form-hint">Must start with ipfs:// or be a valid CID/hash</small>
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
