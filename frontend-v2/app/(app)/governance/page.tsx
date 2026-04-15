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
import { useProtocolStats, formatEther } from '@/hooks/use-contracts';

export default function GovernancePage() {
  const [activeTab, setActiveTab] = useState<'proposals' | 'treasury'>('proposals');
  const protocol = useProtocolStats();

  const proposals: Proposal[] = [];

  const treasuryAllocations = protocol.totalValueLocked != null && protocol.totalValueLocked > 0n
    ? [{ name: 'Task Rewards', value: Number(formatEther(protocol.totalValueLocked)), percentage: 100 }]
    : [];

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
            totalValue={protocol.totalValueLocked != null ? formatEther(protocol.totalValueLocked) : '0'}
            monthlyChange={0}
            allocations={treasuryAllocations}
          />
        </motion.div>
      )}
    </div>
  );
}
