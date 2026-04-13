'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { ScrollText, Users, Clock, ThumbsUp, ThumbsDown } from 'lucide-react';

export interface Proposal {
  id: string;
  title: string;
  description: string;
  status: 'active' | 'passed' | 'rejected' | 'pending';
  votesFor: number;
  votesAgainst: number;
  totalVotes: number;
  quorum: number;
  deadline: string;
  proposer: string;
  category: string;
}

interface ProposalCardProps {
  proposal: Proposal;
  index?: number;
  onVote?: (proposalId: string, vote: 'for' | 'against') => void;
  onView?: (proposal: Proposal) => void;
}

export function ProposalCard({ proposal, index = 0, onVote, onView }: ProposalCardProps) {
  const forPercentage = proposal.totalVotes > 0 
    ? (proposal.votesFor / proposal.totalVotes) * 100 
    : 0;
  const quorumPercentage = (proposal.totalVotes / proposal.quorum) * 100;

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20';
      case 'passed': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      case 'rejected': return 'bg-red-500/10 text-red-500 border-red-500/20';
      case 'pending': return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      default: return 'bg-slate-500/10 text-slate-500 border-slate-500/20';
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: index * 0.1 }}
    >
      <Card className="hover:shadow-md transition-all">
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                <ScrollText className="w-5 h-5 text-primary" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <Badge variant="outline" className="font-mono text-xs">{proposal.id}</Badge>
                  <Badge className={getStatusColor(proposal.status)}>{proposal.status}</Badge>
                </div>
                <h3 className="font-semibold mt-1">{proposal.title}</h3>
              </div>
            </div>
            <Badge variant="secondary">{proposal.category}</Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground line-clamp-2">{proposal.description}</p>
          
          <div className="flex items-center gap-4 text-sm text-muted-foreground">
            <div className="flex items-center gap-1">
              <Users className="w-4 h-4" />
              <span>{proposal.proposer.slice(0, 6)}...</span>
            </div>
            <div className="flex items-center gap-1">
              <Clock className="w-4 h-4" />
              <span>{proposal.deadline}</span>
            </div>
          </div>

          {proposal.status === 'active' && (
            <>
              <div className="space-y-2">
                <div className="flex justify-between text-xs">
                  <span className="text-emerald-500">For: {proposal.votesFor}</span>
                  <span className="text-red-500">Against: {proposal.votesAgainst}</span>
                </div>
                <div className="h-2 bg-red-500/20 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-emerald-500 transition-all"
                    style={{ width: `${forPercentage}%` }}
                  />
                </div>
              </div>

              <div className="flex gap-2">
                <Button 
                  variant="outline" 
                  size="sm" 
                  className="flex-1 border-emerald-500/30 hover:bg-emerald-500/10"
                  onClick={() => onVote?.(proposal.id, 'for')}
                >
                  <ThumbsUp className="w-4 h-4 mr-2" />
                  For
                </Button>
                <Button 
                  variant="outline" 
                  size="sm" 
                  className="flex-1 border-red-500/30 hover:bg-red-500/10"
                  onClick={() => onVote?.(proposal.id, 'against')}
                >
                  <ThumbsDown className="w-4 h-4 mr-2" />
                  Against
                </Button>
              </div>
            </>
          )}

          <div className="flex justify-between text-xs text-muted-foreground">
            <span>Quorum: {quorumPercentage.toFixed(1)}%</span>
            <Button variant="ghost" size="sm" onClick={() => onView?.(proposal)}>View Details</Button>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
