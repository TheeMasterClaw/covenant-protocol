import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AgentCard } from './AgentCard';

const MOCK_AGENTS = [
  { address: '0x1234...5678', reputationScore: 947, tasksCompleted: 156, covenantsCompleted: 42, skills: ['Solidity', 'AI/ML', 'Data Analysis', 'Security Audit'], isActive: true, stakeAmount: '45.2' },
  { address: '0xabcd...efgh', reputationScore: 823, tasksCompleted: 89, covenantsCompleted: 23, skills: ['Smart Contracts', 'DeFi', 'Frontend'], isActive: true, stakeAmount: '32.1' },
  { address: '0x9876...5432', reputationScore: 756, tasksCompleted: 67, covenantsCompleted: 18, skills: ['Backend', 'DevOps', 'Monitoring'], isActive: true, stakeAmount: '28.5' },
  { address: '0xwxyz...mnop', reputationScore: 691, tasksCompleted: 45, covenantsCompleted: 12, skills: ['Design', 'UX', 'Documentation'], isActive: false, stakeAmount: '15.0' },
  { address: '0xqwer...tyui', reputationScore: 634, tasksCompleted: 34, covenantsCompleted: 8, skills: ['Testing', 'QA', 'Automation'], isActive: true, stakeAmount: '12.3' },
  { address: '0xasdf...ghjk', reputationScore: 892, tasksCompleted: 134, covenantsCompleted: 38, skills: ['Solidity', 'ZK-Proofs', 'Cryptography'], isActive: true, stakeAmount: '50.0' },
];

const SKILL_OPTIONS = ['All', 'Solidity', 'AI/ML', 'Data Analysis', 'Security Audit', 'Smart Contracts', 'DeFi', 'Frontend', 'Backend', 'DevOps'];

export function AgentDiscovery({ contracts, account }) {
  const [agents, setAgents] = useState(MOCK_AGENTS);
  const [filteredAgents, setFilteredAgents] = useState(MOCK_AGENTS);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSkill, setSelectedSkill] = useState('All');
  const [sortBy, setSortBy] = useState('reputation');
  const [showActiveOnly, setShowActiveOnly] = useState(false);
  const [minReputation, setMinReputation] = useState(0);
  const [viewMode, setViewMode] = useState('grid');

  useEffect(() => {
    let filtered = [...agents];

    // Search filter
    if (searchQuery) {
      filtered = filtered.filter(agent => 
        agent.address.toLowerCase().includes(searchQuery.toLowerCase()) ||
        agent.skills.some(skill => skill.toLowerCase().includes(searchQuery.toLowerCase()))
      );
    }

    // Skill filter
    if (selectedSkill !== 'All') {
      filtered = filtered.filter(agent => agent.skills.includes(selectedSkill));
    }

    // Active filter
    if (showActiveOnly) {
      filtered = filtered.filter(agent => agent.isActive);
    }

    // Reputation filter
    filtered = filtered.filter(agent => agent.reputationScore >= minReputation);

    // Sort
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'reputation': return b.reputationScore - a.reputationScore;
        case 'tasks': return b.tasksCompleted - a.tasksCompleted;
        case 'covenants': return b.covenantsCompleted - a.covenantsCompleted;
        case 'stake': return parseFloat(b.stakeAmount) - parseFloat(a.stakeAmount);
        default: return 0;
      }
    });

    setFilteredAgents(filtered);
  }, [agents, searchQuery, selectedSkill, sortBy, showActiveOnly, minReputation]);

  return (
    <div className="agent-discovery">
      <div className="discovery-header">
        <h2>Agent Discovery</h2>
        <p>Find verified AI agents by skills, reputation, and activity</p>
      </div>

      <div className="discovery-filters">
        <div className="filter-row">
          <div className="search-box">
            <span className="search-icon">🔍</span>
            <input
              type="text"
              placeholder="Search by address or skill..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>

          <select 
            className="filter-select"
            value={selectedSkill}
            onChange={(e) => setSelectedSkill(e.target.value)}
          >
            {SKILL_OPTIONS.map(skill => (
              <option key={skill} value={skill}>{skill}</option>
            ))}
          </select>

          <select
            className="filter-select"
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
          >
            <option value="reputation">Sort by Reputation</option>
            <option value="tasks">Sort by Tasks</option>
            <option value="covenants">Sort by Covenants</option>
            <option value="stake">Sort by Stake</option>
          </select>

          <div className="view-toggle">
            <button 
              className={viewMode === 'grid' ? 'active' : ''}
              onClick={() => setViewMode('grid')}
            >
              ⊞ Grid
            </button>
            <button 
              className={viewMode === 'list' ? 'active' : ''}
              onClick={() => setViewMode('list')}
            >
              ☰ List
            </button>
          </div>
        </div>

        <div className="filter-row secondary">
          <label className="checkbox-label">
            <input
              type="checkbox"
              checked={showActiveOnly}
              onChange={(e) => setShowActiveOnly(e.target.checked)}
            />
            Active agents only
          </label>

          <div className="range-filter">
            <span>Min Reputation: {minReputation}+</span>
            <input
              type="range"
              min="0"
              max="1000"
              value={minReputation}
              onChange={(e) => setMinReputation(Number(e.target.value))}
            />
          </div>

          <div className="results-count">
            {filteredAgents.length} agent{filteredAgents.length !== 1 ? 's' : ''} found
          </div>
        </div>
      </div>

      <div className={`agents-container ${viewMode}`}>
        <AnimatePresence mode="popLayout">
          {filteredAgents.map((agent, index) => (
            <motion.div
              key={agent.address}
              layout
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.9 }}
              transition={{ duration: 0.3, delay: index * 0.05 }}
            >
              <AgentCard agent={agent} index={index} />
            </motion.div>
          ))}
        </AnimatePresence>
      </div>

      {filteredAgents.length === 0 && (
        <div className="empty-state">
          <div className="empty-icon">🔍</div>
          <h3>No agents found</h3>
          <p>Try adjusting your filters or search query</p>
        </div>
      )}
    </div>
  );
}
