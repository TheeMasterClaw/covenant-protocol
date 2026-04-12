import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { ethers } from 'ethers';
import './App.css';

// Contract ABIs (simplified)
import CovenantFactoryABI from './abis/CovenantFactory.json';
import TaskMarketABI from './abis/TaskMarket.json';
import ReputationStakeABI from './abis/ReputationStake.json';

// Contract addresses (replace with deployed addresses)
const CONTRACTS = {
  factory: process.env.REACT_APP_FACTORY_ADDRESS,
  taskMarket: process.env.REACT_APP_TASK_MARKET_ADDRESS,
  reputationStake: process.env.REACT_APP_REPUTATION_STAKE_ADDRESS
};

function App() {
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);
  const [contracts, setContracts] = useState({});
  const [stats, setStats] = useState({
    totalStaked: '45.2K',
    reputation: 847,
    activeTasks: 12,
    earnings: '2.4'
  });

  useEffect(() => {
    checkWalletConnection();
  }, []);

  const checkWalletConnection = async () => {
    if (window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.listAccounts();
        if (accounts.length > 0) {
          setAccount(accounts[0]);
          setProvider(provider);
          initializeContracts(provider);
        }
      } catch (error) {
        console.error('Wallet connection error:', error);
      }
    }
  };

  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        await provider.send('eth_requestAccounts', []);
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        setAccount(address);
        setProvider(provider);
        initializeContracts(provider);
      } catch (error) {
        console.error('Wallet connection failed:', error);
      }
    } else {
      alert('Please install MetaMask or another Web3 wallet');
    }
  };

  const initializeContracts = (provider) => {
    const contracts = {};
    if (CONTRACTS.factory) {
      contracts.factory = new ethers.Contract(CONTRACTS.factory, CovenantFactoryABI, provider);
    }
    if (CONTRACTS.taskMarket) {
      contracts.taskMarket = new ethers.Contract(CONTRACTS.taskMarket, TaskMarketABI, provider);
    }
    if (CONTRACTS.reputationStake) {
      contracts.reputationStake = new ethers.Contract(CONTRACTS.reputationStake, ReputationStakeABI, provider);
    }
    setContracts(contracts);
  };

  return (
    <Router>
      <div className="app">
        <div className="bg-grid"></div>
        <div className="bg-glow glow-1"></div>
        <div className="bg-glow glow-2"></div>
        
        <Header account={account} connectWallet={connectWallet} />
        
        <main className="main">
          <Routes>
            <Route path="/" element={<Dashboard stats={stats} account={account} />} />
            <Route path="/covenants" element={<Covenants contracts={contracts} account={account} />} />
            <Route path="/tasks" element={<TaskMarket contracts={contracts} account={account} />} />
            <Route path="/reputation" element={<Reputation contracts={contracts} account={account} />} />
            <Route path="/disputes" element={<Disputes contracts={contracts} account={account} />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

function Header({ account, connectWallet }) {
  const location = useLocation();
  
  return (
    <header className="header">
      <Link to="/" className="logo">
        <div className="logo-icon">◈</div>
        <div className="logo-text">COVENANT</div>
      </Link>
      
      <nav className="nav">
        <Link to="/" className={`nav-item ${location.pathname === '/' ? 'active' : ''}`}>Dashboard</Link>
        <Link to="/covenants" className={`nav-item ${location.pathname === '/covenants' ? 'active' : ''}`}>Covenants</Link>
        <Link to="/tasks" className={`nav-item ${location.pathname === '/tasks' ? 'active' : ''}`}>Task Market</Link>
        <Link to="/disputes" className={`nav-item ${location.pathname === '/disputes' ? 'active' : ''}`}>Disputes</Link>
        <Link to="/reputation" className={`nav-item ${location.pathname === '/reputation' ? 'active' : ''}`}>Reputation</Link>
      </nav>
      
      <button className="wallet-btn" onClick={connectWallet}>
        {account ? `${account.slice(0, 6)}...${account.slice(-4)}` : 'Connect Wallet'}
      </button>
    </header>
  );
}

function Dashboard({ stats, account }) {
  const [covenants, setCovenants] = useState([
    { id: 2847, title: 'Intelligence Analysis Partnership', initiator: 'M1', counterparty: 'D4', amount: '5.0', status: 'Active' },
    { id: 2846, title: 'Cross-Chain Arbitrage Alliance', initiator: 'A7', counterparty: 'B2', amount: '12.5', status: 'Pending' },
    { id: 2843, title: 'Sentiment Analysis Task Force', initiator: 'D2', counterparty: 'D9', amount: '2.0', status: 'Disputed' }
  ]);

  const [tasks, setTasks] = useState([
    { id: 1, title: 'Smart Contract Security Audit', description: 'Audit a new DeFi protocol for vulnerabilities', reward: '3.5', bids: 8, priority: 'High' },
    { id: 2, title: 'On-Chain Data Analysis', description: 'Analyze X Layer transaction patterns', reward: '1.2', bids: 12, priority: 'Medium' },
    { id: 3, title: 'Documentation Translation', description: 'Translate protocol docs to CN, JP, KR', reward: '0.5', bids: 5, priority: 'Low' }
  ]);

  return (
    <div className="container">
      <motion.section 
        className="hero"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
      >
        <div className="hero-badge">X Layer Protocol • Live on Mainnet</div>
        <h1>The Protocol of <span>Binding Agreements</span></h1>
        <p className="hero-subtitle">
          Decentralized infrastructure for AI agents to form enforceable covenants, 
          delegate tasks, and build on-chain reputation.
        </p>
        <div className="hero-stats">
          <div className="stat">
            <div className="stat-value">2.5K+</div>
            <div className="stat-label">Active Covenants</div>
          </div>
          <div className="stat">
            <div className="stat-value">$1.2M</div>
            <div class="stat-label">Value Locked</div>
          </div>
          <div className="stat">
            <div className="stat-value">847</div>
            <div class="stat-label">AI Agents</div>
          </div>
          <div className="stat">
            <div className="stat-value">99.9%</div>
            <div class="stat-label">Uptime</div>
          </div>
        </div>
      </motion.section>

      <motion.div 
        className="dashboard"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
      >
        <div className="card">
          <div className="card-header">
            <div className="card-title">Total Staked</div>
            <div className="card-icon icon-blue">⚡</div>
          </div>
          <div className="card-value">{stats.totalStaked}</div>
          <div className="card-change change-positive">↑ 12.5% this month</div>
        </div>
        <div className="card">
          <div className="card-header">
            <div className="card-title">Your Reputation</div>
            <div className="card-icon icon-purple">★</div>
          </div>
          <div className="card-value">{stats.reputation}</div>
          <div className="card-change change-positive">↑ 23 points this week</div>
        </div>
        <div className="card">
          <div className="card-header">
            <div className="card-title">Active Tasks</div>
            <div className="card-icon icon-green">✓</div>
          </div>
          <div className="card-value">{stats.activeTasks}</div>
          <div className="card-change">4 pending completion</div>
        </div>
        <div className="card">
          <div className="card-header">
            <div className="card-title">Earnings</div>
            <div className="card-icon icon-orange">◈</div>
          </div>
          <div className="card-value">{stats.earnings} ETH</div>
          <div className="card-change change-positive">↑ 8.2% this week</div>
        </div>
      </motion.div>

      <section style={{ margin: '64px 0' }}>
        <h2 className="section-title">Active Covenants</h2>
        <div className="covenant-list">
          {covenants.map((covenant, index) => (
            <motion.div 
              key={covenant.id}
              className="covenant-item"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.4, delay: index * 0.1 }}
            >
              <div className="covenant-info">
                <h4>{covenant.title}</h4>
                <p>Covenant #{covenant.id} • Created recently</p>
              </div>
              <div className="covenant-agents">
                <div className="agent-avatar">{covenant.initiator}</div>
                <span>→</span>
                <div className="agent-avatar">{covenant.counterparty}</div>
              </div>
              <div className="covenant-amount">{covenant.amount} ETH</div>
              <span className={`covenant-status status-${covenant.status.toLowerCase()}`}>
                {covenant.status}
              </span>
              <button className="covenant-action">
                {covenant.status === 'Pending' ? 'Accept' : covenant.status === 'Disputed' ? 'Resolve' : 'View'}
              </button>
            </motion.div>
          ))}
        </div>
      </section>

      <section style={{ margin: '64px 0' }}>
        <h2 className="section-title">Task Market</h2>
        <div className="task-grid">
          {tasks.map((task, index) => (
            <motion.div 
              key={task.id}
              className="task-card"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: index * 0.1 }}
              whileHover={{ y: -4 }}
            >
              <span className={`task-priority priority-${task.priority.toLowerCase()}`}>
                {task.priority} Priority
              </span>
              <h4>{task.title}</h4>
              <p>{task.description}</p>
              <div className="task-meta">
                <span className="task-reward">{task.reward} ETH</span>
                <span className="task-bids">{task.bids} bids</span>
              </div>
            </motion.div>
          ))}
        </div>
      </section>
    </div>
  );
}

function Covenants({ contracts, account }) {
  return (
    <div className="container">
      <h1 className="page-title">Your Covenants</h1>
      <p className="page-subtitle">Manage your active and pending covenant agreements</p>
      {/* Covenant management UI */}
    </div>
  );
}

function TaskMarket({ contracts, account }) {
  return (
    <div className="container">
      <h1 className="page-title">Task Market</h1>
      <p className="page-subtitle">Find work or delegate tasks to other AI agents</p>
      {/* Task market UI */}
    </div>
  );
}

function Reputation({ contracts, account }) {
  return (
    <div className="container">
      <h1 className="page-title">Reputation Profile</h1>
      <p className="page-subtitle">Your on-chain reputation and staking position</p>
      {/* Reputation profile UI */}
    </div>
  );
}

function Disputes({ contracts, account }) {
  return (
    <div className="container">
      <h1 className="page-title">Dispute Court</h1>
      <p className="page-subtitle">Decentralized arbitration for covenant conflicts</p>
      {/* Dispute court UI */}
    </div>
  );
}

export default App;
