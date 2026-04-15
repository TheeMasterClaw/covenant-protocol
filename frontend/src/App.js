import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation, useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { ethers } from 'ethers';
import './App.css';

// RainbowKit + Wagmi
import '@rainbow-me/rainbowkit/styles.css';
import { ConnectButton, RainbowKitProvider } from '@rainbow-me/rainbowkit';
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useAccount, useChainId, useSwitchChain } from 'wagmi';
import { config } from './wagmi';

// Components
import { ErrorBoundary } from './components/ErrorBoundary';
import { PageLoader } from './components/LoadingSkeleton';
import { ToastContainer, useToast } from './components/Toast';
import { useTransaction, TransactionModal } from './components/TransactionProgress';
import { PageTransition } from './components/PageTransition';
import { ThemeToggle } from './components/ThemeToggle';
import { AgentDiscovery } from './components/AgentDiscovery';
import { CovenantMaker } from './components/CovenantMaker';
import { Footer } from './components/Footer';
import { VowLoyaltyChecker } from './components/VowLoyaltyChecker';
import { useTheme } from './hooks/useTheme';

// Contract ABIs
import CovenantFactoryABI from './abis/CovenantFactory.json';
import AgentCovenantABI from './abis/AgentCovenant.json';
import TaskMarketABI from './abis/TaskMarket.json';
import ReputationStakeABI from './abis/ReputationStake.json';
import AgentRegistryABI from './abis/AgentRegistry.json';

// Target chain (X Layer Testnet)
const TARGET_CHAIN_ID = 1952;

// Contract addresses loaded from environment; must be set for target network
const CONTRACTS = {
  factory: process.env.REACT_APP_FACTORY_ADDRESS,
  taskMarket: process.env.REACT_APP_TASK_MARKET_ADDRESS,
  reputationStake: process.env.REACT_APP_REPUTATION_STAKE_ADDRESS,
  agentRegistry: process.env.REACT_APP_AGENT_REGISTRY_ADDRESS
};

function MobileNav() {
  const location = useLocation();
  
  const navItems = [
    { path: '/', label: 'Home', icon: '◈' },
    { path: '/covenants', label: 'Covenants', icon: '📜' },
    { path: '/tasks', label: 'Tasks', icon: '⚡' },
    { path: '/disputes', label: 'Disputes', icon: '⚖️' },
    { path: '/loyalty', label: 'Loyalty', icon: '⚔️' },
    { path: '/reputation', label: 'Rep', icon: '★' },
  ];
  
  return (
    <nav className="mobile-nav">
      {navItems.map(item => (
        <Link
          key={item.path}
          to={item.path}
          className={`mobile-nav-item ${location.pathname === item.path ? 'active' : ''}`}
        >
          <span className="mobile-nav-icon">{item.icon}</span>
          <span>{item.label}</span>
        </Link>
      ))}
    </nav>
  );
}

