'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Star, TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface ScoreCardProps {
  score: number;
  rank: string;
  previousScore?: number;
}

export function ScoreCard({ score, rank, previousScore }: ScoreCardProps) {
  const change = previousScore ? score - previousScore : 0;
  const percentage = Math.min((score / 1000) * 100, 100);

  const getRankColor = (rank: string) => {
    switch (rank.toLowerCase()) {
      case 'elite': return 'bg-purple-500/10 text-purple-500 border-purple-500/20';
      case 'expert': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      case 'advanced': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20';
      case 'novice': return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      default: return 'bg-slate-500/10 text-slate-500 border-slate-500/20';
    }
  };

  return (
    <Card>
      <CardHeader className="pb-2">
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg flex items-center gap-2">
            <Star className="w-5 h-5 text-amber-500" />
            Reputation Score
          </CardTitle>
          <Badge className={getRankColor(rank)}>{rank}</Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="flex items-center gap-6">
          <motion.div
            className="relative w-28 h-28"
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', stiffness: 200, damping: 15 }}
          >
            <svg className="w-full h-full -rotate-90" viewBox="0 0 100 100">
              <circle
                cx="50"
                cy="50"
                r="42"
                fill="none"
                stroke="currentColor"
                strokeWidth="8"
                className="text-muted/20"
              />
              <motion.circle
                cx="50"
                cy="50"
                r="42"
                fill="none"
                stroke="currentColor"
                strokeWidth="8"
                strokeLinecap="round"
                strokeDasharray={`${percentage * 2.64} 264`}
                className="text-primary"
                initial={{ strokeDasharray: '0 264' }}
                animate={{ strokeDasharray: `${percentage * 2.64} 264` }}
                transition={{ duration: 1, delay: 0.5 }}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <motion.span
                className="text-3xl font-bold"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.8 }}
              >
                {score}
              </motion.span>
              <span className="text-xs text-muted-foreground">/ 1000</span>
            </div>
          </motion.div>

          <div className="flex-1 space-y-3">
            <div>
              <div className="flex items-center gap-2 mb-1">
                {change > 0 ? (
                  <TrendingUp className="w-4 h-4 text-emerald-500" />
                ) : change < 0 ? (
                  <TrendingDown className="w-4 h-4 text-red-500" />
                ) : (
                  <Minus className="w-4 h-4 text-slate-400" />
                )}
                <span className={`text-sm ${change > 0 ? 'text-emerald-500' : change < 0 ? 'text-red-500' : 'text-slate-400'}`}>
                  {change > 0 ? '+' : ''}{change} this week
                </span>
              </div>
              <Progress value={percentage} className="h-2" />
            </div>
            <p className="text-sm text-muted-foreground">
              {percentage >= 80 ? 'Excellent standing in the protocol' :
               percentage >= 60 ? 'Good reputation, keep it up' :
               percentage >= 40 ? 'Building reputation steadily' :
               'New to the protocol, gain more experience'}
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
