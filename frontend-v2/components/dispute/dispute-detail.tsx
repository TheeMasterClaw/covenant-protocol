'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { Dispute } from '@/stores/dispute-store';
import { ArrowLeft, Scale, Users, Coins, Clock, FileText, Gavel } from 'lucide-react';

interface DisputeDetailProps {
  dispute: Dispute;
  isJuror?: boolean;
  onBack?: () => void;
  onVote?: (vote: 'for' | 'against') => void;
}

export function DisputeDetail({ dispute, isJuror, onBack, onVote }: DisputeDetailProps) {
  const totalVotes = (dispute.votesFor || 0) + (dispute.votesAgainst || 0);
  const forPercentage = totalVotes > 0 ? ((dispute.votesFor || 0) / totalVotes) * 100 : 50;

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'voting': return 'bg-amber-500/10 text-amber-500';
      case 'evidence': return 'bg-blue-500/10 text-blue-500';
      case 'resolved': return 'bg-emerald-500/10 text-emerald-500';
      default: return 'bg-slate-500/10 text-slate-500';
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="space-y-6"
    >
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="sm" onClick={onBack} className="gap-2">
          <ArrowLeft className="w-4 h-4" />
          Back
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <Badge className="mb-2 font-mono">{dispute.id}</Badge>
              <CardTitle className="text-2xl">{dispute.title}</CardTitle>
            </div>
            <Badge className={getStatusColor(dispute.status)}>{dispute.status}</Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Parties */}
          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 bg-muted/50 rounded-lg text-center">
              <p className="text-xs text-muted-foreground mb-2">Claimant</p>
              <p className="font-semibold">{dispute.parties[0]}</p>
            </div>
            <div className="p-4 bg-muted/50 rounded-lg text-center">
              <p className="text-xs text-muted-foreground mb-2">Respondent</p>
              <p className="font-semibold">{dispute.parties[1]}</p>
            </div>
          </div>

          {/* Meta */}
          <div className="grid grid-cols-3 gap-4">
            <div className="flex items-center gap-3 p-3 bg-muted/50 rounded-lg">
              <Coins className="w-5 h-5 text-primary" />
              <div>
                <p className="text-xs text-muted-foreground">Amount at Stake</p>
                <p className="font-semibold">{dispute.amount} ETH</p>
              </div>
            </div>
            <div className="flex items-center gap-3 p-3 bg-muted/50 rounded-lg">
              <Scale className="w-5 h-5 text-primary" />
              <div>
                <p className="text-xs text-muted-foreground">Covenant</p>
                <p className="font-semibold">#{dispute.covenantId}</p>
              </div>
            </div>
            {dispute.timeRemaining && (
              <div className="flex items-center gap-3 p-3 bg-muted/50 rounded-lg">
                <Clock className="w-5 h-5 text-primary" />
                <div>
                  <p className="text-xs text-muted-foreground">Time Remaining</p>
                  <p className="font-semibold">{dispute.timeRemaining}</p>
                </div>
              </div>
            )}
          </div>

          <Separator />

          {/* Reason */}
          {dispute.reason && (
            <div>
              <h4 className="font-medium mb-2">Dispute Reason</h4>
              <p className="text-muted-foreground p-4 bg-muted/50 rounded-lg">{dispute.reason}</p>
            </div>
          )}

          {/* Resolution */}
          {dispute.resolution && (
            <div>
              <h4 className="font-medium mb-2">Resolution</h4>
              <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-lg">
                <p className="text-emerald-700 dark:text-emerald-300">{dispute.resolution}</p>
                {dispute.winner && (
                  <p className="text-sm text-emerald-600 dark:text-emerald-400 mt-2">
                    Winner: {dispute.winner}
                  </p>
                )}
              </div>
            </div>
          )}

          {/* Voting */}
          {dispute.status === 'voting' && totalVotes > 0 && (
            <div>
              <h4 className="font-medium mb-4">Current Vote Tally</h4>
              <div className="space-y-4">
                <div>
                  <div className="flex justify-between text-sm mb-1">
                    <span>For Claimant: {dispute.votesFor}</span>
                    <span>{forPercentage.toFixed(1)}%</span>
                  </div>
                  <div className="h-3 bg-emerald-500/20 rounded-full overflow-hidden">
                    <div className="h-full bg-emerald-500" style={{ width: `${forPercentage}%` }} />
                  </div>
                </div>
                <div>
                  <div className="flex justify-between text-sm mb-1">
                    <span>For Respondent: {dispute.votesAgainst}</span>
                    <span>{(100 - forPercentage).toFixed(1)}%</span>
                  </div>
                  <div className="h-3 bg-red-500/20 rounded-full overflow-hidden">
                    <div className="h-full bg-red-500" style={{ width: `${100 - forPercentage}%` }} />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Juror Actions */}
          {isJuror && dispute.status === 'voting' && onVote && (
            <div className="p-4 border rounded-lg space-y-4">
              <h4 className="font-medium flex items-center gap-2">
                <Gavel className="w-4 h-4" />
                Cast Your Vote
              </h4>
              <p className="text-sm text-muted-foreground">
                You have staked {dispute.staked} REP tokens on this dispute
              </p>
              <div className="flex gap-3">
                <Button 
                  variant="outline" 
                  className="flex-1 border-emerald-500/50 hover:bg-emerald-500/10"
                  onClick={() => onVote('for')}
                >
                  Vote for Claimant
                </Button>
                <Button 
                  variant="outline" 
                  className="flex-1 border-red-500/50 hover:bg-red-500/10"
                  onClick={() => onVote('against')}
                >
                  Vote for Respondent
                </Button>
              </div>
            </div>
          )}

          {/* Evidence */}
          {dispute.evidence && dispute.evidence.length > 0 && (
            <div>
              <h4 className="font-medium mb-3">Evidence</h4>
              <div className="space-y-2">
                {dispute.evidence.map((item, i) => (
                  <div key={i} className="flex items-center gap-3 p-3 bg-muted/50 rounded-lg">
                    <FileText className="w-5 h-5 text-primary" />
                    <span className="flex-1">{item}</span>
                    <Button variant="ghost" size="sm">View</Button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </motion.div>
  );
}
