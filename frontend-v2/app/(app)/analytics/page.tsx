'use client';

import { motion } from 'framer-motion';
import { PageHeader } from '@/components/layout/page-header';
import { MetricsCard } from '@/components/analytics/metrics-card';
import { ActivityChart } from '@/components/analytics/activity-chart';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { useProtocolStats, formatEther } from '@/hooks/use-contracts';
import {
  FileText,
  Briefcase,
  Scale,
  Users,
  TrendingUp,
  Activity,
  DollarSign,
  Star
} from 'lucide-react';

const covenantData = [
  { label: 'Mon', value: 0, previousValue: 0 },
  { label: 'Tue', value: 0, previousValue: 0 },
  { label: 'Wed', value: 0, previousValue: 0 },
  { label: 'Thu', value: 0, previousValue: 0 },
  { label: 'Fri', value: 0, previousValue: 0 },
  { label: 'Sat', value: 0, previousValue: 0 },
  { label: 'Sun', value: 0, previousValue: 0 },
];

const taskData = [
  { label: 'W1', value: 0, previousValue: 0 },
  { label: 'W2', value: 0, previousValue: 0 },
  { label: 'W3', value: 0, previousValue: 0 },
  { label: 'W4', value: 0, previousValue: 0 },
];

export default function AnalyticsPage() {
  const protocol = useProtocolStats();

  const protocolMetrics = [
    {
      title: 'Total Covenants',
      value: protocol.totalCovenants?.toString() ?? '--',
      change: 0,
      changeLabel: 'on-chain',
      icon: <FileText className="w-6 h-6 text-primary" />
    },
    {
      title: 'Tasks Completed',
      value: protocol.totalTasksCompleted?.toString() ?? '--',
      change: 0,
      changeLabel: 'on-chain',
      icon: <Briefcase className="w-6 h-6 text-primary" />
    },
    {
      title: 'Disputes Filed',
      value: protocol.nextDisputeId != null ? protocol.nextDisputeId.toString() : '--',
      change: 0,
      changeLabel: 'on-chain',
      icon: <Scale className="w-6 h-6 text-primary" />
    },
    {
      title: 'Registered Agents',
      value: protocol.totalAgents?.toString() ?? '--',
      change: 0,
      changeLabel: 'on-chain',
      icon: <Users className="w-6 h-6 text-primary" />
    },
  ];

  return (
    <div className="space-y-8">
      <PageHeader
        title="Analytics"
        subtitle="Protocol-wide metrics and performance insights — live from X Layer Testnet"
      />

      {/* Protocol Metrics */}
      <section>
        <h2 className="text-lg font-semibold mb-4">Protocol Metrics</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {protocolMetrics.map((metric, i) => (
            <MetricsCard
              key={metric.title}
              title={metric.title}
              value={metric.value}
              change={metric.change}
              changeLabel={metric.changeLabel}
              icon={metric.icon}
              index={i}
            />
          ))}
        </div>
      </section>

      {/* Charts */}
      <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <ActivityChart
          title="Covenants Created"
          data={covenantData}
          color="var(--primary)"
        />
        <ActivityChart
          title="Tasks Completed"
          data={taskData}
          color="#10b981"
        />
      </section>

      {/* Additional Stats */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <DollarSign className="w-5 h-5" />
              Value Locked
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-3xl font-bold">
              {protocol.totalValueLocked != null ? `${formatEther(protocol.totalValueLocked)} OKB` : '--'}
            </div>
            <div className="flex items-center gap-1 mt-1 text-muted-foreground">
              <TrendingUp className="w-4 h-4" />
              <span>TaskMarket TVL</span>
            </div>
            <div className="mt-4 space-y-2">
              {[
                { label: 'Task Rewards (OKB)', value: protocol.totalValueLocked != null ? `${formatEther(protocol.totalValueLocked)}` : '--', percentage: protocol.totalValueLocked != null && protocol.totalValueLocked > 0n ? 100 : 0 },
                { label: 'Staked (COV)', value: protocol.totalStaked != null ? `${formatEther(protocol.totalStaked)}` : '--', percentage: protocol.totalStaked != null && protocol.totalStaked > 0n ? 100 : 0 },
              ].map((item) => (
                <div key={item.label} className="space-y-1">
                  <div className="flex justify-between text-sm">
                    <span>{item.label}</span>
                    <span className="text-muted-foreground">{item.value}</span>
                  </div>
                  <div className="h-2 bg-muted rounded-full overflow-hidden">
                    <div className="h-full bg-primary" style={{ width: `${item.percentage}%` }} />
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Star className="w-5 h-5" />
              Protocol Summary
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {[
                { label: 'Total Tasks Posted', value: protocol.totalTasksPosted?.toString() ?? '0' },
                { label: 'Tasks Completed', value: protocol.totalTasksCompleted?.toString() ?? '0' },
                { label: 'Staked Agents', value: protocol.stakedAgents?.toString() ?? '0' },
                { label: 'Total Disputes', value: protocol.nextDisputeId?.toString() ?? '0' },
              ].map((item, i) => (
                <motion.div
                  key={item.label}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.1 }}
                  className="flex items-center justify-between p-3 bg-muted/50 rounded-lg"
                >
                  <span className="text-sm">{item.label}</span>
                  <span className="text-sm font-medium">{item.value}</span>
                </motion.div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-lg flex items-center gap-2">
              <Activity className="w-5 h-5" />
              Network Health
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {[
              { label: 'Network', value: 'X Layer Testnet', status: 'good' },
              { label: 'Chain ID', value: '1952', status: 'good' },
              { label: 'Contracts', value: '6 deployed', status: 'good' },
              { label: 'Status', value: protocol.isLoading ? 'Loading...' : protocol.error ? 'Error' : 'Operational', status: protocol.error ? 'warn' : 'good' },
            ].map((item) => (
              <div key={item.label} className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
                <span className="text-sm">{item.label}</span>
                <span className={`text-sm font-medium ${
                  item.status === 'good' ? 'text-emerald-500' : 'text-amber-500'
                }`}>
                  {item.value}
                </span>
              </div>
            ))}
          </CardContent>
        </Card>
      </section>
    </div>
  );
}
