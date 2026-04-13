import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface Milestone {
  title: string;
  description: string;
  amount: string;
  deadline: string;
  status: 'pending' | 'in_progress' | 'completed';
}

export interface Covenant {
  id: number;
  title: string;
  initiator: string;
  counterparty: string;
  amount: string;
  status: 'Active' | 'Pending' | 'Disputed' | 'Completed' | 'Cancelled';
  startDate?: string;
  endDate?: string;
  proposedDate?: string;
  completedDate?: string;
  milestones: Milestone[];
  progress: number;
  disputeReason?: string;
  covenantType: string;
}

interface CovenantState {
  covenants: Covenant[];
  selectedCovenant: Covenant | null;
  filter: 'all' | 'active' | 'pending' | 'completed' | 'disputed';
  searchQuery: string;
  setCovenants: (covenants: Covenant[]) => void;
  addCovenant: (covenant: Covenant) => void;
  updateCovenant: (id: number, updates: Partial<Covenant>) => void;
  selectCovenant: (covenant: Covenant | null) => void;
  setFilter: (filter: 'all' | 'active' | 'pending' | 'completed' | 'disputed') => void;
  setSearchQuery: (query: string) => void;
}

export const useCovenantStore = create<CovenantState>()(
  persist(
    (set) => ({
      covenants: [
        { 
          id: 2847, 
          title: 'Intelligence Analysis Partnership', 
          initiator: 'M1', 
          counterparty: 'D4', 
          amount: '5.0', 
          status: 'Active', 
          startDate: '2026-04-01',
          endDate: '2026-05-01',
          milestones: [
            {title: 'Kickoff', description: 'Initial setup', amount: '20', deadline: '7', status: 'completed'},
            {title: 'Data Collection', description: 'Gather data', amount: '40', deadline: '14', status: 'in_progress'},
            {title: 'Analysis', description: 'Final analysis', amount: '40', deadline: '30', status: 'pending'}
          ],
          progress: 35,
          covenantType: 'development'
        },
        { 
          id: 2846, 
          title: 'Cross-Chain Arbitrage Alliance', 
          initiator: 'A7', 
          counterparty: 'B2', 
          amount: '12.5', 
          status: 'Pending', 
          proposedDate: '2026-04-10',
          milestones: [],
          progress: 0,
          covenantType: 'arbitrage'
        },
        { 
          id: 2843, 
          title: 'Sentiment Analysis Task Force', 
          initiator: 'D2', 
          counterparty: 'D9', 
          amount: '2.0', 
          status: 'Disputed', 
          disputeReason: 'Milestone delivery disagreement',
          milestones: [],
          progress: 60,
          covenantType: 'analysis'
        },
      ],
      selectedCovenant: null,
      filter: 'all',
      searchQuery: '',
      setCovenants: (covenants) => set({ covenants }),
      addCovenant: (covenant) => set((state) => ({ covenants: [...state.covenants, covenant] })),
      updateCovenant: (id, updates) => set((state) => ({
        covenants: state.covenants.map(c => c.id === id ? { ...c, ...updates } : c)
      })),
      selectCovenant: (covenant) => set({ selectedCovenant: covenant }),
      setFilter: (filter) => set({ filter }),
      setSearchQuery: (searchQuery) => set({ searchQuery }),
    }),
    {
      name: 'covenant-store',
    }
  )
);
