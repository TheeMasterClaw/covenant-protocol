'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Dispute } from '@/stores/dispute-store';
import { Scale, Clock, Users, ChevronRight, Gavel } from 'lucide-react';

interface DisputeCardProps {
  dispute: Dispute;
  index?: number;
  onView?: (dispute: Dispute) => void;
  variant?: 'active' | 'jury' | 'resolved';
}

export function DisputeCard({ dispute, index = 0, onView, variant = 'active' }: DisputeCardProps) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'voting': return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'evidence': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      case 'resolved': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20';
      default: return 'bg-slate-500/10 text-slate-500 border-slate-500/20';
    }
  };

  const totalVotes = (dispute.votesFor || 0) + (dispute.votesAgainst || 0);
  const forPercentage = totalVotes > 0 ? ((dispute.votesFor || 0) / totalVotes) * 100 : 50;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: index * 0.1 }}
      whileHover={{ scale: 1.01 }}
    >
      <Card 
        className="cursor-pointer hover:shadow-md transition-all overflow-hidden"
        onClick={() => onView?.(dispute)}
      >
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-amber-500/20 to-amber-500/5 flex items-center justify-center">
                <Scale className="w-6 h-6 text-amber-500" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground font-mono">{dispute.id}</p>
                <h3 className="font-semibold">{dispute.title}</h3>
              </div>
            </div>
            <Badge className={getStatusColor(dispute.status)}>{dispute.status}</Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-2 text-sm">
            <Users className="w-4 h-4 text-muted-foreground" />
            <span className="text-muted-foreground">{dispute.parties[0]}</span>
            <span className="text-muted-foreground">vs</span>
            <span className="text-muted-foreground">{dispute.parties[1]}</span>
          </div>

          {dispute.reason && (
            <p className="text-sm text-muted-foreground bg-muted/50 p-2 rounded">
              {dispute.reason}
            </p>
          )}

          {dispute.resolution && (
            <p className="text-sm text-muted-foreground bg-muted/50 p-2 rounded">
              {dispute.resolution}
            </p>
          )}

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2 text-sm">
                <Gavel className="w-4 h-4 text-primary" />
                <span className="font-semibold">{dispute.amount} ETH</span>
              </div>
              {dispute.timeRemaining && (
                <div className="flex items-center gap-2 text-sm text-muted-foreground">
                  <Clock className="w-4 h-4" />
                  <span>{dispute.timeRemaining} left</span>
                </div>
              )}
            </div>
            <Button variant="ghost" size="sm" className="gap-1">
              View <ChevronRight className="w-4 h-4" />
            </Button>
          </div>

          {dispute.status === 'voting' && totalVotes > 0 && (
            <div>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-emerald-500">For: {dispute.votesFor}</span>
                <span className="text-red-500">Against: {dispute.votesAgainst}</span>
              </div>
              <div className="h-2 bg-red-500/20 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-emerald-500 transition-all"
                  style={{ width: `${forPercentage}%` }}
                />
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </motion.div>
  );
}
