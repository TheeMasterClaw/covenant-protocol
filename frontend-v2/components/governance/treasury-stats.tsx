'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { 
  Wallet, 
  TrendingUp, 
  ArrowUpRight, 
  ArrowDownRight, 
  Coins,
  PieChart,
  Activity
} from 'lucide-react';

interface TreasuryStatsProps {
  totalValue: string;
  monthlyChange: number;
  allocations: {
    category: string;
    amount: string;
    percentage: number;
    color: string;
  }[];
}

export function TreasuryStats({ totalValue, monthlyChange, allocations }: TreasuryStatsProps) {
  return (
    <div className="space-y-6">
      {/* Main Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
        >
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center">
                  <Wallet className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Treasury Balance</p>
                  <p className="text-2xl font-bold">{totalValue} ETH</p>
                  <div className={`flex items-center gap-1 text-sm ${monthlyChange >= 0 ? 'text-emerald-500' : 'text-red-500'}`}>
                    {monthlyChange >= 0 ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
                    <span>{Math.abs(monthlyChange)}% this month</span>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-emerald-500/10 flex items-center justify-center">
                  <TrendingUp className="w-6 h-6 text-emerald-500" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Revenue (30d)</p>
                  <p className="text-2xl font-bold">142.5 ETH</p>
                  <p className="text-sm text-muted-foreground">From protocol fees</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
        >
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-full bg-amber-500/10 flex items-center justify-center">
                  <Activity className="w-6 h-6 text-amber-500" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Expenses (30d)</p>
                  <p className="text-2xl font-bold">89.2 ETH</p>
                  <p className="text-sm text-muted-foreground">Grants & operations</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Allocations */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <PieChart className="w-5 h-5" />
            Treasury Allocation
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {allocations.map((allocation, index) => (
              <motion.div
                key={allocation.category}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.1 * index }}
                className="space-y-2"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div 
                      className="w-3 h-3 rounded-full"
                      style={{ backgroundColor: allocation.color }}
                    />
                    <span className="font-medium">{allocation.category}</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-muted-foreground">{allocation.amount} ETH</span>
                    <Badge variant="outline">{allocation.percentage}%</Badge>
                  </div>
                </div>
                <Progress 
                  value={allocation.percentage} 
                  className="h-2"
                  style={{ 
                    backgroundColor: `${allocation.color}20`,
                  }}
                />
              </motion.div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
