'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Plus, ScrollText } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { PageHeader } from '@/components/layout/page-header';
import { EmptyState } from '@/components/layout/empty-state';
import { ProposalCard, Proposal } from '@/components/governance/proposal-card';
import { TreasuryStats } from '@/components/governance/treasury-stats';

const proposals: Proposal[] = [
  {
    id: 'PIP-001',
    title: 'Increase Juror Rewards by 15%',
    description: 'Proposal to increase rewards for active jurors in the dispute resolution mechanism to improve participation rates.',
    status: 'active',
    votesFor: 1247,
    votesAgainst: 389,
    totalVotes: 1636,
    quorum: 2000,
    deadline: '2 days left',
    proposer: '0x1234...5678',
    category: 'Rewards',
  },
  {
    id: 'PIP-002',
    title: 'Add zk-SNARK Verification for Covenants',
    description: 'Implement zero-knowledge proof verification for covenant terms to enhance privacy while maintaining enforceability.',
    status: 'active',
    votesFor: 892,
    votesAgainst: 234,
    totalVotes: 1126,
    quorum: 1500,
    deadline: '5 days left',
    proposer: '0xabcd...efgh',
    category: 'Technology',
  },
  {
    id: 'PIP-003',
    title: 'Treasury Grant for AI Agent Research',
    description: 'Allocate 50 ETH from treasury to fund research into autonomous AI agent covenant enforcement.',
    status: 'passed',
    votesFor: 2156,
    votesAgainst: 445,
    totalVotes: 2601,
    quorum: 2000,
    deadline: 'Ended 3 days ago',
    proposer: '0x9876...5432',
    category: 'Treasury',
  },
  {
    id: 'PIP-004',
    title: 'Reduce Platform Fee to 0.75%',
    description: 'Lower the platform fee from 1% to 0.75% to make covenants more accessible to smaller agents.',
    status: 'rejected',
    votesFor: 567,
    votesAgainst: 1890,
    totalVotes: 2457,
    quorum: 2000,
    deadline: 'Ended 1 week ago',
    proposer: '0xwxyz...mnop',
    category: 'Fees',
  },
];

const treasuryAllocations = [
  { category: 'Development', amount: '450.2', percentage: 35, color: '#3b82f6' },
  { category: 'Community Grants', amount: '289.5', percentage: 22, color: '#10b981' },
  { category: 'Marketing', amount: '192.3', percentage: 15, color: '#f59e0b' },
  { category: 'Reserves', amount: '256.8', percentage: 20, color: '#8b5cf6' },
  { category: 'Operations', amount: '102.4', percentage: 8, color: '#6b7280' },
];

export default function GovernancePage() {
  const [activeTab, setActiveTab] = useState<'proposals' | 'treasury'>('proposals');

  return (
    <div className="space-y-6">
      <PageHeader
        title="Governance"
        subtitle="Participate in protocol governance and treasury decisions"
        action={
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            New Proposal
          </Button>
        }
      />

      <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as typeof activeTab)}>
        <TabsList className="grid grid-cols-2 w-full max-w-md">
          <TabsTrigger value="proposals">Proposals</TabsTrigger>
          <TabsTrigger value="treasury">Treasury</TabsTrigger>
        </TabsList>
      </Tabs>

      {activeTab === 'proposals' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-4"
        >
          {proposals.length === 0 ? (
            <EmptyState
              title="No proposals"
              description="There are no active governance proposals at this time."
              icon={<ScrollText className="w-10 h-10 text-muted-foreground" />}
            />
          ) : (
            proposals.map((proposal, i) => (
              <ProposalCard
                key={proposal.id}
                proposal={proposal}
                index={i}
                onVote={(id, vote) => console.log('Voted', id, vote)}
              />
            ))
          )}
        </motion.div>
      )}

      {activeTab === 'treasury' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <TreasuryStats
            totalValue="1,291.2"
            monthlyChange={8.4}
            allocations={treasuryAllocations}
          />
        </motion.div>
      )}
    </div>
  );
}
