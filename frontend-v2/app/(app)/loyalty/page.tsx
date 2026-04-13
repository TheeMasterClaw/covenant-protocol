'use client';

import { motion } from 'framer-motion';
import { useCovenantStore } from '@/stores/covenant-store';
import { PageHeader } from '@/components/layout/page-header';
import { LoyaltyBadge } from '@/components/loyalty/loyalty-badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { Shield, ShieldCheck, ShieldAlert, ShieldX } from 'lucide-react';

export default function LoyaltyPage() {
  const { covenants } = useCovenantStore();

  const getLoyaltyLevel = (covenant: typeof covenants[0]): import('@/components/loyalty/loyalty-badge').LoyaltyLevel => {
    if (covenant.status === 'Disputed') return 'oathbreaker';
    if (covenant.status === 'Pending') return 'questionable';
    if (covenant.progress < 30) return 'suspicious';
    if (covenant.status === 'Completed') return 'faithful';
    return 'faithful';
  };

  const getScore = (covenant: typeof covenants[0]) => {
    if (covenant.status === 'Disputed') return 25;
    if (covenant.status === 'Pending') return 72;
    if (covenant.progress < 30) return 55;
    if (covenant.status === 'Completed') return 100;
    return 85;
  };

  const distribution = {
    faithful: covenants.filter(c => getLoyaltyLevel(c) === 'faithful').length,
    questionable: covenants.filter(c => getLoyaltyLevel(c) === 'questionable').length,
    suspicious: covenants.filter(c => getLoyaltyLevel(c) === 'suspicious').length,
    oathbreaker: covenants.filter(c => getLoyaltyLevel(c) === 'oathbreaker').length,
  };

  const total = covenants.length;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Vow Loyalty Center"
        subtitle="Test covenant fidelity and detect breaches automatically"
      />

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Faithful', count: distribution.faithful, icon: ShieldCheck, color: 'text-emerald-500' },
          { label: 'Questionable', count: distribution.questionable, icon: ShieldAlert, color: 'text-amber-500' },
          { label: 'Suspicious', count: distribution.suspicious, icon: ShieldAlert, color: 'text-orange-500' },
          { label: 'Oathbreaker', count: distribution.oathbreaker, icon: ShieldX, color: 'text-red-500' },
        ].map((item, i) => (
          <motion.div
            key={item.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.1 }}
          >
            <Card>
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-3xl font-bold">{item.count}</p>
                    <p className="text-sm text-muted-foreground">{item.label}</p>
                  </div>
                  <div className={`w-12 h-12 rounded-full bg-muted flex items-center justify-center ${item.color}`}>
                    <item.icon className="w-6 h-6" />
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </div>

      {/* Distribution */}
      <Card>
        <CardHeader>
          <CardTitle>Loyalty Distribution</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {[
            { label: 'Faithful', count: distribution.faithful, color: 'bg-emerald-500' },
            { label: 'Questionable', count: distribution.questionable, color: 'bg-amber-500' },
            { label: 'Suspicious', count: distribution.suspicious, color: 'bg-orange-500' },
            { label: 'Oathbreaker', count: distribution.oathbreaker, color: 'bg-red-500' },
          ].map((item) => (
            <div key={item.label} className="space-y-1">
              <div className="flex justify-between text-sm">
                <span>{item.label}</span>
                <span className="text-muted-foreground">
                  {total > 0 ? Math.round((item.count / total) * 100) : 0}%
                </span>
              </div>
              <div className="h-2 bg-muted rounded-full overflow-hidden">
                <div 
                  className={`h-full ${item.color} transition-all`}
                  style={{ width: `${total > 0 ? (item.count / total) * 100 : 0}%` }}
                />
              </div>
            </div>
          ))}
        </CardContent>
      </Card>

      {/* Covenant List */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">All Covenants</h3>
        {covenants.map((covenant, i) => {
          const level = getLoyaltyLevel(covenant);
          const score = getScore(covenant);

          return (
            <motion.div
              key={covenant.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
            >
              <Card>
                <CardContent className="p-4">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <h4 className="font-semibold">{covenant.title}</h4>
                        <Badge variant="outline">#{covenant.id}</Badge>
                      </div>
                      <p className="text-sm text-muted-foreground">{covenant.amount} ETH • {covenant.status}</p>
                    </div>
                    <div className="flex items-center gap-3">
                      <LoyaltyBadge level={level} />
                      <Badge 
                        className={
                          score >= 70 ? 'bg-emerald-500/10 text-emerald-500' :
                          score >= 40 ? 'bg-amber-500/10 text-amber-500' :
                          'bg-red-500/10 text-red-500'
                        }
                      >
                        Score: {score}
                      </Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
