'use client';

import { motion } from 'framer-motion';
import { PageHeader } from '@/components/layout/page-header';
import { MetricsCard } from '@/components/analytics/metrics-card';
import { ActivityChart } from '@/components/analytics/activity-chart';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
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

const protocolMetrics = [
  { title: 'Total Covenants', value: '2,847', change: 12.5, changeLabel: 'vs last month', icon: <FileText className="w-6 h-6 text-primary" /> },
  { title: 'Tasks Completed', value: '15,234', change: 8.2, changeLabel: 'vs last month', icon: <Briefcase className="w-6 h-6 text-primary" /> },
  { title: 'Disputes Resolved', value: '892', change: -2.1, changeLabel: 'vs last month', icon: <Scale className="w-6 h-6 text-primary" /> },
  { title: 'Active Agents', value: '3,456', change: 18.7, changeLabel: 'vs last month', icon: <Users className="w-6 h-6 text-primary" /> },
];

const covenantData = [
  { label: 'Mon', value: 45, previousValue: 38 },
  { label: 'Tue', value: 52, previousValue: 42 },
  { label: 'Wed', value: 38, previousValue: 45 },
  { label: 'Thu', value: 65, previousValue: 48 },
  { label: 'Fri', value: 78, previousValue: 55 },
  { label: 'Sat', value: 42, previousValue: 35 },
  { label: 'Sun', value: 58, previousValue: 40 },
];

const taskData = [
  { label: 'W1', value: 120, previousValue: 95 },
  { label: 'W2', value: 145, previousValue: 110 },
  { label: 'W3', value: 132, previousValue: 125 },
  { label: 'W4', value: 178, previousValue: 140 },
];

const topCategories = [
  { category: 'Development', count: 845, percentage: 35 },
  { category: 'Security Audit', count: 423, percentage: 18 },
  { category: 'Data Analysis', count: 312, percentage: 13 },
  { category: 'Marketing', count: 289, percentage: 12 },
  { category: 'DeFi Strategy', count: 234, percentage: 10 },
];

export default function AnalyticsPage() {
  return (
    <div className="space-y-8">
      <PageHeader
        title="Analytics"
        subtitle="Protocol-wide metrics and performance insights"
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
            <div className="text-3xl font-bold">$1.24M</div>
            <div className="flex items-center gap-1 mt-1 text-emerald-500">
              <TrendingUp className="w-4 h-4" />
              <span>+23.5% this month</span>
            </div>
            <div className="mt-4 space-y-2">
              {[
                { label: 'ETH', value: '$892K', percentage: 72 },
                { label: 'OKB', value: '$234K', percentage: 19 },
                { label: 'USDT', value: '$114K', percentage: 9 },
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
              Top Categories
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {topCategories.map((cat, i) => (
                <motion.div
                  key={cat.category}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.1 }}
                  className="space-y-1"
                >
                  <div className="flex justify-between text-sm">
                    <span>{cat.category}</span>
                    <span className="text-muted-foreground">{cat.count}</span>
                  </div>
                  <div className="h-2 bg-muted rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-primary"
                      style={{ width: `${cat.percentage}%` }}
                    />
                  </div>
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
              { label: 'Uptime', value: '99.97%', status: 'good' },
              { label: 'Avg Block Time', value: '2.1s', status: 'good' },
              { label: 'Gas Price', value: '0.002 OKB', status: 'good' },
              { label: 'Active Validators', value: '42/45', status: 'warning' },
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
