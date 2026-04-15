'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { useStake, useTokenApprove, useTokenBalance } from '@/hooks/use-contracts';
import { parseEther } from '@/hooks/use-contracts-helpers';
import { useAccount } from 'wagmi';
import { CONTRACTS } from '@/lib/contracts';
import { Coins, TrendingUp, Clock, Shield, Info, Loader2, Check, ExternalLink } from 'lucide-react';

interface StakingPanelProps {
  totalStaked: string;
  pendingRewards: string;
  apr: number;
}

export function StakingPanel({ totalStaked, pendingRewards, apr }: StakingPanelProps) {
  const [stakeAmount, setStakeAmount] = useState('');
  const [needsApproval, setNeedsApproval] = useState(true);
  const { address } = useAccount();
  const { balance } = useTokenBalance(address);
  const { approve, hash: approveHash, isPending: approvePending, isConfirming: approveConfirming, isSuccess: approveSuccess } = useTokenApprove();
  const { stake, hash: stakeHash, isPending: stakePending, isConfirming: stakeConfirming, isSuccess: stakeSuccess, error: stakeError } = useStake();

  const handleApprove = () => {
    if (!stakeAmount) return;
    approve(CONTRACTS.ReputationStake.address as `0x${string}`, parseEther(stakeAmount));
    setNeedsApproval(false);
  };

  const handleStake = () => {
    if (!stakeAmount) return;
    stake(parseEther(stakeAmount));
  };

  const isProcessing = approvePending || approveConfirming || stakePending || stakeConfirming;

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }}>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                  <Coins className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Total Staked</p>
                  <p className="text-xl font-bold">{totalStaked} COV</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.2 }}>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-emerald-500/10 flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-emerald-500" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">COV Balance</p>
                  <p className="text-xl font-bold">{balance != null ? (Number(balance) / 1e18).toFixed(2) : '--'}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }}>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-amber-500/10 flex items-center justify-center">
                  <TrendingUp className="w-5 h-5 text-amber-500" />
                </div>
                <div>
                  <p className="text-sm text-muted-foreground">Pending Rewards</p>
                  <p className="text-xl font-bold">{pendingRewards} COV</p>
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
            Stake COV Tokens
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">
            Stake COV to increase your reputation score. Higher reputation unlocks higher-value tasks and covenants.
          </p>

          {stakeSuccess && stakeHash ? (
            <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-center space-y-2">
              <Check className="w-6 h-6 text-emerald-500 mx-auto" />
              <p className="text-sm font-medium">Staked successfully!</p>
              <a href={`https://www.oklink.com/xlayer-test/tx/${stakeHash}`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-xs text-primary hover:underline">
                View TX <ExternalLink className="w-3 h-3" />
              </a>
            </div>
          ) : (
            <div className="flex gap-3">
              <Input
                type="number"
                step="1"
                min="1"
                placeholder="Amount of COV to stake"
                value={stakeAmount}
                onChange={(e) => { setStakeAmount(e.target.value); setNeedsApproval(true); }}
              />
              {needsApproval && !approveSuccess ? (
                <Button onClick={handleApprove} disabled={!stakeAmount || isProcessing}>
                  {approvePending ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Approving...</> :
                   approveConfirming ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Confirming...</> :
                   'Approve'}
                </Button>
              ) : (
                <Button onClick={handleStake} disabled={!stakeAmount || isProcessing}>
                  {stakePending ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Staking...</> :
                   stakeConfirming ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Confirming...</> :
                   'Stake'}
                </Button>
              )}
            </div>
          )}

          {stakeError && (
            <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-500">
              {stakeError.message?.includes('user rejected') ? 'Transaction rejected' : stakeError.message || 'Staking failed'}
            </div>
          )}

          <div className="p-4 bg-muted/50 rounded-lg space-y-2">
            <div className="flex items-start gap-2">
              <Info className="w-4 h-4 text-muted-foreground mt-0.5" />
              <div className="text-sm text-muted-foreground">
                <p className="font-medium text-foreground">Staking Benefits:</p>
                <ul className="list-disc list-inside mt-1 space-y-1">
                  <li>Higher reputation weight in disputes</li>
                  <li>Increased visibility in agent discovery</li>
                  <li>Priority access to high-value covenants</li>
                  <li>10% slash protection on first breach</li>
                </ul>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 text-sm text-muted-foreground">
            <Clock className="w-4 h-4" />
            <span>7-day lock period for withdrawals</span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
