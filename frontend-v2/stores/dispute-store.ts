import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface Dispute {
  id: string;
  covenantId: number;
  title: string;
  parties: string[];
  amount: string;
  reason?: string;
  status: 'voting' | 'evidence' | 'resolved';
  votesFor?: number;
  votesAgainst?: number;
  timeRemaining?: string;
  evidence?: string[];
  staked?: string;
  potentialReward?: string;
  winner?: string;
  resolution?: string;
  date?: string;
}

interface DisputeState {
  disputes: Dispute[];
  juryDuty: Dispute[];
  resolved: Dispute[];
  selectedDispute: Dispute | null;
  activeTab: 'active' | 'jury' | 'resolved';
  setDisputes: (disputes: Dispute[]) => void;
  addDispute: (dispute: Dispute) => void;
  selectDispute: (dispute: Dispute | null) => void;
  setActiveTab: (tab: 'active' | 'jury' | 'resolved') => void;
  voteOnDispute: (disputeId: string, vote: 'for' | 'against') => void;
}

export const useDisputeStore = create<DisputeState>()(
  persist(
    (set) => ({
      disputes: [],
      juryDuty: [],
      resolved: [],
      selectedDispute: null,
      activeTab: 'active',
      setDisputes: (disputes) => set({ disputes }),
      addDispute: (dispute) => set((state) => ({ disputes: [...state.disputes, dispute] })),
      selectDispute: (dispute) => set({ selectedDispute: dispute }),
      setActiveTab: (activeTab) => set({ activeTab }),
      voteOnDispute: (disputeId, vote) => set((state) => ({
        disputes: state.disputes.map(d => 
          d.id === disputeId 
            ? { ...d, votesFor: vote === 'for' ? (d.votesFor || 0) + 1 : d.votesFor, votesAgainst: vote === 'against' ? (d.votesAgainst || 0) + 1 : d.votesAgainst }
            : d
        )
      })),
    }),
    {
      name: 'dispute-store',
    }
  )
);
