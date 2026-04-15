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
      covenants: [],
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
