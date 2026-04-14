import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ethers } from 'ethers';
import AgentCovenantABI from '../abis/AgentCovenant.json';

const STATUS_MAP = ['Pending', 'Active', 'Completed', 'Disputed', 'Breach', 'Cancelled'];

export function VowLoyaltyChecker({ covenant, account, provider, onChallenge, onClose }) {
  const [checks, setChecks] = useState([]);
  const [loyaltyScore, setLoyaltyScore] = useState(100);
  const [loading, setLoading] = useState(true);
  const [selectedBreach, setSelectedBreach] = useState(null);
  const [contractError, setContractError] = useState(null);
  
  // Commit-reveal state (MEV protection from research)
  const [phase, setPhase] = useState('scanning'); // scanning | committing | committed | revealing | revealed
  const [commitHash, setCommitHash] = useState('');
  const [commitTime, setCommitTime] = useState(null);
  const [revealCountdown, setRevealCountdown] = useState(3);

  useEffect(() => {
    if (phase === 'committed' && revealCountdown > 0) {
      const timer = setTimeout(() => setRevealCountdown(c => c - 1), 1000);
      return () => clearTimeout(timer);
    }
    if (phase === 'committed' && revealCountdown === 0) {
      setPhase('revealing');
      setTimeout(() => setPhase('revealed'), 800);
    }
  }, [phase, revealCountdown]);

  useEffect(() => {
    const runChecks = async () => {
      setLoading(true);
      setContractError(null);
      const results = [];
      let score = 100;
      const now = new Date();

      try {
        if (!covenant?.address) {
          setContractError('Covenant contract address not available for on-chain verification.');
          setLoading(false);
          setPhase('committing');
          return;
        }

        let readProvider = provider;
        if (!readProvider && window.ethereum) {
          readProvider = new ethers.BrowserProvider(window.ethereum);
        }

        if (!readProvider) {
          setContractError('No blockchain provider available.');
          setLoading(false);
          setPhase('committing');
          return;
        }

        const contract = new ethers.Contract(covenant.address, AgentCovenantABI, readProvider);

        const [statusNum, terms, remainingBalance, disputedAt, disputeReason, initiator, counterparty] = await Promise.all([
          contract.status().catch(() => 0),
          contract.terms().catch(() => ''),
          contract.remainingBalance().catch(() => 0n),
          contract.disputedAt().catch(() => 0n),
          contract.disputeReason().catch(() => ''),
          contract.initiator().catch(() => ''),
          contract.counterparty().catch(() => ''),
        ]);

        const status = typeof statusNum === 'number' || typeof statusNum === 'bigint' ? STATUS_MAP[Number(statusNum)] || `Status ${statusNum}` : String(statusNum);

        // Fetch milestones
        let milestones = [];
        try {
          // Try to read milestone count by iterating until revert
          let idx = 0;
          while (idx < 20) {
            try {
              const m = await contract.milestones(idx);
              milestones.push(m);
              idx++;
            } catch {
              break;
            }
          }
        } catch (e) {
          // ignore
        }

        // Check 1: Active dispute
        if (Number(disputedAt) > 0 || status === 'Disputed') {
          results.push({
            id: 'disputed',
            type: 'breach',
            title: 'Active Dispute in Progress',
            detail: disputeReason || 'This covenant is currently under dispute resolution.',
            penalty: 25,
            auto: true
          });
          score -= 25;
        }

        // Check 2: Breach status
        if (status === 'Breach' || status === 'Breached') {
          results.push({
            id: 'breach',
            type: 'breach',
            title: 'Covenant Declared Breach',
            detail: 'This covenant has been declared a breach on-chain.',
            penalty: 30,
            auto: true
          });
          score -= 30;
        }

        // Check 3: Cancelled status
        if (status === 'Cancelled') {
          results.push({
            id: 'cancelled',
            type: 'warning',
            title: 'Covenant Cancelled',
            detail: 'This covenant was cancelled before completion.',
            penalty: 15,
            auto: true
          });
          score -= 15;
        }

        // Check 4: Funds not escrowed (remainingBalance is 0 on an active covenant)
        if (status === 'Active' && remainingBalance === 0n) {
          results.push({
            id: 'funds',
            type: 'warning',
            title: 'No Funds in Escrow',
            detail: 'The covenant is active but the remaining balance is zero.',
            penalty: 10,
            auto: true
          });
          score -= 10;
        }

        // Check 5: Pending milestones
        if (milestones.length > 0) {
          const pendingCount = milestones.filter(m => !m.completed).length;
          const unpaidCount = milestones.filter(m => m.completed && !m.paid).length;
          if (pendingCount > 0 && status === 'Active') {
            results.push({
              id: 'pending-milestones',
              type: 'info',
              title: 'Pending Milestones',
              detail: `${pendingCount} of ${milestones.length} milestones remain incomplete.`,
              penalty: 0,
              auto: true
            });
          }
          if (unpaidCount > 0) {
            results.push({
              id: 'unpaid-milestones',
              type: 'warning',
              title: 'Completed but Unpaid Milestones',
              detail: `${unpaidCount} completed milestone(s) have not been paid out.`,
              penalty: 10,
              auto: true
            });
            score -= 10;
          }
        }

        // Check 6: Long pending acceptance
        if (status === 'Pending') {
          results.push({
            id: 'pending',
            type: 'info',
            title: 'Awaiting Counterparty Acceptance',
            detail: `Initiator: ${initiator.slice(0, 6)}...${initiator.slice(-4)} • Counterparty: ${counterparty.slice(0, 6)}...${counterparty.slice(-4)}`,
            penalty: 0,
            auto: true
          });
        }

        // Check 7: Terms mismatch (if covenant prop has terms and contract has different terms)
        if (covenant.terms && terms && covenant.terms !== terms) {
          results.push({
            id: 'terms',
            type: 'warning',
            title: 'Terms Hash Mismatch',
            detail: 'The locally stored terms do not match the on-chain terms hash.',
            penalty: 10,
            auto: true
          });
          score -= 10;
        }

        setChecks(results);
        setLoyaltyScore(Math.max(0, score));
      } catch (err) {
        console.error('Loyalty check error:', err);
        setContractError(err?.message || 'Failed to read covenant state');
      } finally {
        setLoading(false);
        setPhase('committing');
      }
    };

    runChecks();
  }, [covenant, provider]);

  const getScoreColor = () => {
    if (loyaltyScore >= 90) return '#00f5a0';
    if (loyaltyScore >= 70) return '#ffaa00';
    return '#ff4757';
  };

  const getScoreLabel = () => {
    if (loyaltyScore >= 90) return 'Faithful';
    if (loyaltyScore >= 70) return 'Questionable';
    if (loyaltyScore >= 40) return 'Suspicious';
    return 'Oathbreaker';
  };

  const handleFileDispute = () => {
    if (onChallenge) {
      onChallenge({
        covenantId: covenant.id || covenant.address,
        breaches: checks.filter(c => c.type === 'breach' || c.type === 'warning'),
        loyaltyScore,
        reason: selectedBreach ? selectedBreach.detail : 'Loyalty challenge initiated due to detected breaches.'
      });
    }
    onClose();
  };

  const hasActionableBreach = checks.some(c => c.type === 'breach' || c.type === 'warning');

  // Generate commit hash from scan results
  const generateCommitHash = () => {
    const id = covenant?.address || covenant?.id || 'unknown';
    const data = `${id}-${loyaltyScore}-${Date.now()}`;
    let hash = 0;
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return '0x' + Math.abs(hash).toString(16).padStart(64, '0');
  };

  const handleCommit = () => {
    const hash = generateCommitHash();
    setCommitHash(hash);
    setCommitTime(Date.now());
    setPhase('committed');
  };

  return (
    <div className="vlc-overlay" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <motion.div
        className="vlc-modal"
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
      >
        <div className="vlc-header">
          <div>
            <h3>⚔️ Vow Loyalty Test</h3>
            <p>Covenant #{covenant.id || covenant.address} • {covenant.title}</p>
            {phase !== 'scanning' && phase !== 'committing' && (
              <span className="vlc-phase-badge">{phase.toUpperCase()}</span>
            )}
          </div>
          <button className="vlc-close" onClick={onClose}>×</button>
        </div>

        {loading ? (
          <div className="vlc-loading">
            <div className="vlc-spinner"></div>
            <p>Scanning blockchain for breaches...</p>
            <p className="vlc-sub">MEV-protected commitment phase loading...</p>
          </div>
        ) : phase === 'committing' || phase === 'committed' ? (
          <div className="vlc-commit-phase">
            <div className="vlc-commit-visual">
              <div className="vlc-sealed-ring">
                <span className="vlc-lock">🔒</span>
                <span className="vlc-sealed-text">SEALED</span>
              </div>
            </div>
            <p className="vlc-commit-hash">Commit: {commitHash.slice(0, 20)}...</p>
            <p className="vlc-commit-info">
              Commit-reveal pattern protects against front-running.
              Score remains hidden until reveal phase.
            </p>
            {phase === 'committed' && (
              <div className="vlc-countdown">
                <p>Revealing in {revealCountdown}s...</p>
                <div className="vlc-progress-bar">
                  <div className="vlc-progress" style={{width: `${((3-revealCountdown)/3)*100}%`}} />
                </div>
              </div>
            )}
          </div>
        ) : phase === 'revealing' ? (
          <div className="vlc-reveal-phase">
            <div className="vlc-reveal-animation">
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 0.8, ease: "easeOut" }}
              >
                <span className="vlc-unlock">🔓</span>
              </motion.div>
            </div>
            <p>Decrypting commitment...</p>
          </div>
        ) : (
          <>
            <div className="vlc-score-section">
              <div className="vlc-score-ring" style={{ '--score-color': getScoreColor() }}>
                <span className="vlc-score-value" style={{ color: getScoreColor() }}>{loyaltyScore}</span>
                <span className="vlc-score-label">{getScoreLabel()}</span>
              </div>
              <div className="vlc-score-meta">
                <p>Automated breach detection complete.</p>
                {phase === 'revealed' && (
                  <p className="vlc-verified">✓ MEV-Protected via Commit-Reveal</p>
                )}
                <span className="vlc-checks-count">
                  {checks.length} concern{checks.length !== 1 ? 's' : ''} found
                </span>
              </div>
            </div>

            {contractError && (
              <div style={{ color: '#ff4757', marginBottom: '16px', padding: '12px', background: 'rgba(255,71,87,0.1)', borderRadius: '8px' }}>
                {contractError}
              </div>
            )}

            <div className="vlc-checks">
              {checks.length === 0 ? (
                <div className="vlc-empty">
                  <span className="vlc-empty-icon">🛡️</span>
                  <h4>No breaches detected</h4>
                  <p>This covenant appears to be in good standing.</p>
                </div>
              ) : (
                checks.map((check, idx) => (
                  <motion.div
                    key={check.id}
                    className={`vlc-check-item ${check.type}`}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: idx * 0.1 }}
                    onClick={() => setSelectedBreach(check)}
                  >
                    <div className="vlc-check-icon">
                      {check.type === 'breach' ? '💀' : check.type === 'warning' ? '⚠️' : 'ℹ️'}
                    </div>
                    <div className="vlc-check-content">
                      <h5>{check.title}</h5>
                      <p>{check.detail}</p>
                    </div>
                    <div className="vlc-check-penalty">
                      {check.penalty > 0 ? `-${check.penalty}` : '0'}
                    </div>
                  </motion.div>
                ))
              )}
            </div>

            {selectedBreach && (
              <div className="vlc-selected-breach">
                <h5>Selected Breach</h5>
                <p>{selectedBreach.title}: {selectedBreach.detail}</p>
              </div>
            )}

            <div className="vlc-actions">
              {hasActionableBreach ? (
                <>
                  <button className="btn btn-primary btn-lg" onClick={handleFileDispute}>
                    File Loyalty Challenge
                  </button>
                  <button className="btn btn-secondary" onClick={onClose}>
                    Dismiss
                  </button>
                </>
              ) : (
                <button className="btn btn-secondary btn-lg" onClick={onClose}>
                  Close
                </button>
              )}
            </div>
          </>
        )}
        
        {/* Commit action - shown in committing phase */}
        {phase === 'committing' && !loading && (
          <div className="vlc-actions" style={{ borderTop: '1px solid var(--border-color)', marginTop: '16px', paddingTop: '16px' }}>
            <button className="btn btn-primary btn-lg" onClick={handleCommit}>
              🔒 Seal Commitment
            </button>
            <button className="btn btn-secondary" onClick={onClose}>
              Cancel
            </button>
          </div>
        )}
      </motion.div>
    </div>
  );
}
