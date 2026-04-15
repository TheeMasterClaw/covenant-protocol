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
      score: 0,
      rank: 'Unranked',
      totalStaked: '0',
      pendingRewards: '0',
      apr: 0,
      history: [],
      stats: {
        covenantsCompleted: 0,
        tasksCompleted: 0,
        disputesWon: 0,
        disputesLost: 0,
        avgRating: 0,
        responseTime: '--',
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
