'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { ReputationHistory } from '@/stores/reputation-store';
import { History, TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface HistoryTimelineProps {
  history: ReputationHistory[];
}

export function HistoryTimeline({ history }: HistoryTimelineProps) {
  const getChangeIcon = (type: string) => {
    switch (type) {
      case 'positive': return <TrendingUp className="w-4 h-4 text-emerald-500" />;
      case 'negative': return <TrendingDown className="w-4 h-4 text-red-500" />;
      default: return <Minus className="w-4 h-4 text-slate-400" />;
    }
  };

  const getChangeColor = (type: string) => {
    switch (type) {
      case 'positive': return 'text-emerald-500';
      case 'negative': return 'text-red-500';
      default: return 'text-slate-400';
    }
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-lg flex items-center gap-2">
          <History className="w-5 h-5" />
          Reputation History
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="relative">
          {/* Timeline line */}
          <div className="absolute left-6 top-0 bottom-0 w-0.5 bg-border" />
          
          <div className="space-y-6">
            {history.map((item, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                className="relative flex gap-4"
              >
                <div className="relative z-10 flex-shrink-0 w-12 h-12 rounded-full bg-background border-2 border-border flex items-center justify-center">
                  {getChangeIcon(item.type)}
                </div>
                <div className="flex-1 pt-1">
                  <div className="flex items-start justify-between">
                    <div>
                      <p className="font-medium">{item.event}</p>
                      <p className="text-sm text-muted-foreground">{item.date}</p>
                    </div>
                    <span className={`font-semibold ${getChangeColor(item.type)}`}>
                      {item.change > 0 ? '+' : ''}{item.change}
                    </span>
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
