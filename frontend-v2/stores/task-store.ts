import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface Task {
  id: number;
  title: string;
  description: string;
  reward: string;
  bids: number;
  priority: 'High' | 'Medium' | 'Low';
  deadline: string;
  skills: string[];
  poster: string;
  posted: string;
  status: 'open' | 'in_progress' | 'completed' | 'cancelled';
  progress?: number;
  assignee?: string;
}

interface TaskState {
  tasks: Task[];
  myTasks: Task[];
  myBids: { id: number; title: string; myBid: string; status: string; totalBids: number }[];
  selectedTask: Task | null;
  activeTab: 'browse' | 'myTasks' | 'myBids';
  searchQuery: string;
  skillFilter: string;
  priceFilter: string;
  setTasks: (tasks: Task[]) => void;
  addTask: (task: Task) => void;
  selectTask: (task: Task | null) => void;
  setActiveTab: (tab: 'browse' | 'myTasks' | 'myBids') => void;
  setSearchQuery: (query: string) => void;
  setSkillFilter: (filter: string) => void;
  setPriceFilter: (filter: string) => void;
}

export const useTaskStore = create<TaskState>()(
  persist(
    (set) => ({
      tasks: [
        { id: 1, title: 'Smart Contract Security Audit', description: 'Audit a new DeFi protocol for vulnerabilities. Focus on reentrancy, access control, and economic attacks.', reward: '3.5', bids: 8, priority: 'High', deadline: '2026-04-20', skills: ['Solidity', 'Security'], poster: '0x1234...5678', posted: '2 days ago', status: 'open' },
        { id: 2, title: 'On-Chain Data Analysis Pipeline', description: 'Build real-time analysis pipeline for X Layer transaction patterns and anomaly detection.', reward: '1.2', bids: 12, priority: 'Medium', deadline: '2026-04-25', skills: ['Python', 'Data', 'SQL'], poster: '0xabcd...efgh', posted: '1 day ago', status: 'open' },
        { id: 3, title: 'Documentation Translation', description: 'Translate protocol documentation to CN, JP, KR. Technical blockchain knowledge required.', reward: '0.5', bids: 5, priority: 'Low', deadline: '2026-05-01', skills: ['Translation', 'Technical Writing'], poster: '0x9876...5432', posted: '3 days ago', status: 'open' },
        { id: 4, title: 'Frontend DApp Development', description: 'Build React frontend for new NFT marketplace. Include wallet integration and IPFS metadata handling.', reward: '2.0', bids: 15, priority: 'High', deadline: '2026-04-18', skills: ['React', 'Web3', 'IPFS'], poster: '0xwxyz...mnop', posted: '5 hours ago', status: 'open' },
        { id: 5, title: 'Liquidity Optimization Strategy', description: 'Design automated liquidity provision strategy for Uniswap V3 positions.', reward: '5.0', bids: 4, priority: 'High', deadline: '2026-04-22', skills: ['DeFi', 'Math', 'Solidity'], poster: '0xqwer...tyui', posted: '1 day ago', status: 'open' },
      ],
      myTasks: [
        { id: 101, title: 'API Integration Module', description: 'Build API integration', reward: '1.5', bids: 0, priority: 'Medium', deadline: '2026-04-15', skills: ['API'], poster: 'You', posted: '1 week ago', status: 'in_progress', progress: 60, assignee: '0xasdf...ghjk' },
        { id: 102, title: 'Discord Bot Development', description: 'Build bot', reward: '0.8', bids: 3, priority: 'Low', deadline: '2026-04-30', skills: ['Node.js'], poster: 'You', posted: '2 days ago', status: 'open' },
      ],
      myBids: [
        { id: 1, title: 'Smart Contract Security Audit', myBid: '3.0', status: 'pending', totalBids: 8 },
        { id: 4, title: 'Frontend DApp Development', myBid: '1.8', status: 'accepted', totalBids: 15 },
      ],
      selectedTask: null,
      activeTab: 'browse',
      searchQuery: '',
      skillFilter: 'All',
      priceFilter: 'Any',
      setTasks: (tasks) => set({ tasks }),
      addTask: (task) => set((state) => ({ tasks: [...state.tasks, task] })),
      selectTask: (task) => set({ selectedTask: task }),
      setActiveTab: (activeTab) => set({ activeTab }),
      setSearchQuery: (searchQuery) => set({ searchQuery }),
      setSkillFilter: (skillFilter) => set({ skillFilter }),
      setPriceFilter: (priceFilter) => set({ priceFilter }),
    }),
    {
      name: 'task-store',
    }
  )
);
