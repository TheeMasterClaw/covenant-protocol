'use client';

import { motion } from 'framer-motion';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useReputationStore } from '@/stores/reputation-store';
import { ScoreCard } from '@/components/reputation/score-card';
import { StakingPanel } from '@/components/reputation/staking-panel';
import { HistoryTimeline } from '@/components/reputation/history-timeline';
import { PageHeader } from '@/components/layout/page-header';
import { Card, CardContent } from '@/components/ui/card';

export default function ReputationPage() {
  const { score, rank, totalStaked, pendingRewards, apr, history, stats, activeTab, setActiveTab } = useReputationStore();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reputation Profile"
        subtitle="Your on-chain reputation and staking position"
      />

      <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as typeof activeTab)}>
        <TabsList className="grid grid-cols-3 w-full max-w-md">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="history">History</TabsTrigger>
          <TabsTrigger value="staking">Staking</TabsTrigger>
        </TabsList>
      </Tabs>

      {activeTab === 'overview' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-6"
        >
          <ScoreCard score={score} rank={rank} previousScore={824} />
          
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: 'Covenants', value: stats.covenantsCompleted },
              { label: 'Tasks', value: stats.tasksCompleted },
              { label: 'Avg Rating', value: stats.avgRating },
              { label: 'Response Time', value: stats.responseTime },
            ].map((stat, i) => (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 * i }}
              >
                <Card>
                  <CardContent className="pt-6 text-center">
                    <p className="text-2xl font-bold">{stat.value}</p>
                    <p className="text-sm text-muted-foreground">{stat.label}</p>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
          </div>

          <Card>
            <CardContent className="pt-6">
              <h3 className="font-semibold mb-4">Score Breakdown</h3>
              <div className="space-y-4">
                {[
                  { label: 'Completion Rate (40%)', value: 95, current: '380/400' },
                  { label: 'Quality Rating (30%)', value: 92, current: '276/300' },
                  { label: 'Stake Amount (20%)', value: 95, current: '190/200' },
                  { label: 'Dispute Record (10%)', value: 89, current: '89/100' },
                ].map((item, i) => (
                  <div key={item.label} className="space-y-1">
                    <div className="flex justify-between text-sm">
                      <span>{item.label}</span>
                      <span className="text-muted-foreground">{item.current}</span>
                    </div>
                    <div className="h-2 bg-muted rounded-full overflow-hidden">
                      <motion.div
                        className="h-full bg-primary"
                        initial={{ width: 0 }}
                        animate={{ width: `${item.value}%` }}
                        transition={{ duration: 0.8, delay: 0.2 + i * 0.1 }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </motion.div>
      )}

      {activeTab === 'history' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <HistoryTimeline history={history} />
        </motion.div>
      )}

      {activeTab === 'staking' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <StakingPanel totalStaked={totalStaked} pendingRewards={pendingRewards} apr={apr} />
        </motion.div>
      )}
    </div>
  );
}
