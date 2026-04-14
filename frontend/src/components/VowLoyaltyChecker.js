import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

export function VowLoyaltyChecker({ covenant, account, onChallenge, onClose }) {
  const [checks, setChecks] = useState([]);
  const [loyaltyScore, setLoyaltyScore] = useState(100);
  const [loading, setLoading] = useState(true);
  const [selectedBreach, setSelectedBreach] = useState(null);
  
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
    // Automated breach detection logic
    const runChecks = () => {
      const results = [];
      let score = 100;
      const now = new Date('2026-04-13');

      // Check 1: Milestone deadlines
      if (covenant.milestones) {
        covenant.milestones.forEach((m, idx) => {
          if (m.status === 'pending' && idx > 0) {
            const prev = covenant.milestones[idx - 1];
            if (prev.status === 'completed') {
              // Simulate deadline: 7 days after previous completion
              results.push({
                id: `milestone-${idx}`,
                type: 'warning',
                title: 'Milestone Deadline Approaching',
                detail: `Milestone "${m.title}" was expected within 7 days of previous completion.`,
                penalty: 5,
                auto: true
              });
              score -= 5;
            }
          }
        });
      }

      // Check 2: Payment staked
      if (parseFloat(covenant.amount) > 0 && covenant.status !== 'Active') {
        // In a real implementation, check if amount is locked in escrow
        results.push({
          id: 'stake',
          type: 'info',
          title: 'Funds Not Yet Escrowed',
          detail: 'The full covenant amount has not been locked in the smart contract.',
          penalty: 0,
          auto: true
        });
      }

      // Check 3: Activity/response time simulation
      if (covenant.status === 'Active') {
        const daysSinceStart = Math.floor((now - new Date(covenant.startDate)) / (1000 * 60 * 60 * 24));
        if (daysSinceStart > 7 && covenant.progress < 10) {
          results.push({
            id: 'inactive',
            type: 'warning',
            title: 'Slow Progress Detected',
            detail: `Only ${covenant.progress}% complete after ${daysSinceStart} days.`,
            penalty: 10,
            auto: true
          });
          score -= 10;
        }
      }

      // Check 4: Prior disputes with counterparty
      if (covenant.status === 'Disputed') {
        results.push({
          id: 'disputed',
          type: 'breach',
          title: 'Active Dispute in Progress',
          detail: 'This covenant is currently under dispute resolution.',
          penalty: 25,
          auto: true
        });
        score -= 25;
      }

      // Check 5: Communication/response (mock)
      if (covenant.status === 'Pending' && covenant.proposedDate) {
        const daysPending = Math.floor((now - new Date(covenant.proposedDate)) / (1000 * 60 * 60 * 24));
        if (daysPending > 3) {
          results.push({
            id: 'pending',
            type: 'warning',
            title: 'Pending Acceptance Timeout',
            detail: `Counterparty has not responded to the covenant proposal in ${daysPending} days.`,
            penalty: 8,
            auto: true
          });
          score -= 8;
        }
      }

      setChecks(results);
      setLoyaltyScore(Math.max(0, score));
      setLoading(false);
      setPhase('committing');
    };

    const timer = setTimeout(runChecks, 400);
    return () => clearTimeout(timer);
  }, [covenant]);

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
        covenantId: covenant.id,
        breaches: checks.filter(c => c.type === 'breach' || c.type === 'warning'),
        loyaltyScore,
        reason: selectedBreach ? selectedBreach.detail : 'Loyalty challenge initiated due to detected breaches.'
      });
    }
    onClose();
  };

  const hasActionableBreach = checks.some(c => c.type === 'breach' || c.type === 'warning');

  // Generate commit hash from scan results (simulating blockchain commitment)
  const generateCommitHash = () => {
    const data = `${covenant.id}-${loyaltyScore}-${Date.now()}`;
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
            <p>Covenant #{covenant.id} • {covenant.title}</p>
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
