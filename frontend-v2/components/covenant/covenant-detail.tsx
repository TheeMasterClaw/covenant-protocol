'use client';

import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Separator } from '@/components/ui/separator';
import { Covenant } from '@/stores/covenant-store';
import { ArrowLeft, Calendar, Coins, Users, CheckCircle, Clock, AlertCircle } from 'lucide-react';

interface CovenantDetailProps {
  covenant: Covenant;
  onBack?: () => void;
  onUpdateProgress?: () => void;
  onTestLoyalty?: () => void;
}

export function CovenantDetail({ covenant, onBack, onUpdateProgress, onTestLoyalty }: CovenantDetailProps) {
  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return <CheckCircle className="w-4 h-4 text-emerald-500" />;
      case 'in_progress': return <Clock className="w-4 h-4 text-amber-500" />;
      default: return <AlertCircle className="w-4 h-4 text-slate-400" />;
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
              <p className="text-sm text-muted-foreground mb-1">Covenant #{covenant.id}</p>
              <CardTitle className="text-2xl">{covenant.title}</CardTitle>
            </div>
            <Badge 
              className={
                covenant.status === 'Active' ? 'bg-emerald-500/10 text-emerald-500' :
                covenant.status === 'Pending' ? 'bg-amber-500/10 text-amber-500' :
                covenant.status === 'Disputed' ? 'bg-red-500/10 text-red-500' :
                'bg-blue-500/10 text-blue-500'
              }
            >
              {covenant.status}
            </Badge>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Parties */}
          <div className="grid grid-cols-3 gap-4 p-4 bg-muted/50 rounded-lg">
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Initiator</p>
              <div className="w-10 h-10 rounded-full bg-primary/10 mx-auto mb-2 flex items-center justify-center">
                <span className="font-semibold">{covenant.initiator[0]}</span>
              </div>
              <p className="font-medium text-sm">{covenant.initiator}</p>
            </div>
            <div className="flex items-center justify-center">
              <div className="text-center">
                <Users className="w-6 h-6 text-muted-foreground mx-auto mb-1" />
                <p className="text-xs text-muted-foreground">Partnership</p>
              </div>
            </div>
            <div className="text-center">
              <p className="text-xs text-muted-foreground mb-1">Counterparty</p>
              <div className="w-10 h-10 rounded-full bg-primary/10 mx-auto mb-2 flex items-center justify-center">
                <span className="font-semibold">{covenant.counterparty[0]}</span>
              </div>
              <p className="font-medium text-sm">{covenant.counterparty}</p>
            </div>
          </div>

          {/* Meta Info */}
          <div className="grid grid-cols-3 gap-4">
            <div className="flex items-center gap-3 p-3 bg-muted/30 rounded-lg">
              <Coins className="w-5 h-5 text-primary" />
              <div>
                <p className="text-xs text-muted-foreground">Amount</p>
                <p className="font-semibold">{covenant.amount} ETH</p>
              </div>
            </div>
            {covenant.startDate && (
              <div className="flex items-center gap-3 p-3 bg-muted/30 rounded-lg">
                <Calendar className="w-5 h-5 text-primary" />
                <div>
                  <p className="text-xs text-muted-foreground">Started</p>
                  <p className="font-semibold">{covenant.startDate}</p>
                </div>
              </div>
            )}
            {covenant.endDate && (
              <div className="flex items-center gap-3 p-3 bg-muted/30 rounded-lg">
                <Clock className="w-5 h-5 text-primary" />
                <div>
                  <p className="text-xs text-muted-foreground">Ends</p>
                  <p className="font-semibold">{covenant.endDate}</p>
                </div>
              </div>
            )}
          </div>

          <Separator />

          {/* Progress */}
          {covenant.progress > 0 && (
            <div>
              <div className="flex justify-between mb-2">
                <span className="text-sm font-medium">Progress</span>
                <span className="text-sm text-muted-foreground">{covenant.progress}%</span>
              </div>
              <Progress value={covenant.progress} className="h-3" />
            </div>
          )}

          {/* Milestones */}
          {covenant.milestones.length > 0 && (
            <div>
              <h4 className="font-medium mb-4">Milestones</h4>
              <div className="space-y-3">
                {covenant.milestones.map((milestone, index) => (
                  <div key={index} className="flex items-center gap-4 p-3 bg-muted/30 rounded-lg">
                    <div className="flex-shrink-0">
                      {getStatusIcon(milestone.status)}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between">
                        <p className="font-medium">{milestone.title}</p>
                        <Badge variant="outline">{milestone.amount}%</Badge>
                      </div>
                      <p className="text-sm text-muted-foreground">{milestone.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Actions */}
          <div className="flex gap-3 pt-4">
            <Button variant="outline" onClick={onBack}>Close</Button>
            {covenant.status === 'Active' && (
              <Button onClick={onUpdateProgress}>Update Progress</Button>
            )}
            {onTestLoyalty && covenant.status !== 'Completed' && (
              <Button variant="secondary" onClick={onTestLoyalty}>Test Loyalty</Button>
            )}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}
