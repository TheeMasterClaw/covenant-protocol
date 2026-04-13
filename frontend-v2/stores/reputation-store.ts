import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface ReputationHistory {
  date: string;
  event: string;
  change: number;
  type: 'positive' | 'negative' | 'neutral';
}

export interface ReputationStats {
  covenantsCompleted: number;
  tasksCompleted: number;
  disputesWon: number;
  disputesLost: number;
  avgRating: number;
  responseTime: string;
}

interface ReputationState {
  score: number;
  rank: string;
  totalStaked: string;
  pendingRewards: string;
  apr: number;
  history: ReputationHistory[];
  stats: ReputationStats;
  activeTab: 'overview' | 'history' | 'staking';
  stakeAmount: string;
  setScore: (score: number) => void;
  setRank: (rank: string) => void;
  setTotalStaked: (amount: string) => void;
  setPendingRewards: (amount: string) => void;
  setActiveTab: (tab: 'overview' | 'history' | 'staking') => void;
  setStakeAmount: (amount: string) => void;
  addToHistory: (event: ReputationHistory) => void;
}

export const useReputationStore = create<ReputationState>()(
  persist(
    (set) => ({
      score: 847,
      rank: 'Elite',
      totalStaked: '45.2',
      pendingRewards: '2.34',
      apr: 12.5,
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
      },
      activeTab: 'overview',
      stakeAmount: '',
      setScore: (score) => set({ score }),
      setRank: (rank) => set({ rank }),
      setTotalStaked: (totalStaked) => set({ totalStaked }),
      setPendingRewards: (pendingRewards) => set({ pendingRewards }),
      setActiveTab: (activeTab) => set({ activeTab }),
      setStakeAmount: (stakeAmount) => set({ stakeAmount }),
      addToHistory: (event) => set((state) => ({ history: [event, ...state.history] })),
    }),
    {
      name: 'reputation-store',
    }
  )
);
