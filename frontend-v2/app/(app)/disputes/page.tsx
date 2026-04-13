'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { Gavel } from 'lucide-react';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useDisputeStore } from '@/stores/dispute-store';
import { DisputeCard } from '@/components/dispute/dispute-card';
import { DisputeDetail } from '@/components/dispute/dispute-detail';
import { PageHeader } from '@/components/layout/page-header';
import { EmptyState } from '@/components/layout/empty-state';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function DisputesPage() {
  const { disputes, juryDuty, resolved, activeTab, setActiveTab, selectedDispute, selectDispute, voteOnDispute } = useDisputeStore();

  const currentItems = activeTab === 'active' ? disputes : activeTab === 'jury' ? juryDuty : resolved;

  if (selectedDispute) {
    return (
      <DisputeDetail
        dispute={selectedDispute}
        isJuror={activeTab === 'jury'}
        onBack={() => selectDispute(null)}
        onVote={(vote) => {
          voteOnDispute(selectedDispute.id, vote);
          selectDispute(null);
        }}
      />
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dispute Court"
        subtitle="Decentralized arbitration for covenant conflicts"
      />

      <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as typeof activeTab)}>
        <TabsList className="grid grid-cols-3 w-full max-w-md">
          <TabsTrigger value="active">Active</TabsTrigger>
          <TabsTrigger value="jury">My Jury Duty</TabsTrigger>
          <TabsTrigger value="resolved">Resolved</TabsTrigger>
        </TabsList>
      </Tabs>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <AnimatePresence mode="wait">
            {currentItems.length === 0 ? (
              <EmptyState
                title="No disputes"
                description={`You have no ${activeTab} disputes.`}
                icon={<Gavel className="w-10 h-10 text-muted-foreground" />}
              />
            ) : (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="space-y-4"
              >
                {currentItems.map((dispute, i) => (
                  <DisputeCard
                    key={dispute.id}
                    dispute={dispute}
                    index={i}
                    variant={activeTab}
                    onView={selectDispute}
                  />
                ))}
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-lg">How It Works</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {[
                  { step: 1, text: 'Either party raises a dispute' },
                  { step: 2, text: 'Evidence submission period (48h)' },
                  { step: 3, text: 'Staked jurors vote on outcome' },
                  { step: 4, text: 'Majority decision executed' },
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <div className="w-6 h-6 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                      <span className="text-xs font-semibold">{item.step}</span>
                    </div>
                    <p className="text-sm text-muted-foreground">{item.text}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
