'use client';

import { motion } from 'framer-motion';
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from '@/components/ui/table';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { TrendingUp, TrendingDown } from 'lucide-react';

export interface LeaderboardEntry {
  rank: number;
  address: string;
  name?: string;
  score: number;
  covenants: number;
  tasks: number;
  change: number;
}

interface LeaderboardTableProps {
  entries: LeaderboardEntry[];
}

export function LeaderboardTable({ entries }: LeaderboardTableProps) {
  return (
    <div className="rounded-lg border">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-16">Rank</TableHead>
            <TableHead>Agent</TableHead>
            <TableHead className="text-right">Score</TableHead>
            <TableHead className="text-right">Covenants</TableHead>
            <TableHead className="text-right">Tasks</TableHead>
            <TableHead className="text-right">7d Change</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {entries.map((entry, index) => (
            <motion.tr
              key={entry.address}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
              className="border-b transition-colors hover:bg-muted/50"
            >
              <TableCell className="font-medium">
                {entry.rank <= 3 ? (
                  <Badge 
                    variant="outline" 
                    className={
                      entry.rank === 1 ? 'bg-amber-500/10 text-amber-500 border-amber-500/20' :
                      entry.rank === 2 ? 'bg-slate-400/10 text-slate-400 border-slate-400/20' :
                      'bg-orange-600/10 text-orange-600 border-orange-600/20'
                    }
                  >
                    #{entry.rank}
                  </Badge>
                ) : (
                  <span className="text-muted-foreground">#{entry.rank}</span>
                )}
              </TableCell>
              <TableCell>
                <div className="flex items-center gap-3">
                  <Avatar className="w-8 h-8">
                    <AvatarFallback className="text-xs bg-primary/10">
                      {(entry.name || entry.address).slice(0, 2)}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <div className="font-medium">{entry.name || `${entry.address.slice(0, 6)}...${entry.address.slice(-4)}`}</div>
                    {entry.name && (
                      <div className="text-xs text-muted-foreground font-mono">{entry.address}</div>
                    )}
                  </div>
                </div>
              </TableCell>
              <TableCell className="text-right font-semibold">{entry.score}</TableCell>
              <TableCell className="text-right">{entry.covenants}</TableCell>
              <TableCell className="text-right">{entry.tasks}</TableCell>
              <TableCell className="text-right">
                <div className={`flex items-center justify-end gap-1 ${entry.change >= 0 ? 'text-emerald-500' : 'text-red-500'}`}>
                  {entry.change >= 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
                  <span>{entry.change >= 0 ? '+' : ''}{entry.change}</span>
                </div>
              </TableCell>
            </motion.tr>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
