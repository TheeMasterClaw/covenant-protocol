'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Covenant } from '@/stores/covenant-store';
import { FileText, Users, ArrowRight, Shield } from 'lucide-react';

interface CovenantCardProps {
  covenant: Covenant;
  index?: number;
  onView?: (covenant: Covenant) => void;
  onTestLoyalty?: (covenant: Covenant) => void;
  compact?: boolean;
}

export function CovenantCard({ covenant, index = 0, onView, onTestLoyalty, compact = false }: CovenantCardProps) {
  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Active': return 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20';
      case 'Pending': return 'bg-amber-500/10 text-amber-500 border-amber-500/20';
      case 'Disputed': return 'bg-red-500/10 text-red-500 border-red-500/20';
      case 'Completed': return 'bg-blue-500/10 text-blue-500 border-blue-500/20';
      default: return 'bg-slate-500/10 text-slate-500 border-slate-500/20';
    }
  };

  const getLoyaltyBadge = () => {
    if (covenant.status === 'Disputed') return { label: 'Oathbreaker', class: 'bg-red-500/10 text-red-500 border-red-500/20' };
    if (covenant.status === 'Pending') return { label: 'Questionable', class: 'bg-amber-500/10 text-amber-500 border-amber-500/20' };
    if (covenant.progress < 30) return { label: 'Suspicious', class: 'bg-orange-500/10 text-orange-500 border-orange-500/20' };
    return { label: 'Faithful', class: 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20' };
  };

  const loyalty = getLoyaltyBadge();

  if (compact) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: index * 0.1 }}
      >
        <Card className="hover:border-primary/50 transition-colors cursor-pointer group" onClick={() => onView?.(covenant)}>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                  <FileText className="w-5 h-5 text-primary" />
                </div>
                <div>
                  <h4 className="font-medium text-sm">{covenant.title}</h4>
                  <p className="text-xs text-muted-foreground">#{covenant.id}</p>
                </div>
              </div>
              <Badge className={getStatusColor(covenant.status)}>{covenant.status}</Badge>
            </div>
          </CardContent>
        </Card>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: index * 0.1 }}
    >
      <Card className="overflow-hidden hover:shadow-lg transition-all duration-300 group">
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center">
                <FileText className="w-6 h-6 text-primary" />
              </div>
              <div>
                <h3 className="font-semibold">{covenant.title}</h3>
                <p className="text-sm text-muted-foreground">Covenant #{covenant.id}</p>
              </div>
            </div>
            <div className="flex flex-col items-end gap-2">
              <Badge className={getStatusColor(covenant.status)}>{covenant.status}</Badge>
              <Badge variant="outline" className={loyalty.class}>{loyalty.label}</Badge>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-4 text-sm">
            <div className="flex items-center gap-2">
              <Users className="w-4 h-4 text-muted-foreground" />
              <span>{covenant.initiator}</span>
              <ArrowRight className="w-3 h-3 text-muted-foreground" />
              <span>{covenant.counterparty}</span>
            </div>
          </div>

          <div className="flex items-center justify-between p-3 bg-muted/50 rounded-lg">
            <div>
              <p className="text-xs text-muted-foreground">Amount</p>
              <p className="font-semibold">{covenant.amount} ETH</p>
            </div>
            {covenant.progress > 0 && (
              <div className="flex-1 mx-4">
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-muted-foreground">Progress</span>
                  <span>{covenant.progress}%</span>
                </div>
                <Progress value={covenant.progress} className="h-2" />
              </div>
            )}
          </div>

          {covenant.milestones.length > 0 && (
            <div className="flex gap-2">
              {covenant.milestones.slice(0, 3).map((m, i) => (
                <div
                  key={i}
                  className={`w-3 h-3 rounded-full ${
                    m.status === 'completed' ? 'bg-emerald-500' :
                    m.status === 'in_progress' ? 'bg-amber-500' : 'bg-slate-300'
                  }`}
                  title={m.title}
                />
              ))}
              {covenant.milestones.length > 3 && (
                <span className="text-xs text-muted-foreground">+{covenant.milestones.length - 3}</span>
              )}
            </div>
          )}

          <div className="flex gap-2 pt-2">
            <Button variant="outline" size="sm" className="flex-1" onClick={() => onView?.(covenant)}>
              View
            </Button>
            {onTestLoyalty && covenant.status !== 'Completed' && (
              <Button 
                size="sm" 
                variant="secondary"
                className="gap-2"
                onClick={() => onTestLoyalty(covenant)}
              >
                <Shield className="w-4 h-4" />
                Test Loyalty
              </Button>
            )}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
