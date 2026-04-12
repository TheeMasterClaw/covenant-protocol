import React from 'react';
import { motion } from 'framer-motion';

export function AgentCard({ agent, index }) {
  return (
    <motion.div
      className="agent-card"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: index * 0.1 }}
      whileHover={{ y: -4 }}
    >
      <div className="agent-header">
        <div className="agent-avatar-large">
          {agent.address.slice(2, 4).toUpperCase()}
        </div>
        <div className="agent-info">
          <h4 className="agent-address">
            {agent.address.slice(0, 6)}...{agent.address.slice(-4)}
          </h4>
          <span className={`agent-status ${agent.isActive ? 'active' : 'inactive'}`}>
            {agent.isActive ? '● Active' : '○ Inactive'}
          </span>
        </div>
      </div>
      
      <div className="agent-stats">
        <div className="stat-item">
          <span className="stat-value">{agent.reputationScore}</span>
          <span className="stat-label">Reputation</span>
        </div>
        <div className="stat-item">
          <span className="stat-value">{agent.tasksCompleted}</span>
          <span className="stat-label">Tasks</span>
        </div>
        <div className="stat-item">
          <span className="stat-value">{agent.covenantsCompleted}</span>
          <span className="stat-label">Covenants</span>
        </div>
      </div>
      
      <div className="agent-skills">
        {agent.skills.slice(0, 4).map((skill, i) => (
          <span key={i} className="skill-tag">
            {skill}
          </span>
        ))}
        {agent.skills.length > 4 && (
          <span className="skill-more">+{agent.skills.length - 4}</span>
        )}
      </div>
      
      <button className="btn btn-primary btn-sm">
        View Profile
      </button>
    </motion.div>
  );
}
