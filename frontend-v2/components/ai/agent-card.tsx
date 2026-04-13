'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Progress } from '@/components/ui/progress';
import { Star, Zap, CheckCircle, Cpu } from 'lucide-react';

export interface Agent {
  address: string;
  name?: string;
  reputationScore: number;
  tasksCompleted: number;
  covenantsCompleted: number;
  skills: string[];
  isActive: boolean;
  stakeAmount: string;
  isAI?: boolean;
}

interface AIAgentCardProps {
  agent: Agent;
  index?: number;
  onView?: (agent: Agent) => void;
  onCovenant?: (agent: Agent) => void;
}

export function AIAgentCard({ agent, index = 0, onView, onCovenant }: AIAgentCardProps) {
  const displayName = agent.name || `Agent ${agent.address.slice(0, 6)}`;
  const reputationPercentage = (agent.reputationScore / 1000) * 100;

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.3, delay: index * 0.05 }}
      whileHover={{ y: -4 }}
    >
      <Card className="overflow-hidden hover:shadow-lg transition-all h-full flex flex-col">
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <Avatar className="w-12 h-12 border-2 border-primary/20">
                <AvatarFallback className="bg-gradient-to-br from-primary/20 to-primary/5">
                  <Cpu className="w-6 h-6 text-primary" />
                </AvatarFallback>
              </Avatar>
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="font-semibold">{displayName}</h3>
                  {agent.isAI && (
                    <Badge variant="outline" className="text-xs bg-purple-500/10 text-purple-500 border-purple-500/20">
                      <Zap className="w-3 h-3 mr-1" />
                      AI
                    </Badge>
                  )}
                </div>
                <p className="text-xs text-muted-foreground font-mono">{agent.address}</p>
              </div>
            </div>
            <Badge className={agent.isActive ? 'bg-emerald-500/10 text-emerald-500' : 'bg-slate-500/10 text-slate-500'}>
              {agent.isActive ? 'Active' : 'Inactive'}
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="flex-1 flex flex-col">
          {/* Reputation */}
          <div className="mb-4">
            <div className="flex items-center justify-between text-sm mb-1">
              <span className="text-muted-foreground flex items-center gap-1">
                <Star className="w-4 h-4 text-amber-500" />
                Reputation
              </span>
              <span className="font-semibold">{agent.reputationScore}</span>
            </div>
            <Progress value={reputationPercentage} className="h-2" />
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 gap-3 mb-4">
            <div className="p-2 bg-muted/50 rounded-lg text-center">
              <p className="text-lg font-semibold">{agent.tasksCompleted}</p>
              <p className="text-xs text-muted-foreground">Tasks</p>
            </div>
            <div className="p-2 bg-muted/50 rounded-lg text-center">
              <p className="text-lg font-semibold">{agent.covenantsCompleted}</p>
              <p className="text-xs text-muted-foreground">Covenants</p>
            </div>
          </div>

          {/* Skills */}
          <div className="flex flex-wrap gap-1 mb-4">
            {agent.skills.slice(0, 3).map((skill, i) => (
              <Badge key={i} variant="outline" className="text-xs">{skill}</Badge>
            ))}
            {agent.skills.length > 3 && (
              <Badge variant="outline" className="text-xs">+{agent.skills.length - 3}</Badge>
            )}
          </div>

          {/* Stake */}
          <div className="flex items-center gap-2 p-2 bg-primary/5 rounded-lg mb-4">
            <CheckCircle className="w-4 h-4 text-primary" />
            <span className="text-sm">{agent.stakeAmount} ETH staked</span>
          </div>

          {/* Actions */}
          <div className="flex gap-2 mt-auto">
            <Button variant="outline" size="sm" className="flex-1" onClick={() => onView?.(agent)}>
              Profile
            </Button>
            <Button size="sm" className="flex-1" onClick={() => onCovenant?.(agent)}>
              Covenant
            </Button>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
