'use client';

import { motion } from 'framer-motion';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useReputationStore } from '@/stores/reputation-store';
import { ScoreCard } from '@/components/reputation/score-card';
import { StakingPanel } from '@/components/reputation/staking-panel';
import { HistoryTimeline } from '@/components/reputation/history-timeline';
import { PageHeader } from '@/components/layout/page-header';
import { Card, CardContent } from '@/components/ui/card';
import { useAccount } from 'wagmi';
import { useReputationScore, useReputationProfile, useAgentStats, useTokenBalance, formatEther } from '@/hooks/use-contracts';
import { useEffect } from 'react';

export default function ReputationPage() {
  const { address, isConnected } = useAccount();
  const { score: chainScore } = useReputationScore(address);
  const { profile } = useReputationProfile(address);
  const { stats: taskStats } = useAgentStats(address);
  const { balance: tokenBalance } = useTokenBalance(address);

  const {
    score, rank, totalStaked, pendingRewards, apr, history, stats, activeTab, setActiveTab,
    setScore, setRank, setTotalStaked,
  } = useReputationStore();

  // Sync on-chain data to store
  useEffect(() => {
    if (chainScore != null) {
      const s = Number(chainScore);
      setScore(s);
      if (s >= 900) setRank('Legendary');
      else if (s >= 700) setRank('Expert');
      else if (s >= 500) setRank('Skilled');
      else if (s >= 300) setRank('Apprentice');
      else if (s > 0) setRank('Novice');
      else setRank('Unranked');
    }
  }, [chainScore, setScore, setRank]);

  useEffect(() => {
    if (profile) {
      const staked = profile.totalStaked ?? profile[2];
      if (staked != null) setTotalStaked(formatEther(staked));
    }
  }, [profile, setTotalStaked]);

  const covenantsCompleted = taskStats ? Number(taskStats[0]) : stats.covenantsCompleted;
  const tasksCompleted = taskStats ? Number(taskStats[0]) : stats.tasksCompleted;
  const totalEarnings = taskStats ? formatEther(taskStats[2]) : '0';

  return (
    <div className="space-y-6">
      <PageHeader
        title="Reputation Profile"
        subtitle={isConnected ? `On-chain reputation for ${address?.slice(0, 6)}...${address?.slice(-4)}` : 'Connect your wallet to view your on-chain reputation'}
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
          <ScoreCard score={score} rank={rank} previousScore={0} />

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: 'Tasks Done', value: tasksCompleted },
              { label: 'Total Earned', value: `${totalEarnings} OKB` },
              { label: 'COV Balance', value: tokenBalance != null ? formatEther(tokenBalance) : '--' },
              { label: 'Total Staked', value: `${totalStaked} COV` },
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
                  { label: 'Completion Rate (40%)', value: Math.min(100, (score / 1000) * 100), current: `${Math.round(score * 0.4)}/400` },
                  { label: 'Quality Rating (30%)', value: Math.min(100, (score / 1000) * 100), current: `${Math.round(score * 0.3)}/300` },
                  { label: 'Stake Amount (20%)', value: Math.min(100, (parseFloat(totalStaked) > 0 ? 50 : 0)), current: `${Math.round(score * 0.2)}/200` },
                  { label: 'Dispute Record (10%)', value: Math.min(100, (score / 1000) * 100), current: `${Math.round(score * 0.1)}/100` },
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
