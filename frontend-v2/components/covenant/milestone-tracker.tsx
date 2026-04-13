'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Milestone } from '@/stores/covenant-store';
import { CheckCircle, Clock, Circle, AlertCircle } from 'lucide-react';

interface MilestoneTrackerProps {
  milestones: Milestone[];
  covenantId: number;
}

export function MilestoneTracker({ milestones, covenantId }: MilestoneTrackerProps) {
  const completedCount = milestones.filter(m => m.status === 'completed').length;
  const progress = milestones.length > 0 ? (completedCount / milestones.length) * 100 : 0;

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-5 h-5 text-emerald-500" />;
      case 'in_progress':
        return <Clock className="w-5 h-5 text-amber-500" />;
      case 'pending':
        return <Circle className="w-5 h-5 text-slate-400" />;
      default:
        return <AlertCircle className="w-5 h-5 text-red-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20';
      case 'in_progress':
        return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'pending':
        return 'bg-slate-500/10 text-slate-500 border-slate-500/20';
      default:
        return 'bg-red-500/10 text-red-500 border-red-500/20';
    }
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg">Milestones</CardTitle>
          <Badge variant="outline">
            {completedCount}/{milestones.length} Completed
          </Badge>
        </div>
        <Progress value={progress} className="h-2" />
      </CardHeader>
      <CardContent>
        <div className="relative">
          {/* Timeline line */}
          <div className="absolute left-6 top-0 bottom-0 w-0.5 bg-border" />
          
          <div className="space-y-6">
            {milestones.map((milestone, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                className="relative flex gap-4"
              >
                <div className="relative z-10 flex-shrink-0 w-12 h-12 rounded-full bg-background border-2 border-border flex items-center justify-center">
                  {getStatusIcon(milestone.status)}
                </div>
                <div className="flex-1 pt-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h4 className="font-medium">{milestone.title}</h4>
                    <Badge className={getStatusColor(milestone.status)}>
                      {milestone.status.replace('_', ' ')}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground mb-2">
                    {milestone.description}
                  </p>
                  <div className="flex gap-4 text-xs text-muted-foreground">
                    <span>Amount: {milestone.amount}%</span>
                    <span>Deadline: Day {milestone.deadline}</span>
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
