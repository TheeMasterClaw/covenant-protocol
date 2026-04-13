'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Separator } from '@/components/ui/separator';
import { Task } from '@/stores/task-store';
import { ArrowLeft, Calendar, Coins, User, CheckCircle, MessageSquare, Clock, Briefcase } from 'lucide-react';

interface TaskDetailProps {
  task: Task;
  onBack?: () => void;
  onSubmitBid?: (amount: string, message: string) => void;
}

export function TaskDetail({ task, onBack, onSubmitBid }: TaskDetailProps) {
  const [bidAmount, setBidAmount] = useState('');
  const [bidMessage, setBidMessage] = useState('');

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'High': return 'bg-red-500/10 text-red-500 border-red-500/20';
      case 'Medium': return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'Low': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      default: return 'bg-slate-500/10 text-slate-500 border-slate-500/20';
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
              <div className="flex items-center gap-2 mb-2">
                <Badge className={getPriorityColor(task.priority)}>{task.priority} Priority</Badge>
                {task.status !== 'open' && (
                  <Badge variant="outline">{task.status}</Badge>
                )}
              </div>
              <CardTitle className="text-2xl">{task.title}</CardTitle>
              <p className="text-sm text-muted-foreground mt-1">
                Posted by {task.poster} • {task.posted}
              </p>
            </div>
            <div className="text-right">
              <div className="text-2xl font-bold text-primary">{task.reward} ETH</div>
              <div className="text-sm text-muted-foreground">{task.bids} bids</div>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Description */}
          <div>
            <h4 className="font-medium mb-2 flex items-center gap-2">
              <Briefcase className="w-4 h-4" />
              Description
            </h4>
            <p className="text-muted-foreground leading-relaxed">{task.description}</p>
          </div>

          <Separator />

          {/* Skills */}
          <div>
            <h4 className="font-medium mb-2">Required Skills</h4>
            <div className="flex flex-wrap gap-2">
              {task.skills.map((skill, i) => (
                <Badge key={i} variant="secondary">{skill}</Badge>
              ))}
            </div>
          </div>

          {/* Meta Grid */}
          <div className="grid grid-cols-3 gap-4">
            <div className="flex items-center gap-3 p-4 bg-muted/50 rounded-lg">
              <Coins className="w-5 h-5 text-primary" />
              <div>
                <p className="text-xs text-muted-foreground">Reward</p>
                <p className="font-semibold">{task.reward} ETH</p>
              </div>
            </div>
            <div className="flex items-center gap-3 p-4 bg-muted/50 rounded-lg">
              <User className="w-5 h-5 text-primary" />
              <div>
                <p className="text-xs text-muted-foreground">Current Bids</p>
                <p className="font-semibold">{task.bids}</p>
              </div>
            </div>
            <div className="flex items-center gap-3 p-4 bg-muted/50 rounded-lg">
              <Calendar className="w-5 h-5 text-primary" />
              <div>
                <p className="text-xs text-muted-foreground">Deadline</p>
                <p className="font-semibold">{task.deadline}</p>
              </div>
            </div>
          </div>

          {/* Bid Form */}
          {task.status === 'open' && onSubmitBid && (
            <div className="p-4 border rounded-lg space-y-4">
              <h4 className="font-medium flex items-center gap-2">
                <MessageSquare className="w-4 h-4" />
                Place Your Bid
              </h4>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-sm text-muted-foreground mb-1 block">Your Bid (ETH)</label>
                  <Input
                    type="number"
                    step="0.01"
                    value={bidAmount}
                    onChange={(e) => setBidAmount(e.target.value)}
                    placeholder={`Suggested: ${(parseFloat(task.reward) * 0.9).toFixed(2)}`}
                  />
                </div>
                <div>
                  <label className="text-sm text-muted-foreground mb-1 block">Message</label>
                  <Textarea
                    value={bidMessage}
                    onChange={(e) => setBidMessage(e.target.value)}
                    placeholder="Explain why you're the best fit..."
                    rows={3}
                  />
                </div>
              </div>
              <Button 
                className="w-full"
                onClick={() => onSubmitBid(bidAmount, bidMessage)}
                disabled={!bidAmount}
              >
                Submit Bid
              </Button>
            </div>
          )}
        </CardContent>
      </Card>
    </motion.div>
  );
}
