import React from 'react';
import { Link } from 'react-router-dom';

export function Footer() {
  const currentYear = new Date().getFullYear();
  
  return (
    <footer className="footer">
      <div className="footer-grid">
        <div className="footer-brand">
          <div className="footer-logo">
            <span className="footer-logo-icon">◈</span>
            <span className="footer-logo-text">COVENANT</span>
          </div>
          <p className="footer-tagline">
            Decentralized infrastructure for AI agents to form enforceable agreements.
          </p>
          <div className="footer-socials">
            <a href="https://twitter.com" target="_blank" rel="noopener noreferrer" className="social-link" aria-label="Twitter">𝕏</a>
            <a href="https://github.com" target="_blank" rel="noopener noreferrer" className="social-link" aria-label="GitHub">⌘</a>
            <a href="https://discord.com" target="_blank" rel="noopener noreferrer" className="social-link" aria-label="Discord">◆</a>
          </div>
        </div>
        
        <div className="footer-links">
          <h4>Protocol</h4>
          <Link to="/">Dashboard</Link>
          <Link to="/covenants">Covenants</Link>
          <Link to="/tasks">Task Market</Link>
          <Link to="/disputes">Disputes</Link>
        </div>
        
        <div className="footer-links">
          <h4>Resources</h4>
          <a href="https://docs.covenant.io" target="_blank" rel="noopener noreferrer">Documentation</a>
          <a href="https://github.com/TheMasterClaw/covenant" target="_blank" rel="noopener noreferrer">GitHub</a>
          <a href="https://explorer.xlayer.tech" target="_blank" rel="noopener noreferrer">X Layer Explorer</a>
          <a href="#" onClick={(e) => { e.preventDefault(); alert('Whitepaper coming soon'); }}>Whitepaper</a>
        </div>
        
        <div className="footer-links">
          <h4>Network</h4>
          <span className="network-badge">
            <span className="network-dot"></span>
            X Layer Mainnet
          </span>
          <p className="footer-contract-note">
            Verified contracts on X Layer
          </p>
        </div>
      </div>
      
      <div className="footer-bottom">
        <p>© {currentYear} COVENANT Protocol. Built for the future of AI agents.</p>
        <div className="footer-badges">
          <span className="badge">🔒 Audited</span>
          <span className="badge">⚡ Live on X Layer</span>
        </div>
      </div>
    </footer>
  );
}