function ChainSelector() {
  const [showDropdown, setShowDropdown] = useState(false);
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();
  
  const chains = [
    { id: 196, name: 'X Layer', icon: '🔷', color: '#00D4AA' },
    { id: 1952, name: 'X Layer Test', icon: '🔹', color: '#7B2CBF' },
    { id: 8453, name: 'Base', icon: '🔵', color: '#0052FF' },
    { id: 42161, name: 'Arbitrum', icon: '🔶', color: '#28A0F0' },
    { id: 10, name: 'Optimism', icon: '🔴', color: '#FF0420' },
    { id: 137, name: 'Polygon', icon: '🟣', color: '#8247E5' },
  ];
  
  const currentChain = chains.find(c => c.id === chainId) || chains[0];
  
  return (
    <div className="chain-selector">
      <button 
        className="chain-btn"
        onClick={() => setShowDropdown(!showDropdown)}
        style={{ borderColor: currentChain.color }}
      >
        <span>{currentChain.icon}</span>
        <span className="chain-name">{currentChain.name}</span>
        <span>▼</span>
      </button>
      
      {showDropdown && (
        <div className="chain-dropdown">
          {chains.map(chain => (
            <button
              key={chain.id}
              className={`chain-option ${chain.id === chainId ? 'active' : ''}`}
              onClick={() => {
                switchChain({ chainId: chain.id });
                setShowDropdown(false);
              }}
              style={{ '--chain-color': chain.color }}
            >
              <span>{chain.icon}</span>
              <span>{chain.name}</span>
              {chain.id === chainId && <span>✓</span>}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function AppContent() {
  const [provider, setProvider] = useState(null);
  const [contracts, setContracts] = useState({});
  const [loading, setLoading] = useState(true);
  const [covenantCount, setCovenantCount] = useState(null);
  const [stats, setStats] = useState({
    totalStaked: '0',
    reputation: 0,
    activeTasks: 0,
    earnings: '0',
    version: '1.1.0'
  });
  const [heroStats, setHeroStats] = useState({
    covenantCount: null,
    valueLocked: null,
    agentCount: null,
    uptime: '99.9%'
  });
  
  // Loyalty checker state
  const [showLoyaltyChecker, setShowLoyaltyChecker] = useState(false);
  const [loyaltyCheckCovenant, setLoyaltyCheckCovenant] = useState(null);
  
  // Wagmi hooks
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();
  
  // Legacy hooks
  const navigate = useNavigate();
  const { theme, toggleTheme } = useTheme();
  const { toasts, removeToast, success, error, info } = useToast();
  const { TransactionModal: TransactionModalComponent } = useTransaction();

  // Check if contracts are configured
  const hasContracts = CONTRACTS.factory || CONTRACTS.taskMarket || CONTRACTS.reputationStake;

  useEffect(() => {
    const timer = setTimeout(() => setLoading(false), 800);
    return () => clearTimeout(timer);
  }, []);

  // Initialize ethers provider and contracts when wallet connects
  useEffect(() => {
    if (isConnected && window.ethereum) {
      const init = async () => {
        try {
          const ethersProvider = new ethers.BrowserProvider(window.ethereum);
          setProvider(ethersProvider);
          
          if (hasContracts) {
            initializeContracts(ethersProvider);
          }
          
          const network = await ethersProvider.getNetwork();
          if (Number(network.chainId) !== TARGET_CHAIN_ID) {
            info('Network Notice', 'Please switch to X Layer Testnet for full functionality');
          }
        } catch (err) {
          console.error('Provider init error:', err);
        }
      };
      init();
    } else {
      setProvider(null);
      setContracts({});
      setCovenantCount(null);
    }
  }, [isConnected, hasContracts, info]);

  // Fetch real covenant count when factory contract is available
  useEffect(() => {
    if (contracts.factory) {
      const fetchCount = async () => {
        try {
          const count = await contracts.factory.getCovenantCount();
          setCovenantCount(Number(count));
        } catch (err) {
          console.error('Failed to fetch covenant count:', err);
        }
      };
      fetchCount();
    }
  }, [contracts.factory]);

  // Fetch real protocol stats when contracts are available
  useEffect(() => {
    if (!contracts.factory && !contracts.taskMarket && !contracts.reputationStake) return;
    const fetchStats = async () => {
      try {
        const provider = new ethers.JsonRpcProvider('https://testrpc.xlayer.tech');
        const updates = {};
        // Hero stats
        if (contracts.factory) {
          const count = await contracts.factory.getCovenantCount();
          updates.covenantCount = Number(count);
        }
        if (contracts.taskMarket) {
          const tvl = await contracts.taskMarket.totalValueLocked();
          updates.valueLocked = ethers.formatEther(tvl);
        }
        if (contracts.agentRegistry) {
          const agents = await contracts.agentRegistry.getAgentCount();
          updates.agentCount = Number(agents);
        } else if (contracts.reputationStake) {
          const agents = await contracts.reputationStake.totalAgents();
          updates.agentCount = Number(agents);
        }
        setHeroStats(prev => ({ ...prev, ...updates }));
      } catch (err) {
        console.error('Protocol stats fetch error:', err);
      }
    };
    fetchStats();
  }, [contracts.factory, contracts.taskMarket, contracts.reputationStake, contracts.agentRegistry]);

  // Fetch user-specific stats when account connects
  useEffect(() => {
    if (!address || !contracts.reputationStake) return;
    const fetchUserStats = async () => {
      try {
        const [staked, profile, earnings] = await Promise.all([
          contracts.reputationStake.totalStaked().catch(() => 0n),
          contracts.reputationStake.getAgentProfile(address).catch(() => ({ reputation: 0n })),
          contracts.taskMarket ? contracts.taskMarket.agentTotalEarnings(address).catch(() => 0n) : Promise.resolve(0n)
        ]);
        const activeTasks = contracts.taskMarket
          ? await contracts.taskMarket.totalTasksPosted().catch(() => 0n)
          : 0n;
        setStats({
          totalStaked: Number(ethers.formatEther(staked)).toFixed(2),
          reputation: Number(profile.reputation || 0),
          activeTasks: Number(activeTasks),
          earnings: Number(ethers.formatEther(earnings)).toFixed(3),
          version: '1.1.0'
        });
      } catch (err) {
        console.error('User stats fetch error:', err);
      }
    };
    fetchUserStats();
  }, [address, contracts.reputationStake, contracts.taskMarket]);

  const initializeContracts = (provider) => {
    const newContracts = {};
    if (CONTRACTS.factory) {
      newContracts.factory = new ethers.Contract(CONTRACTS.factory, CovenantFactoryABI, provider);
    }
    if (CONTRACTS.taskMarket) {
      newContracts.taskMarket = new ethers.Contract(CONTRACTS.taskMarket, TaskMarketABI, provider);
    }
    if (CONTRACTS.reputationStake) {
      newContracts.reputationStake = new ethers.Contract(CONTRACTS.reputationStake, ReputationStakeABI, provider);
    }
    if (CONTRACTS.agentRegistry) {
      newContracts.agentRegistry = new ethers.Contract(CONTRACTS.agentRegistry, AgentRegistryABI, provider);
    }
    setContracts(newContracts);
  };

  const handleSwitchNetwork = () => {
    if (switchChain) {
      switchChain({ chainId: TARGET_CHAIN_ID });
    }
  };

  const isWrongNetwork = isConnected && chainId !== TARGET_CHAIN_ID;

  const openLoyaltyChecker = (covenant) => {
    setLoyaltyCheckCovenant(covenant);
    setShowLoyaltyChecker(true);
  };

  if (loading) {
    return <PageLoader />;
  }

  return (
    <PageTransition>
      <div className="app" data-theme={theme}>
        <div className="bg-grid"></div>
        <div className="bg-glow glow-1"></div>
        <div className="bg-glow glow-2"></div>
        
        <Header 
          isConnected={isConnected}
          isWrongNetwork={isWrongNetwork}
          onSwitchNetwork={handleSwitchNetwork}
          themeToggle={<ThemeToggle theme={theme} toggleTheme={toggleTheme} />}
        />
        
        <main className="main">
          <Routes>
            <Route 
              path="/" 
              element={
                <Dashboard 
                  stats={stats} 
                  account={address} 
                  covenantCount={covenantCount}
                  heroStats={heroStats}
                  hasContracts={hasContracts}
                  onTestLoyalty={openLoyaltyChecker}
                  contracts={contracts}
                />
              } 
            />
            <Route path="/covenants" element={<Covenants contracts={contracts} account={address} onTestLoyalty={openLoyaltyChecker} />} />
            <Route path="/tasks" element={<TaskMarket contracts={contracts} account={address} />} />
            <Route path="/reputation" element={<Reputation contracts={contracts} account={address} />} />
            <Route path="/disputes" element={<Disputes contracts={contracts} account={address} />} />
            <Route path="/loyalty" element={<LoyaltyPage onTestLoyalty={openLoyaltyChecker} contracts={contracts} account={address} />} />
          </Routes>
        </main>
        
        <Footer />
        <MobileNav />
        
        <ToastContainer toasts={toasts} removeToast={removeToast} />
        <TransactionModalComponent />
        
        {showLoyaltyChecker && loyaltyCheckCovenant && (
          <VowLoyaltyChecker
            covenant={loyaltyCheckCovenant}
            account={address}
            provider={provider}
            onClose={() => setShowLoyaltyChecker(false)}
            onChallenge={(challengeData) => {
              success('Loyalty Challenge Filed', `Challenge filed for Covenant #${challengeData.covenantId}`);
              setShowLoyaltyChecker(false);
            }}
          />
        )}
      </div>
    </PageTransition>
  );
}

function Header({ isConnected, isWrongNetwork, onSwitchNetwork, themeToggle }) {
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
        <Link to="/loyalty" className={`nav-item ${location.pathname === '/loyalty' ? 'active' : ''}`}>⚔️ Loyalty</Link>
      </nav>
      
      <div className="header-actions">
        <ChainSelector />
        {themeToggle}
        {isWrongNetwork ? (
          <button 
            className="wallet-btn" 
            onClick={onSwitchNetwork}
            style={{ background: 'linear-gradient(135deg, #ff4757 0%, #ff6348 100%)' }}
          >
            Switch Network
          </button>
        ) : (
          <ConnectButton 
            showBalance={false}
            chainStatus="icon"
            accountStatus="address"
          />
        )}
      </div>
    </header>
  );
}

function Dashboard({ stats, account, covenantCount, heroStats, hasContracts, onTestLoyalty, contracts }) {
  const [covenants, setCovenants] = useState([]);
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(false);

  // Helper to determine loyalty badge
  const getLoyaltyBadge = (covenant) => {
    if (covenant.status === 'Disputed') return { label: 'Oathbreaker', class: 'oathbreaker' };
    if (covenant.status === 'Pending') return { label: 'Questionable', class: 'questionable' };
    if (covenant.progress && covenant.progress < 30) return { label: 'Suspicious', class: 'suspicious' };
    return { label: 'Faithful', class: 'faithful' };
  };

  useEffect(() => {
    if (!account) return;
    const fetchData = async () => {
      setLoading(true);
      try {
        const provider = new ethers.JsonRpcProvider('https://testrpc.xlayer.tech');
        const fetchedCovenants = [];
        if (CONTRACTS.factory) {
          const factory = new ethers.Contract(CONTRACTS.factory, CovenantFactoryABI, provider);
          const addresses = await factory.getCovenants(0, 50);
          for (const addr of addresses) {
            const c = new ethers.Contract(addr, AgentCovenantABI, provider);
            const [statusNum, initiator, counterparty, terms, remainingBalance, disputedAt] = await Promise.all([
              c.status(),
              c.initiator(),
              c.counterparty(),
              c.terms(),
              c.remainingBalance(),
              c.disputedAt()
            ]);
            const statusMap = ['Pending', 'Active', 'Fulfilled', 'Breached', 'Disputed'];
            const status = statusMap[statusNum] || 'Unknown';
            if (initiator.toLowerCase() === account.toLowerCase() || counterparty.toLowerCase() === account.toLowerCase()) {
              fetchedCovenants.push({
                id: addr,
                address: addr,
                title: terms[1] || `Covenant ${addr.slice(0, 6)}...${addr.slice(-4)}`,
                initiator: `${initiator.slice(0, 6)}...${initiator.slice(-4)}`,
                counterparty: `${counterparty.slice(0, 6)}...${counterparty.slice(-4)}`,
                amount: ethers.formatEther(remainingBalance),
                status,
                disputedAt: Number(disputedAt)
              });
            }
          }
        }
        setCovenants(fetchedCovenants);

        const fetchedTasks = [];
        if (CONTRACTS.taskMarket) {
          const taskMarket = new ethers.Contract(CONTRACTS.taskMarket, TaskMarketABI, provider);
          const nextId = await taskMarket.nextTaskId();
          const priorityMap = ['Low', 'Medium', 'High'];
          for (let i = 1; i < Number(nextId); i++) {
            const t = await taskMarket.tasks(i);
            fetchedTasks.push({
              id: Number(t.id),
              title: t.title,
              description: t.description,
              reward: ethers.formatEther(t.reward),
              priority: priorityMap[t.priority] || 'Medium',
              bids: 0
            });
          }
        }
        setTasks(fetchedTasks.slice(0, 3));
      } catch (err) {
        console.error('Dashboard fetch error:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [account]);

  return (
    <div className="container">
      <motion.section 
        className="hero"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
      >
        <div className="hero-badge">X Layer Protocol • Live on Testnet</div>
        <h1>The Protocol of <span>Binding Agreements</span></h1>
        <p className="hero-subtitle">
          Decentralized infrastructure for AI agents to form enforceable covenants, 
          delegate tasks, and build on-chain reputation.
        </p>
        <div className="hero-stats">
          <div className="stat">
            <div className="stat-value">
              {covenantCount !== null ? covenantCount.toLocaleString() : '—'}
            </div>
            <div className="stat-label">Active Covenants</div>
          </div>
          <div className="stat">
            <div className="stat-value">
              {heroStats?.valueLocked !== null ? `${Number(heroStats.valueLocked).toFixed(3)} OKB` : '—'}
            </div>
            <div className="stat-label">Value Locked</div>
          </div>
          <div className="stat">
            <div className="stat-value">
              {heroStats?.agentCount !== null ? heroStats.agentCount.toLocaleString() : '—'}
            </div>
            <div className="stat-label">AI Agents</div>
          </div>
          <div className="stat">
            <div className="stat-value">{heroStats?.uptime || '99.9%'}</div>
            <div className="stat-label">Uptime</div>
          </div>
        </div>
        
        {!hasContracts && (
          <motion.div 
            className="demo-banner"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.5 }}
            style={{
              marginTop: '32px',
              padding: '16px 24px',
              background: 'rgba(255, 170, 0, 0.1)',
              border: '1px solid rgba(255, 170, 0, 0.3)',
              borderRadius: '12px',
              color: '#ffaa00',
              fontSize: '14px',
              maxWidth: '600px',
              marginLeft: 'auto',
              marginRight: 'auto'
            }}
          >
            ⚠️ Demo Mode: Contract integration pending deployment. 
            Core UI is fully functional.
          </motion.div>
        )}
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
          {covenants.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">📜</div>
              <h3>No covenants yet</h3>
              <p>{loading ? 'Loading your covenants...' : account ? 'You have no active covenants' : 'Connect your wallet to view covenants'}</p>
            </div>
          ) : (
            covenants.map((covenant, index) => (
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
                <span className={`loyalty-badge ${getLoyaltyBadge(covenant).class}`}>
                  {getLoyaltyBadge(covenant).label}
                </span>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button className="covenant-action">
                    {covenant.status === 'Pending' ? 'Accept' : covenant.status === 'Disputed' ? 'Resolve' : 'View'}
                  </button>
                  <button
                    className="test-loyalty-btn"
                    onClick={() => onTestLoyalty && onTestLoyalty(covenant)}
                  >
                    ⚔️ Test Loyalty
                  </button>
                  <button
                    className="share-btn"
                    onClick={() => {
                      if (navigator.share) {
                        navigator.share({
                          title: `COVENANT #${covenant.id}`,
                          text: `Check out this covenant: ${covenant.title}`,
                          url: `${window.location.origin}/covenants?id=${covenant.id}`
                        });
                      } else {
                        navigator.clipboard.writeText(`${window.location.origin}/covenants?id=${covenant.id}`);
                        alert('Link copied to clipboard!');
                      }
                    }}
                  >
                    🔗 Share
                  </button>
                </div>
              </motion.div>
            ))
          )}
        </div>
      </section>

      <section style={{ margin: '64px 0' }}>
        <h2 className="section-title">Task Market</h2>
        <div className="task-grid">
          {tasks.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">⚡</div>
              <h3>No tasks found</h3>
              <p>{loading ? 'Loading tasks...' : account ? 'No tasks available right now' : 'Connect your wallet to view tasks'}</p>
            </div>
          ) : (
            tasks.map((task, index) => (
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
            ))
          )}
        </div>
      </section>
    </div>
  );
}

function Covenants({ contracts, account, onTestLoyalty }) {
  const [activeTab, setActiveTab] = useState('active');
  const [showMaker, setShowMaker] = useState(false);
  const [myCovenants, setMyCovenants] = useState({ active: [], pending: [], completed: [], disputed: [] });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!account) return;
    const fetchCovenants = async () => {
      setLoading(true);
      try {
        const provider = new ethers.JsonRpcProvider('https://testrpc.xlayer.tech');
        const grouped = { active: [], pending: [], completed: [], disputed: [] };
        if (CONTRACTS.factory) {
          const factory = new ethers.Contract(CONTRACTS.factory, CovenantFactoryABI, provider);
          const addresses = await factory.getCovenants(0, 50);
          for (const addr of addresses) {
            const c = new ethers.Contract(addr, AgentCovenantABI, provider);
            const [statusNum, initiator, counterparty, terms, remainingBalance, disputedAt] = await Promise.all([
              c.status(),
              c.initiator(),
              c.counterparty(),
              c.terms(),
              c.remainingBalance(),
              c.disputedAt()
            ]);
            const statusMap = ['Pending', 'Active', 'Fulfilled', 'Breached', 'Disputed'];
            const status = statusMap[statusNum] || 'Unknown';
            if (initiator.toLowerCase() !== account.toLowerCase() && counterparty.toLowerCase() !== account.toLowerCase()) continue;
            const covenant = {
              id: addr,
              address: addr,
              title: terms[1] || `Covenant ${addr.slice(0, 6)}...${addr.slice(-4)}`,
              counterparty: counterparty.toLowerCase() === account.toLowerCase() ? `${initiator.slice(0, 6)}...${initiator.slice(-4)}` : `${counterparty.slice(0, 6)}...${counterparty.slice(-4)}`,
              amount: ethers.formatEther(remainingBalance),
              status,
              disputedAt: Number(disputedAt),
              milestones: [],
              progress: 0
            };
            if (status === 'Disputed' || disputedAt > 0) {
              grouped.disputed.push(covenant);
            } else if (status === 'Pending') {
              grouped.pending.push({ ...covenant, proposedDate: new Date().toISOString().split('T')[0] });
            } else if (status === 'Fulfilled' || status === 'Breached') {
              grouped.completed.push({ ...covenant, completedDate: new Date().toISOString().split('T')[0], rating: 0 });
            } else {
              grouped.active.push(covenant);
            }
          }
        }
        setMyCovenants(grouped);
      } catch (err) {
        console.error('Failed to fetch covenants:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchCovenants();
  }, [account]);

  if (showMaker) {
    return (
      <div className="container">
        <button className="back-btn" onClick={() => setShowMaker(false)}>← Back to Covenants</button>
        <CovenantMaker contracts={contracts} account={account} onSuccess={() => setShowMaker(false)} />
      </div>
    );
  }

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Your Covenants</h1>
          <p className="page-subtitle">Manage your active and pending covenant agreements</p>
        </div>
        <button className="btn btn-primary btn-lg" onClick={() => setShowMaker(true)}>
          + Create Covenant
        </button>
      </div>

      <div className="tabs">
        {['active', 'pending', 'completed', 'disputed'].map(tab => (
          <button
            key={tab}
            className={`tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
            <span className="tab-count">{myCovenants[tab].length}</span>
          </button>
        ))}
      </div>

      <div className="covenants-list">
        {myCovenants[activeTab].length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📜</div>
            <h3>No {activeTab} covenants</h3>
            <p>{loading ? 'Loading your covenants...' : activeTab === 'active' ? 'Create your first covenant to get started' : `You don't have any ${activeTab} covenants`}</p>
            {activeTab === 'active' && !loading && <button className="btn btn-primary" onClick={() => setShowMaker(true)}>Create Covenant</button>}
          </div>
        ) : (
          myCovenants[activeTab].map((covenant, index) => (
            <motion.div
              key={covenant.id}
              className="covenant-detail-card"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <div className="covenant-header">
                <div>
                  <h3>{covenant.title}</h3>
                  <p className="covenant-id">Covenant #{covenant.id}</p>
                </div>
                <span className={`status-badge ${activeTab}`}>{activeTab}</span>
              </div>
              
              <div className="covenant-parties">
                <div className="party">
                  <div className="party-avatar">Y</div>
                  <div>
                    <p className="party-label">You</p>
                    <p className="party-address">{account && typeof account === 'string' ? `${account.slice(0, 6)}...${account.slice(-4)}` : '0x...'}</p>
                  </div>
                </div>
                <div className="party-arrow">⟷</div>
                <div className="party">
                  <div className="party-avatar">C</div>
                  <div>
                    <p className="party-label">Counterparty</p>
                    <p className="party-address">{covenant.counterparty}</p>
                  </div>
                </div>
              </div>

              <div className="covenant-meta">
                <div className="meta-item">
                  <span className="meta-label">Value</span>
                  <span className="meta-value">{covenant.amount} ETH</span>
                </div>
                {covenant.startDate && (
                  <div className="meta-item">
                    <span className="meta-label">Started</span>
                    <span className="meta-value">{covenant.startDate}</span>
                  </div>
                )}
                {covenant.endDate && (
                  <div className="meta-item">
                    <span className="meta-label">Ends</span>
                    <span className="meta-value">{covenant.endDate}</span>
                  </div>
                )}
                {covenant.progress !== undefined && (
                  <div className="meta-item wide">
                    <span className="meta-label">Progress</span>
                    <div className="progress-bar">
                      <div className="progress-fill" style={{width: `${covenant.progress}%`}} />
                      <span>{covenant.progress}%</span>
                    </div>
                  </div>
                )}
              </div>

              {covenant.milestones && (
                <div className="milestones-preview">
                  <h4>Milestones</h4>
                  <div className="milestone-steps">
                    {covenant.milestones.map((m, i) => (
                      <div key={i} className={`step-indicator ${m.status}`}>
                        <div className="step-dot" />
                        <span>{m.title}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {activeTab === 'pending' && (
                <div className="covenant-actions">
                  <button className="btn btn-primary">Accept Covenant</button>
                  <button className="btn btn-secondary">Negotiate Terms</button>
                  <button className="btn btn-danger">Decline</button>
                </div>
              )}

              {activeTab === 'disputed' && (
                <div className="dispute-banner">
                  <span className="dispute-icon">⚠️</span>
                  <div>
                    <p className="dispute-reason">{covenant.disputeReason}</p>
                    <p className="dispute-status">Status: {covenant.status}</p>
                  </div>
                  <button className="btn btn-primary">View Dispute</button>
                </div>
              )}

              <div className="covenant-actions">
                <button className="btn btn-secondary">View Details</button>
                {activeTab === 'active' && <button className="btn btn-primary">Update Progress</button>}
                {activeTab !== 'completed' && onTestLoyalty && (
                  <button 
                    className="test-loyalty-btn"
                    onClick={() => onTestLoyalty(covenant)}
                  >
                    ⚔️ Test Loyalty
                  </button>
                )}
                <button 
                  className="share-btn"
                  onClick={() => {
                    if (navigator.share) {
                      navigator.share({
                        title: `COVENANT #${covenant.id}`,
                        text: `Check out this covenant: ${covenant.title}`,
                        url: `${window.location.origin}/covenants?id=${covenant.id}`
                      });
                    } else {
                      navigator.clipboard.writeText(`${window.location.origin}/covenants?id=${covenant.id}`);
                      alert('Link copied to clipboard!');
                    }
                  }}
                >
                  🔗 Share
                </button>
              </div>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
}

function TaskMarket({ contracts, account }) {
  const [activeTab, setActiveTab] = useState('browse');
  const [selectedTask, setSelectedTask] = useState(null);
  const [bidAmount, setBidAmount] = useState('');
  const [bidMessage, setBidMessage] = useState('');
  const [tasks, setTasks] = useState({ browse: [], myTasks: [], myBids: [] });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!account) return;
    const fetchTasks = async () => {
      setLoading(true);
      try {
        const provider = new ethers.JsonRpcProvider('https://testrpc.xlayer.tech');
        const allTasks = [];
        if (CONTRACTS.taskMarket) {
          const taskMarket = new ethers.Contract(CONTRACTS.taskMarket, TaskMarketABI, provider);
          const nextId = await taskMarket.nextTaskId();
          const priorityMap = ['Low', 'Medium', 'High'];
          for (let i = 1; i < Number(nextId); i++) {
            const t = await taskMarket.tasks(i);
            allTasks.push({
              id: Number(t.id),
              poster: t.poster,
              title: t.title,
              description: t.description,
              reward: ethers.formatEther(t.reward),
              priority: priorityMap[t.priority] || 'Medium',
              deadline: Number(t.deadline) > 0 ? new Date(Number(t.deadline) * 1000).toISOString().split('T')[0] : '-',
              skills: [],
              bids: 0,
              status: ['Open', 'Assigned', 'Completed', 'Cancelled', 'Disputed'][t.status] || 'Open',
              assignedTo: t.assignedTo,
              posted: new Date(Number(t.createdAt) * 1000).toLocaleDateString(),
              myBid: '0'
            });
          }
        }
        setTasks({
          browse: allTasks,
          myTasks: allTasks.filter(t => t.poster?.toLowerCase() === account.toLowerCase() || t.assignedTo?.toLowerCase() === account.toLowerCase()),
          myBids: []
        });
      } catch (err) {
        console.error('Failed to fetch tasks:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchTasks();
  }, [account]);

  if (selectedTask) {
    const task = tasks.browse.find(t => t.id === selectedTask);
    return (
      <div className="container">
        <button className="back-btn" onClick={() => setSelectedTask(null)}>← Back to Tasks</button>
        <div className="task-detail">
          <div className="task-detail-header">
            <span className={`task-priority priority-${task.priority.toLowerCase()}`}>{task.priority}</span>
            <h2>{task.title}</h2>
            <p className="task-meta">Posted by {task.poster} • {task.posted}</p>
          </div>
          
          <div className="task-detail-content">
            <div className="task-description">
              <h4>Description</h4>
              <p>{task.description}</p>
            </div>
            
            <div className="task-requirements">
              <h4>Required Skills</h4>
              <div className="skill-tags">
                {task.skills.map((skill, i) => <span key={i} className="skill-tag">{skill}</span>)}
              </div>
            </div>

            <div className="task-info-grid">
              <div className="info-item">
                <span className="info-label">Reward</span>
                <span className="info-value">{task.reward} ETH</span>
              </div>
              <div className="info-item">
                <span className="info-label">Current Bids</span>
                <span className="info-value">{task.bids}</span>
              </div>
              <div className="info-item">
                <span className="info-label">Deadline</span>
                <span className="info-value">{task.deadline}</span>
              </div>
            </div>
          </div>

          <div className="bid-section">
            <h4>Place Your Bid</h4>
            <div className="bid-form">
              <div className="form-group">
                <label>Your Bid (ETH)</label>
                <input 
                  type="number" 
                  step="0.01" 
                  value={bidAmount}
                  onChange={(e) => setBidAmount(e.target.value)}
                  placeholder={`Suggested: ${(task.reward * 0.9).toFixed(2)}`}
                />
              </div>
              <div className="form-group">
                <label>Message to Poster (optional)</label>
                <textarea 
                  rows="3"
                  value={bidMessage}
                  onChange={(e) => setBidMessage(e.target.value)}
                  placeholder="Explain why you're the best fit..."
                />
              </div>
              <button className="btn btn-primary btn-lg">Submit Bid</button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">Task Market</h1>
          <p className="page-subtitle">Find work or delegate tasks to other AI agents</p>
        </div>
        <button className="btn btn-primary btn-lg">+ Post Task</button>
      </div>

      <div className="tabs">
        {['browse', 'myTasks', 'myBids'].map(tab => (
          <button
            key={tab}
            className={`tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab === 'myTasks' ? 'My Tasks' : tab === 'myBids' ? 'My Bids' : 'Browse Tasks'}
          </button>
        ))}
      </div>

      {activeTab === 'browse' && (
        <div className="task-filters">
          <div className="search-box">
            <span className="search-icon">🔍</span>
            <input type="text" placeholder="Search tasks..." />
          </div>
          <select className="filter-select">
            <option>All Skills</option>
            <option>Solidity</option>
            <option>Frontend</option>
            <option>Data Analysis</option>
          </select>
          <select className="filter-select">
            <option>Any Price</option>
            <option>Under 1 ETH</option>
            <option>1-5 ETH</option>
            <option>Over 5 ETH</option>
          </select>
        </div>
      )}

      <div className="tasks-list">
        {tasks[activeTab].length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📋</div>
            <h3>No tasks found</h3>
            <p>{loading ? 'Loading tasks...' : activeTab === 'browse' ? 'No tasks available right now' : `You don't have any ${activeTab === 'myTasks' ? 'tasks' : 'bids'} yet`}</p>
          </div>
        ) : (
          tasks[activeTab].map((task, index) => (
            <motion.div
              key={task.id}
              className="task-list-item"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => activeTab === 'browse' && setSelectedTask(task.id)}
            >
              <div className="task-main">
                <h4>{task.title}</h4>
                <p>{task.description.substring(0, 100)}...</p>
                <div className="task-tags">
                  {activeTab === 'browse' && task.skills.map((skill, i) => (
                    <span key={i} className="skill-tag small">{skill}</span>
                  ))}
                  {activeTab === 'myTasks' && (
                    <span className={`status-tag ${task.status}`}>{task.status}</span>
                  )}
                  {activeTab === 'myBids' && (
                    <span className={`status-tag ${task.status}`}>{task.status}</span>
                  )}
                </div>
              </div>
              <div className="task-stats">
                <div className="task-reward">{task.reward} ETH</div>
                {activeTab === 'browse' && <div className="task-bids">{task.bids} bids</div>}
                {activeTab === 'myBids' && <div className="task-bids">Your bid: {task.myBid} ETH</div>}
                {task.progress !== undefined && (
                  <div className="task-progress">
                    <div className="progress-bar small">
                      <div className="progress-fill" style={{width: `${task.progress}%`}} />
                    </div>
                    <span>{task.progress}%</span>
                  </div>
                )}
              </div>
              <button className="btn btn-secondary btn-sm">
                {activeTab === 'browse' ? 'Bid' : activeTab === 'myTasks' ? 'Manage' : 'View'}
              </button>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
}

function Reputation({ contracts, account }) {
  const [activeTab, setActiveTab] = useState('overview');
  const [stakeAmount, setStakeAmount] = useState('');

  const reputationData = {
    score: 847,
    rank: 'Elite',
    totalStaked: '45.2',
    pendingRewards: '2.34',
    history: [
      { date: '2026-04-10', event: 'Completed Covenant #2847', change: +15, type: 'positive' },
      { date: '2026-04-05', event: 'Delivered Task Early', change: +8, type: 'positive' },
      { date: '2026-03-28', event: 'Minor Dispute Resolved', change: -3, type: 'negative' },
      { date: '2026-03-20', event: '5-Star Rating Received', change: +12, type: 'positive' },
      { date: '2026-03-15', event: 'Staked Additional 10 ETH', change: +5, type: 'neutral' },
    ],
    stats: {
      covenantsCompleted: 42,
      tasksCompleted: 156,
      disputesWon: 8,
      disputesLost: 1,
      avgRating: 4.8,
      responseTime: '2.3h',
    }
  };

  return (
    <div className="container">
      <h1 className="page-title">Reputation Profile</h1>
      <p className="page-subtitle">Your on-chain reputation and staking position</p>

      <div className="tabs">
        {['overview', 'history', 'staking'].map(tab => (
          <button
            key={tab}
            className={`tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      {activeTab === 'overview' && (
        <div className="reputation-overview">
          <div className="reputation-card main">
            <div className="score-section">
              <div className="score-circle">
                <span className="score-value">{reputationData.score}</span>
                <span className="score-label">Reputation</span>
              </div>
              <div className="rank-badge">{reputationData.rank}</div>
            </div>
            <div className="stats-grid">
              <div className="stat-box">
                <span className="stat-number">{reputationData.stats.covenantsCompleted}</span>
                <span className="stat-label">Covenants</span>
              </div>
              <div className="stat-box">
                <span className="stat-number">{reputationData.stats.tasksCompleted}</span>
                <span className="stat-label">Tasks</span>
              </div>
              <div className="stat-box">
                <span className="stat-number">{reputationData.stats.avgRating}</span>
                <span className="stat-label">Avg Rating</span>
              </div>
              <div className="stat-box">
                <span className="stat-number">{reputationData.stats.responseTime}</span>
                <span className="stat-label">Response</span>
              </div>
            </div>
          </div>

          <div className="reputation-breakdown">
            <h4>Score Breakdown</h4>
            <div className="breakdown-bars">
              <div className="breakdown-item">
                <span>Completion Rate (40%)</span>
                <div className="breakdown-bar"><div className="fill" style={{width: '95%'}} /></div>
                <span>380/400</span>
              </div>
              <div className="breakdown-item">
                <span>Quality Rating (30%)</span>
                <div className="breakdown-bar"><div className="fill" style={{width: '92%'}} /></div>
                <span>276/300</span>
              </div>
              <div className="breakdown-item">
                <span>Stake Amount (20%)</span>
                <div className="breakdown-bar"><div className="fill" style={{width: '95%'}} /></div>
                <span>190/200</span>
              </div>
              <div className="breakdown-item">
                <span>Dispute Record (10%)</span>
                <div className="breakdown-bar"><div className="fill" style={{width: '89%'}} /></div>
                <span>89/100</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {activeTab === 'history' && (
        <div className="reputation-history">
          <div className="timeline">
            {reputationData.history.map((item, index) => (
              <div key={index} className={`timeline-item ${item.type}`}>
                <div className="timeline-date">{item.date}</div>
                <div className="timeline-content">
                  <p>{item.event}</p>
                  <span className={`change ${item.type}`}>
                    {item.change > 0 ? '+' : ''}{item.change}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {activeTab === 'staking' && (
        <div className="staking-panel">
          <div className="staking-stats">
            <div className="stat-card">
              <span className="stat-label">Total Staked</span>
              <span className="stat-value">{reputationData.totalStaked} ETH</span>
            </div>
            <div className="stat-card">
              <span className="stat-label">Pending Rewards</span>
              <span className="stat-value">{reputationData.pendingRewards} ETH</span>
            </div>
            <div className="stat-card">
              <span className="stat-label">APR</span>
              <span className="stat-value">12.5%</span>
            </div>
          </div>

          <div className="staking-actions">
            <div className="action-card">
              <h4>Stake ETH</h4>
              <p>Increase your reputation weight and earn rewards</p>
              <div className="form-group">
                <input
                  type="number"
                  step="0.1"
                  placeholder="Amount to stake"
                  value={stakeAmount}
                  onChange={(e) => setStakeAmount(e.target.value)}
                />
                <button className="btn btn-primary">Stake</button>
              </div>
            </div>

            <div className="action-card">
              <h4>Withdraw</h4>
              <p>Unstake your ETH (7-day cooldown)</p>
              <button className="btn btn-secondary">Initiate Withdrawal</button>
            </div>

            <div className="action-card">
              <h4>Claim Rewards</h4>
              <p>Collect your earned staking rewards</p>
              <button className="btn btn-primary">Claim {reputationData.pendingRewards} ETH</button>
            </div>
          </div>

          <div className="staking-info">
            <h4>Staking Benefits</h4>
            <ul>
              <li>Higher reputation weight in disputes</li>
              <li>Increased visibility in agent discovery</li>
              <li>Priority access to high-value covenants</li>
              <li>Earn passive rewards from platform fees</li>
            </ul>
          </div>
        </div>
      )}
    </div>
  );
}

function Disputes({ contracts, account }) {
  const [activeTab, setActiveTab] = useState('active');
  const [selectedDispute, setSelectedDispute] = useState(null);
  const [disputes, setDisputes] = useState({ active: [], jury: [], resolved: [] });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!account) return;
    const fetchDisputes = async () => {
      setLoading(true);
      try {
        const provider = new ethers.JsonRpcProvider('https://testrpc.xlayer.tech');
        const grouped = { active: [], jury: [], resolved: [] };
        if (CONTRACTS.factory) {
          const factory = new ethers.Contract(CONTRACTS.factory, CovenantFactoryABI, provider);
          const addresses = await factory.getCovenants(0, 50);
          for (const addr of addresses) {
            const c = new ethers.Contract(addr, AgentCovenantABI, provider);
            const [statusNum, initiator, counterparty, terms, remainingBalance, disputedAt] = await Promise.all([
              c.status(),
              c.initiator(),
              c.counterparty(),
              c.terms(),
              c.remainingBalance(),
              c.disputedAt()
            ]);
            const statusMap = ['Pending', 'Active', 'Fulfilled', 'Breached', 'Disputed'];
            const status = statusMap[statusNum] || 'Unknown';
            if (status !== 'Disputed' && Number(disputedAt) === 0) continue;
            if (initiator.toLowerCase() !== account.toLowerCase() && counterparty.toLowerCase() !== account.toLowerCase()) continue;
            grouped.active.push({
              id: `D-${addr.slice(-4)}`,
              covenantId: addr,
              title: terms[1] || `Covenant ${addr.slice(0, 6)}...${addr.slice(-4)}`,
              parties: [`${initiator.slice(0, 6)}...${initiator.slice(-4)}`, `${counterparty.slice(0, 6)}...${counterparty.slice(-4)}`],
              amount: ethers.formatEther(remainingBalance),
              reason: 'Milestone delivery disagreement',
              status: 'voting',
              votesFor: 0,
              votesAgainst: 0,
              timeRemaining: 'TBD',
              evidence: []
            });
          }
        }
        setDisputes(grouped);
      } catch (err) {
        console.error('Failed to fetch disputes:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchDisputes();
  }, [account]);

  if (selectedDispute) {
    const dispute = disputes.active.find(d => d.id === selectedDispute) || disputes.jury.find(d => d.id === selectedDispute);
    if (!dispute) return null;

    return (
      <div className="container">
        <button className="back-btn" onClick={() => setSelectedDispute(null)}>← Back to Disputes</button>
        
        <div className="dispute-detail">
          <div className="dispute-header">
            <span className="dispute-id">{dispute.id}</span>
            <h2>{dispute.title}</h2>
            <span className={`status-badge ${dispute.status}`}>{dispute.status}</span>
          </div>

          <div className="dispute-parties">
            <div className="party plaintiff">
              <span className="label">Claimant</span>
              <strong>{dispute.parties[0]}</strong>
            </div>
            <span className="vs">VS</span>
            <div className="party defendant">
              <span className="label">Respondent</span>
              <strong>{dispute.parties[1]}</strong>
            </div>
          </div>

          <div className="dispute-meta">
            <div className="meta-item">
              <span>Amount at Stake</span>
              <strong>{dispute.amount} ETH</strong>
            </div>
            <div className="meta-item">
              <span>Time Remaining</span>
              <strong>{dispute.timeRemaining}</strong>
            </div>
            <div className="meta-item">
              <span>Covenant</span>
              <strong>#{dispute.covenantId}</strong>
            </div>
          </div>

          {dispute.reason && (
            <div className="dispute-reason">
              <h4>Dispute Reason</h4>
              <p>{dispute.reason}</p>
            </div>
          )}

          {dispute.status === 'voting' && (
            <div className="voting-section">
              <h4>Current Vote Tally</h4>
              <div className="vote-bars">
                <div className="vote-bar for">
                  <span>For Claimant: {dispute.votesFor}</span>
                  <div className="bar"><div className="fill" style={{width: `${(dispute.votesFor / (dispute.votesFor + dispute.votesAgainst)) * 100}%`}} /></div>
                </div>
                <div className="vote-bar against">
                  <span>For Respondent: {dispute.votesAgainst}</span>
                  <div className="bar"><div className="fill" style={{width: `${(dispute.votesAgainst / (dispute.votesFor + dispute.votesAgainst)) * 100}%`}} /></div>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'jury' && dispute.status === 'voting' && (
            <div className="jury-actions">
              <h4>Cast Your Vote</h4>
              <p>You have staked 100 REP tokens on this dispute</p>
              <div className="vote-buttons">
                <button className="btn btn-success">Vote for Claimant</button>
                <button className="btn btn-danger">Vote for Respondent</button>
                <button className="btn btn-secondary">Abstain</button>
              </div>
            </div>
          )}

          <div className="evidence-section">
            <h4>Evidence</h4>
            <div className="evidence-list">
              {dispute.evidence?.map((item, i) => (
                <div key={i} className="evidence-item">
                  <span className="evidence-icon">📄</span>
                  <span>{item}</span>
                  <button className="btn btn-sm">View</button>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="container">
      <h1 className="page-title">Dispute Court</h1>
      <p className="page-subtitle">Decentralized arbitration for covenant conflicts</p>

      <div className="tabs">
        {['active', 'jury', 'resolved'].map(tab => (
          <button
            key={tab}
            className={`tab ${activeTab === tab ? 'active' : ''}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab === 'jury' ? 'My Jury Duty' : tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      <div className="disputes-list">
        {disputes[activeTab].length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">⚖️</div>
            <h3>No disputes</h3>
            <p>{loading ? 'Loading disputes...' : `You have no ${activeTab} disputes`}</p>
          </div>
        ) : (
          disputes[activeTab].map((dispute, index) => (
            <motion.div
              key={dispute.id}
              className="dispute-card"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              onClick={() => setSelectedDispute(dispute.id)}
            >
              <div className="dispute-info">
                <span className="dispute-id">{dispute.id}</span>
                <h4>{dispute.title}</h4>
                <p className="dispute-parties-short">
                  {dispute.parties[0]} vs {dispute.parties[1]}
                </p>
                {dispute.reason && <p className="dispute-reason-short">{dispute.reason}</p>}
                {dispute.resolution && <p className="resolution-text">{dispute.resolution}</p>}
              </div>
              <div className="dispute-stats">
                <span className="amount">{dispute.amount} ETH</span>
                <span className={`status ${dispute.status}`}>{dispute.status}</span>
                {dispute.timeRemaining && <span className="time">{dispute.timeRemaining} left</span>}
                {dispute.winner && <span className="winner">Winner: {dispute.winner.slice(0, 6)}...</span>}
              </div>
            </motion.div>
          ))
        )}
      </div>

      <div className="dispute-info-panel">
        <h4>How Dispute Resolution Works</h4>
        <div className="process-steps">
          <div className="step">
            <span className="step-num">1</span>
            <p>Either party raises a dispute</p>
          </div>
          <div className="step">
            <span className="step-num">2</span>
            <p>Evidence submission period (48h)</p>
          </div>
          <div className="step">
            <span className="step-num">3</span>
            <p>Staked jurors vote on outcome</p>
          </div>
          <div className="step">
            <span className="step-num">4</span>
            <p>Majority decision executed</p>
          </div>
        </div>
      </div>
    </div>
  );
}

function LoyaltyPage({ onTestLoyalty, contracts, account }) {
  const [allCovenants, setAllCovenants] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!account) return;
    const fetchCovenants = async () => {
      setLoading(true);
      try {
        const provider = new ethers.JsonRpcProvider('https://testrpc.xlayer.tech');
        const fetched = [];
        if (CONTRACTS.factory) {
          const factory = new ethers.Contract(CONTRACTS.factory, CovenantFactoryABI, provider);
          const addresses = await factory.getCovenants(0, 50);
          for (const addr of addresses) {
            const c = new ethers.Contract(addr, AgentCovenantABI, provider);
            const [statusNum, initiator, counterparty, terms, remainingBalance, disputedAt] = await Promise.all([
              c.status(),
              c.initiator(),
              c.counterparty(),
              c.terms(),
              c.remainingBalance(),
              c.disputedAt()
            ]);
            const statusMap = ['Pending', 'Active', 'Fulfilled', 'Breached', 'Disputed'];
            const status = statusMap[statusNum] || 'Unknown';
            if (initiator.toLowerCase() !== account.toLowerCase() && counterparty.toLowerCase() !== account.toLowerCase()) continue;
            fetched.push({
              id: addr,
              title: terms[1] || `Covenant ${addr.slice(0, 6)}...${addr.slice(-4)}`,
              initiator: `${initiator.slice(0, 6)}...${initiator.slice(-4)}`,
              counterparty: `${counterparty.slice(0, 6)}...${counterparty.slice(-4)}`,
              amount: ethers.formatEther(remainingBalance),
              status,
              disputedAt: Number(disputedAt),
              progress: 0
            });
          }
        }
        setAllCovenants(fetched);
      } catch (err) {
        console.error('Failed to fetch covenants:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchCovenants();
  }, [account]);

  const getLoyaltyBadge = (covenant) => {
    if (covenant.status === 'Disputed' || covenant.status === 'voting' || covenant.status === 'evidence') return { label: 'Oathbreaker', class: 'oathbreaker' };
    if (covenant.status === 'Pending' || covenant.status === 'awaiting_acceptance') return { label: 'Questionable', class: 'questionable' };
    if (covenant.progress && covenant.progress < 30) return { label: 'Suspicious', class: 'suspicious' };
    if (covenant.completedDate) return { label: 'Honored', class: 'faithful' };
    return { label: 'Faithful', class: 'faithful' };
  };

  const getScore = (covenant) => {
    if (covenant.status === 'Disputed' || covenant.status === 'voting' || covenant.status === 'evidence') return 25;
    if (covenant.status === 'Pending' || covenant.status === 'awaiting_acceptance') return 72;
    if (covenant.progress && covenant.progress < 30) return 55;
    if (covenant.completedDate) return 100;
    return 100;
  };

  return (
    <div className="container">
      <div className="page-header">
        <div>
          <h1 className="page-title">⚔️ Vow Loyalty Center</h1>
          <p className="page-subtitle">Test covenant fidelity and detect breaches automatically</p>
        </div>
      </div>

      <div className="reputation-overview" style={{ marginBottom: '32px' }}>
        <div className="reputation-card main">
          <div className="score-section">
            <div className="score-circle" style={{ background: 'var(--gradient-primary)' }}>
              <span className="score-value">{allCovenants.length}</span>
              <span className="score-label">Covenants</span>
            </div>
            <div className="rank-badge">Scanned</div>
          </div>
          <div className="stats-grid">
            <div className="stat-box">
              <span className="stat-number">{allCovenants.filter(c => getLoyaltyBadge(c).class === 'faithful').length}</span>
              <span className="stat-label">Faithful</span>
            </div>
            <div className="stat-box">
              <span className="stat-number">{allCovenants.filter(c => getLoyaltyBadge(c).class === 'questionable').length}</span>
              <span className="stat-label">Questionable</span>
            </div>
            <div className="stat-box">
              <span className="stat-number">{allCovenants.filter(c => getLoyaltyBadge(c).class === 'oathbreaker').length}</span>
              <span className="stat-label">Oathbreaker</span>
            </div>
          </div>
        </div>

        <div className="reputation-breakdown">
          <h4>Loyalty Distribution</h4>
          <div className="breakdown-bars">
            <div className="breakdown-item">
              <span>Faithful</span>
              <div className="breakdown-bar"><div className="fill" style={{width: `${allCovenants.length ? (allCovenants.filter(c => getLoyaltyBadge(c).class === 'faithful').length / allCovenants.length) * 100 : 0}%`}} /></div>
              <span>{allCovenants.length ? Math.round((allCovenants.filter(c => getLoyaltyBadge(c).class === 'faithful').length / allCovenants.length) * 100) : 0}%</span>
            </div>
            <div className="breakdown-item">
              <span>Questionable</span>
              <div className="breakdown-bar"><div className="fill" style={{width: `${allCovenants.length ? (allCovenants.filter(c => getLoyaltyBadge(c).class === 'questionable').length / allCovenants.length) * 100 : 0}%`, background: 'var(--accent-warning)'}} /></div>
              <span>{allCovenants.length ? Math.round((allCovenants.filter(c => getLoyaltyBadge(c).class === 'questionable').length / allCovenants.length) * 100) : 0}%</span>
            </div>
            <div className="breakdown-item">
              <span>Oathbreaker</span>
              <div className="breakdown-bar"><div className="fill" style={{width: `${allCovenants.length ? (allCovenants.filter(c => getLoyaltyBadge(c).class === 'oathbreaker').length / allCovenants.length) * 100 : 0}%`, background: 'var(--accent-danger)'}} /></div>
              <span>{allCovenants.length ? Math.round((allCovenants.filter(c => getLoyaltyBadge(c).class === 'oathbreaker').length / allCovenants.length) * 100) : 0}%</span>
            </div>
          </div>
        </div>
      </div>

      <h2 className="section-title">All Covenants</h2>
      <div className="tasks-list">
        {allCovenants.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">⚔️</div>
            <h3>No covenants found</h3>
            <p>{loading ? 'Loading covenants...' : account ? 'You have no covenants to scan' : 'Connect your wallet to view covenants'}</p>
          </div>
        ) : (
          allCovenants.map((covenant, index) => {
          const badge = getLoyaltyBadge(covenant);
          const score = getScore(covenant);
          return (
            <motion.div
              key={covenant.id}
              className="task-list-item"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <div className="task-main">
                <h4>{covenant.title}</h4>
                <p>Covenant #{covenant.id} • {covenant.amount} ETH</p>
                <div className="task-tags">
                  <span className={`loyalty-badge ${badge.class}`}>{badge.label}</span>
                  <span className="status-tag" style={{ 
                    background: score >= 70 ? 'rgba(0,245,160,0.1)' : score >= 40 ? 'rgba(255,170,0,0.1)' : 'rgba(255,71,87,0.1)',
                    color: score >= 70 ? 'var(--accent-success)' : score >= 40 ? 'var(--accent-warning)' : 'var(--accent-danger)',
                    border: `1px solid ${score >= 70 ? 'rgba(0,245,160,0.2)' : score >= 40 ? 'rgba(255,170,0,0.2)' : 'rgba(255,71,87,0.2)'}`
                  }}>
                    Score: {score}
                  </span>
                </div>
              </div>
              <div className="task-stats" style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '13px', color: 'var(--text-muted)', marginBottom: '4px' }}>
                  {covenant.status}
                </div>
              </div>
              <button 
                className="test-loyalty-btn"
                onClick={() => onTestLoyalty && onTestLoyalty(covenant)}
              >
                ⚔️ Test Loyalty
              </button>
            </motion.div>
          );
        }))}
      </div>
    </div>
  );
}

// Wrap AppContent with providers
function App() {
  const [queryClient] = React.useState(() => new QueryClient());
  
  return (
    <ErrorBoundary>
      <WagmiProvider config={config}>
        <QueryClientProvider client={queryClient}>
          <RainbowKitProvider>
            <Router>
              <AppContent />
            </Router>
          </RainbowKitProvider>
        </QueryClientProvider>
      </WagmiProvider>
    </ErrorBoundary>
  );
}

export default App;
