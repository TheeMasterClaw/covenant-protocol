'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Coins, TrendingUp, Clock, Shield, Info } from 'lucide-react';

interface StakingPanelProps {
  totalStaked: string;
  pendingRewards: string;
  apr: number;
}

export function StakingPanel({ totalStaked, pendingRewards, apr }: StakingPanelProps) {
  const [stakeAmount, setStakeAmount] = useState('');
  const [isStaking, setIsStaking] = useState(false);

  const handleStake = async () => {
    setIsStaking(true);
    await new Promise(r => setTimeout(r, 1500));
    setIsStaking(false);
    setStakeAmount('');
  };

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
        >
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                  <Coins className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Total Staked</p>
                  <p className="text-xl font-bold">{totalStaked} ETH</p>
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
                <div className="w-10 h-10 rounded-full bg-emerald-500/10 flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-emerald-500" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Pending Rewards</p>
                  <p className="text-xl font-bold">{pendingRewards} ETH</p>
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
                <div className="w-10 h-10 rounded-full bg-amber-500/10 flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-amber-500" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">APR</p>
                  <p className="text-xl font-bold">{apr}%</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Stake Action */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg flex items-center gap-2">
            <Shield className="w-5 h-5" />
            Stake ETH
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Stake ETH to increase your reputation weight and earn passive rewards from platform fees.
          </p>
          <div className="flex gap-3">
            <Input
              type="number"
              step="0.1"
              placeholder="Amount to stake"
              value={stakeAmount}
              onChange={(e) => setStakeAmount(e.target.value)}
            />
            <Button 
              onClick={handleStake}
              disabled={!stakeAmount || isStaking}
            >
              {isStaking ? 'Staking...' : 'Stake'}
            </Button>
          </div>
          
          <div className="p-4 bg-muted/50 rounded-lg space-y-2">
            <div className="flex items-start gap-2">
              <Info className="w-4 h-4 text-muted-foreground mt-0.5" />
              <div className="text-sm text-muted-foreground">
                <p className="font-medium text-foreground">Staking Benefits:</p>
                <ul className="list-disc list-inside mt-1 space-y-1">
                  <li>Higher reputation weight in disputes</li>
                  <li>Increased visibility in agent discovery</li>
                  <li>Priority access to high-value covenants</li>
                  <li>Earn passive rewards from platform fees</li>
                </ul>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Clock className="w-4 h-4" />
            <span>7-day cooldown period for withdrawals</span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
