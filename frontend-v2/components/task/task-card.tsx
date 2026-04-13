'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Task } from '@/stores/task-store';
import { Briefcase, Clock, Coins, Users, Zap } from 'lucide-react';

interface TaskCardProps {
  task: Task;
  index?: number;
  onView?: (task: Task) => void;
  onBid?: (task: Task) => void;
  variant?: 'default' | 'compact' | 'list';
}

export function TaskCard({ task, index = 0, onView, onBid, variant = 'default' }: TaskCardProps) {
  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'High': return 'bg-red-500/10 text-red-500 border-red-500/20';
      case 'Medium': return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'Low': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      default: return 'bg-slate-500/10 text-slate-500 border-slate-500/20';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'open': return 'bg-emerald-500/10 text-emerald-500';
      case 'in_progress': return 'bg-amber-500/10 text-amber-500';
      case 'completed': return 'bg-blue-500/10 text-blue-500';
      default: return 'bg-slate-500/10 text-slate-500';
    }
  };

  if (variant === 'compact') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: index * 0.1 }}
      >
        <Card className="hover:border-primary/50 transition-colors cursor-pointer" onClick={() => onView?.(task)}>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                  <Briefcase className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <h4 className="font-medium text-sm">{task.title}</h4>
                  <p className="text-xs text-muted-foreground">{task.reward} ETH</p>
                </div>
              </div>
              <Badge className={getPriorityColor(task.priority)}>{task.priority}</Badge>
            </div>
          </CardContent>
        </Card>
      </motion.div>
    );
  }

  if (variant === 'list') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: index * 0.1 }}
        className="group"
      >
        <div 
          className="flex items-center gap-4 p-4 border rounded-lg hover:border-primary/50 transition-colors cursor-pointer bg-card"
          onClick={() => onView?.(task)}
        >
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <h4 className="font-medium truncate">{task.title}</h4>
              <Badge className={getPriorityColor(task.priority)}>{task.priority}</Badge>
            </div>
            <p className="text-sm text-muted-foreground line-clamp-1">{task.description}</p>
            <div className="flex gap-2 mt-2">
              {task.skills.map((skill, i) => (
                <Badge key={i} variant="outline" className="text-xs">{skill}</Badge>
              ))}
            </div>
          </div>
          <div className="text-right min-w-[100px]">
            <div className="font-semibold">{task.reward} ETH</div>
            <div className="text-sm text-muted-foreground">{task.bids} bids</div>
          </div>
          <Button size="sm" onClick={(e) => { e.stopPropagation(); onBid?.(task); }}>
            Bid
          </Button>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: index * 0.1 }}
      whileHover={{ y: -4 }}
    >
      <Card className="overflow-hidden hover:shadow-lg transition-all duration-300 h-full flex flex-col">
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <Badge className={getPriorityColor(task.priority)}>{task.priority}</Badge>
            {task.status !== 'open' && (
              <Badge className={getStatusColor(task.status)}>{task.status}</Badge>
            )}
          </div>
          <h3 className="font-semibold mt-2">{task.title}</h3>
          <p className="text-sm text-muted-foreground line-clamp-2">{task.description}</p>
        </CardHeader>
        <CardContent className="flex-1 flex flex-col">
          <div className="flex flex-wrap gap-2 mb-4">
            {task.skills.slice(0, 3).map((skill, i) => (
              <Badge key={i} variant="outline" className="text-xs">{skill}</Badge>
            ))}
            {task.skills.length > 3 && (
              <Badge variant="outline" className="text-xs">+{task.skills.length - 3}</Badge>
            )}
          </div>

          <div className="mt-auto space-y-3">
            {task.progress !== undefined && (
              <div>
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-muted-foreground">Progress</span>
                  <span>{task.progress}%</span>
                </div>
                <Progress value={task.progress} className="h-2" />
              </div>
            )}

            <div className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
              <div className="flex items-center gap-2">
                <Coins className="w-4 h-4 text-primary" />
                <span className="font-semibold">{task.reward} ETH</span>
              </div>
              <div className="flex items-center gap-2 text-sm text-muted-foreground">
                <Users className="w-4 h-4" />
                <span>{task.bids} bids</span>
              </div>
            </div>

            <div className="flex items-center gap-2 text-xs text-muted-foreground">
              <Clock className="w-3 h-3" />
              <span>Due {task.deadline}</span>
              <span>•</span>
              <span>Posted {task.posted}</span>
            </div>

            <div className="flex gap-2 pt-2">
              <Button variant="outline" size="sm" className="flex-1" onClick={() => onView?.(task)}>
                View
              </Button>
              {task.status === 'open' && (
                <Button size="sm" className="flex-1" onClick={() => onBid?.(task)}>
                  <Zap className="w-4 h-4 mr-1" />
                  Bid
                </Button>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
