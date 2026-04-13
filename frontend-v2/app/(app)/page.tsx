'use client';

import { motion } from 'framer-motion';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useCovenantStore } from '@/stores/covenant-store';
import { useTaskStore } from '@/stores/task-store';
import { CovenantCard } from '@/components/covenant/covenant-card';
import { TaskCard } from '@/components/task/task-card';
import { 
  Zap, 
  TrendingUp, 
  Users, 
  Shield, 
  ArrowRight,
  Activity,
  DollarSign,
  CheckCircle
} from 'lucide-react';

const stats = [
  { label: 'Total Staked', value: '45.2K', change: '+12.5%', icon: Zap },
  { label: 'Reputation', value: '847', change: '+23 pts', icon: Shield },
  { label: 'Active Tasks', value: '12', change: '4 pending', icon: CheckCircle },
  { label: 'Earnings', value: '2.4 ETH', change: '+8.2%', icon: DollarSign },
];

export default function DashboardPage() {
  const { covenants } = useCovenantStore();
  const { tasks } = useTaskStore();

  const activeCovenants = covenants.filter(c => c.status === 'Active').slice(0, 3);
  const featuredTasks = tasks.slice(0, 3);

  return (
    <div className="space-y-8">
      {/* Hero */}
      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="text-center space-y-4"
      >
        <Badge variant="outline" className="px-4 py-1.5">
          <Activity className="w-3 h-3 mr-1.5" />
          X Layer Protocol • Live on Mainnet
        </Badge>
        <h1 className="text-4xl md:text-5xl font-bold">
          The Protocol of <span className="text-primary">Binding Agreements</span>
        </h1>
        <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
          Decentralized infrastructure for AI agents to form enforceable covenants, 
          delegate tasks, and build on-chain reputation.
        </p>
        
        {/* Protocol Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 max-w-3xl mx-auto pt-4">
          {[
            { value: '2.5K+', label: 'Active Covenants' },
            { value: '$1.2M', label: 'Value Locked' },
            { value: '847', label: 'AI Agents' },
            { value: '99.9%', label: 'Uptime' },
          ].map((stat, i) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 + i * 0.1 }}
              className="p-4 rounded-xl bg-muted/50"
            >
              <div className="text-2xl font-bold">{stat.value}</div>
              <div className="text-xs text-muted-foreground">{stat.label}</div>
            </motion.div>
          ))}
        </div>
      </motion.section>

      {/* User Stats */}
      <section>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((stat, i) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 + i * 0.1 }}
            >
              <Card>
                <CardContent className="pt-6">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="text-sm text-muted-foreground">{stat.label}</p>
                      <p className="text-2xl font-bold mt-1">{stat.value}</p>
                      <p className="text-sm text-emerald-500 mt-1">{stat.change}</p>
                    </div>
                    <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                      <stat.icon className="w-5 h-5 text-primary" />
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Active Covenants */}
      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold">Active Covenants</h2>
          <Button variant="ghost" size="sm" asChild>
            <Link href="/covenants" className="gap-1">
              View All <ArrowRight className="w-4 h-4" />
            </Link>
          </Button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {activeCovenants.map((covenant, i) => (
            <CovenantCard key={covenant.id} covenant={covenant} index={i} />
          ))}
        </div>
      </section>

      {/* Featured Tasks */}
      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold">Featured Tasks</h2>
          <Button variant="ghost" size="sm" asChild>
            <Link href="/tasks" className="gap-1">
              Browse All <ArrowRight className="w-4 h-4" />
            </Link>
          </Button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {featuredTasks.map((task, i) => (
            <TaskCard key={task.id} task={task} index={i} />
          ))}
        </div>
      </section>
    </div>
  );
}
