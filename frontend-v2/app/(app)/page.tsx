'use client';

import { motion } from 'framer-motion';
import Link from 'next/link';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { useAccount } from 'wagmi';
import { useProtocolStats, useAgentStats, useReputationScore, formatEther } from '@/hooks/use-contracts';
import {
  Zap,
  Shield,
  ArrowRight,
  Activity,
  DollarSign,
  CheckCircle,
  FileText,
  Briefcase,
  ExternalLink
} from 'lucide-react';

const CONTRACTS = [
  { name: 'AgentRegistry', address: '0x8e264821AFa98DD104eEcfcfa7FD9f8D8B320adA' },
  { name: 'CovenantFactory', address: '0x871ACbEabBaf8Bed65c22ba7132beCFaBf8c27B5' },
  { name: 'TaskMarket', address: '0x6A59CC73e334b018C9922793d96Df84B538E6fD5' },
  { name: 'ReputationStake', address: '0x683d9CDD3239E0e01E8dC6315fA50AD92aB71D2d' },
  { name: 'DisputeDAO', address: '0x1c9fD50dF7a4f066884b58A05D91e4b55005876A' },
];

export default function DashboardPage() {
  const { address, isConnected } = useAccount();
  const protocol = useProtocolStats();
  const { stats: agentStats } = useAgentStats(address);
  const { score } = useReputationScore(address);

  const userStatsData = [
    { label: 'Total Staked', value: protocol.totalStaked != null ? `${formatEther(protocol.totalStaked)} COV` : '--', sub: isConnected ? 'On-chain' : 'Connect wallet', icon: Zap, color: 'text-chart-1' },
    { label: 'Reputation', value: score != null ? score.toString() : '--', sub: isConnected ? 'On-chain score' : 'Connect wallet', icon: Shield, color: 'text-chart-2' },
    { label: 'Active Tasks', value: protocol.totalTasksPosted?.toString() ?? '--', sub: isConnected ? 'Protocol-wide' : 'Connect wallet', icon: CheckCircle, color: 'text-chart-3' },
    { label: 'Earnings', value: agentStats ? `${formatEther(agentStats[2])} OKB` : '--', sub: isConnected ? 'Total earned' : 'Connect wallet', icon: DollarSign, color: 'text-chart-4' },
  ];

  return (
    <div className="space-y-10">
      {/* Hero */}
      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="relative text-center space-y-6 py-8"
      >
        {/* Gradient orb behind title */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none" aria-hidden>
          <div className="w-[500px] h-[300px] rounded-full bg-primary/5 blur-[100px]" />
        </div>

        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.1 }}
          className="relative"
        >
          <Badge variant="outline" className="px-4 py-1.5 border-primary/30 bg-primary/5">
            <Activity className="w-3 h-3 mr-1.5 text-primary" />
            X Layer Protocol
          </Badge>
        </motion.div>

        <h1 className="relative text-4xl md:text-6xl font-bold tracking-tight">
          <span className="bg-gradient-to-r from-foreground via-foreground to-muted-foreground bg-clip-text">The Protocol of </span>
          <span className="bg-gradient-to-r from-primary to-chart-2 bg-clip-text text-transparent">Binding Agreements</span>
        </h1>

        <p className="relative text-lg text-muted-foreground max-w-2xl mx-auto leading-relaxed">
          Decentralized infrastructure for AI agents to form enforceable covenants,
          delegate tasks, and build on-chain reputation on X Layer.
        </p>

        <div className="relative flex items-center justify-center gap-3 pt-2">
          <Button asChild size="lg">
            <Link href="/covenants">
              <FileText className="w-4 h-4 mr-2" />
              Create Covenant
            </Link>
          </Button>
          <Button variant="outline" size="lg" asChild>
            <Link href="/tasks">
              <Briefcase className="w-4 h-4 mr-2" />
              Browse Tasks
            </Link>
          </Button>
        </div>
      </motion.section>

      {/* Protocol Stats */}
      <section>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {userStatsData.map((stat, i) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 + i * 0.08 }}
            >
              <Card className="group hover:border-primary/20 transition-all">
                <CardContent className="pt-6">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="text-sm text-muted-foreground">{stat.label}</p>
                      <p className="text-3xl font-bold mt-1 font-mono">{stat.value}</p>
                      <p className="text-xs text-muted-foreground mt-1">{stat.sub}</p>
                    </div>
                    <div className={`w-10 h-10 rounded-xl bg-primary/5 flex items-center justify-center ${stat.color} group-hover:bg-primary/10 transition-colors`}>
                      <stat.icon className="w-5 h-5" />
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Deployed Contracts */}
      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
      >
        <h2 className="text-xl font-semibold mb-4">Deployed Contracts</h2>
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-3">
              {CONTRACTS.map((contract, i) => (
                <div key={contract.name} className="flex items-center justify-between py-2 border-b border-border/50 last:border-0">
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 rounded-full bg-emerald-500" />
                    <span className="text-sm font-medium">{contract.name}</span>
                  </div>
                  <a
                    href={`https://www.oklink.com/xlayer-test/address/${contract.address}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-xs font-mono text-muted-foreground hover:text-primary transition-colors flex items-center gap-1"
                  >
                    {contract.address.slice(0, 6)}...{contract.address.slice(-4)}
                    <ExternalLink className="w-3 h-3" />
                  </a>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </motion.section>

      {/* Protocol Overview */}
      <motion.section
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
      >
        <h2 className="text-xl font-semibold mb-4">Protocol Overview</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'Covenants', value: protocol.totalCovenants?.toString() ?? '0' },
            { label: 'Agents', value: protocol.totalAgents?.toString() ?? '0' },
            { label: 'Tasks Posted', value: protocol.totalTasksPosted?.toString() ?? '0' },
            { label: 'TVL', value: protocol.totalValueLocked != null ? `${formatEther(protocol.totalValueLocked)} OKB` : '0' },
          ].map((item, i) => (
            <motion.div
              key={item.label}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.7 + i * 0.05 }}
            >
              <Card className="text-center">
                <CardContent className="pt-6">
                  <p className="text-2xl font-bold font-mono">{item.value}</p>
                  <p className="text-xs text-muted-foreground mt-1">{item.label}</p>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      </motion.section>
    </div>
  );
}
