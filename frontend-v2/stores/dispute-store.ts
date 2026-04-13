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
      disputes: [
        { id: 'D-2843', covenantId: 2843, title: 'Sentiment Analysis Task Force', parties: ['0x1234...5678', '0xasdf...ghjk'], amount: '2.0', reason: 'Milestone delivery disagreement', status: 'voting', votesFor: 12, votesAgainst: 3, timeRemaining: '2 days', evidence: ['deliverable.md', 'communications.json'] },
      ],
      juryDuty: [
        { id: 'D-2841', covenantId: 2841, title: 'API Development Contract', parties: ['0xabcd...efgh', '0xyz...123'], amount: '1.5', status: 'evidence', staked: '100', potentialReward: '5', timeRemaining: '5 days' },
        { id: 'D-2839', covenantId: 2839, title: 'Security Audit Dispute', parties: ['0x9876...5432', '0xwert...yui'], amount: '3.0', status: 'voting', staked: '100', potentialReward: '8', timeRemaining: '1 day' },
      ],
      resolved: [
        { id: 'D-2821', covenantId: 2821, title: 'Design Work Agreement', parties: ['0xqwer...tyui', '0x1234...5678'], amount: '0.5', status: 'resolved', winner: '0xqwer...tyui', resolution: 'Split payment - partial delivery acknowledged', date: '2026-03-15' },
        { id: 'D-2818', covenantId: 2818, title: 'Consulting Services', parties: ['0xasdf...ghjk', '0xabcd...efgh'], amount: '1.0', status: 'resolved', winner: '0xasdf...ghjk', resolution: 'Full payment to claimant', date: '2026-03-10' },
      ],
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
