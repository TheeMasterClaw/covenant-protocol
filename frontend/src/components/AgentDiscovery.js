import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ethers } from 'ethers';
import { AgentCard } from './AgentCard';
import AgentRegistryABI from '../abis/AgentRegistry.json';
import ReputationStakeABI from '../abis/ReputationStake.json';

const SKILL_OPTIONS = ['All', 'Solidity', 'AI/ML', 'Data Analysis', 'Security Audit', 'Smart Contracts', 'DeFi', 'Frontend', 'Backend', 'DevOps'];

const AGENT_REGISTRY_ADDRESS = process.env.REACT_APP_AGENT_REGISTRY_ADDRESS;
const REPUTATION_STAKE_ADDRESS = process.env.REACT_APP_REPUTATION_STAKE_ADDRESS;

export function AgentDiscovery({ contracts, account }) {
  const [agents, setAgents] = useState([]);
  const [filteredAgents, setFilteredAgents] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSkill, setSelectedSkill] = useState('All');
  const [sortBy, setSortBy] = useState('reputation');
  const [showActiveOnly, setShowActiveOnly] = useState(false);
  const [minReputation, setMinReputation] = useState(0);
  const [viewMode, setViewMode] = useState('grid');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchAgents = async () => {
      setLoading(true);
      setError(null);
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
          setLoading(false);
          return;
        }

        const totalAgents = await registry.totalAgents();
        const limit = totalAgents > 0 ? Number(totalAgents) : 0;

        let agentAddresses = [];
        if (limit > 0) {
          // Try getTopAgents first
          try {
            agentAddresses = await registry.getTopAgents(limit);
          } catch {
            // Fallback: iterate allAgents array
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
                reputationScore: Number(profile.reputationScore || stakeInfo.reputationScore || 0),
                tasksCompleted: Number(profile.tasksCompleted || 0),
                covenantsCompleted: Number(profile.covenantsCompleted || 0),
                skills: profile.skillNames?.length > 0 ? profile.skillNames : profile.skills?.map(s => `Skill ${s}`) || [],
                isActive: profile.isActive || false,
                stakeAmount: ethers.formatEther(stakeInfo.totalStaked || 0n),
              };
            } catch (e) {
              return null;
            }
          })
        );

        const validAgents = agentData.filter(a => a !== null);
        setAgents(validAgents);
      } catch (err) {
        console.error('Error fetching agents:', err);
        setError(err.message || 'Failed to load agents');
        setAgents([]);
      } finally {
        setLoading(false);
      }
    };

    fetchAgents();
  }, [contracts]);

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

      {loading && (
        <div className="empty-state">
          <div className="empty-icon">⏳</div>
          <h3>Loading agents...</h3>
          <p>Fetching verified agents from the blockchain</p>
        </div>
      )}

      {!loading && error && (
        <div className="empty-state">
          <div className="empty-icon">⚠️</div>
          <h3>Error loading agents</h3>
          <p>{error}</p>
        </div>
      )}

      {!loading && !error && (
        <>
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
        </>
      )}
    </div>
  );
}
