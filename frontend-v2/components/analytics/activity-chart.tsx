'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { BarChart3, TrendingUp } from 'lucide-react';

interface DataPoint {
  label: string;
  value: number;
  previousValue?: number;
}

interface ActivityChartProps {
  title: string;
  data: DataPoint[];
  color?: string;
}

export function ActivityChart({ title, data, color = 'var(--primary)' }: ActivityChartProps) {
  const [period, setPeriod] = useState<'7d' | '30d' | '90d'>('30d');
  const maxValue = Math.max(...data.map(d => d.value));

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-lg flex items-center gap-2">
            <BarChart3 className="w-5 h-5" />
            {title}
          </CardTitle>
          <div className="flex gap-1">
            {(['7d', '30d', '90d'] as const).map((p) => (
              <Button
                key={p}
                variant={period === p ? 'default' : 'ghost'}
                size="sm"
                onClick={() => setPeriod(p)}
              >
                {p}
              </Button>
            ))}
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="h-64 flex items-end gap-2">
          {data.map((point, index) => {
            const height = (point.value / maxValue) * 100;
            const previousHeight = point.previousValue ? (point.previousValue / maxValue) * 100 : 0;
            const change = point.previousValue ? ((point.value - point.previousValue) / point.previousValue) * 100 : 0;

            return (
              <motion.div
                key={point.label}
                className="flex-1 flex flex-col items-center gap-2"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: index * 0.05 }}
              >
                <div className="relative w-full flex-1 flex items-end">
                  {/* Previous value line */}
                  {point.previousValue && (
                    <div 
                      className="absolute w-full border-t-2 border-dashed border-muted-foreground/30"
                      style={{ bottom: `${previousHeight}%` }}
                    />
                  )}
                  {/* Bar */}
                  <motion.div
                    className="w-full rounded-t-md transition-all hover:opacity-80"
                    style={{ 
                      backgroundColor: color,
                      opacity: 0.8,
                    }}
                    initial={{ height: 0 }}
                    animate={{ height: `${height}%` }}
                    transition={{ duration: 0.5, delay: index * 0.05 }}
                  />
                  {/* Value tooltip */}
                  <div className="absolute -top-8 left-1/2 -translate-x-1/2 opacity-0 hover:opacity-100 transition-opacity">
                    <Badge variant="secondary">{point.value}</Badge>
                  </div>
                </div>
                <span className="text-xs text-muted-foreground">{point.label}</span>
              </motion.div>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}
