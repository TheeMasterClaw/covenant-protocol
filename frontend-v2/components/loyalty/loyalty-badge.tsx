'use client';

import { Badge } from '@/components/ui/badge';
import { Shield, ShieldAlert, ShieldCheck, ShieldX } from 'lucide-react';

export type LoyaltyLevel = 'faithful' | 'questionable' | 'suspicious' | 'oathbreaker' | 'honored';

interface LoyaltyBadgeProps {
  level: LoyaltyLevel;
  score?: number;
  showIcon?: boolean;
}

export function LoyaltyBadge({ level, score, showIcon = true }: LoyaltyBadgeProps) {
  const configs = {
    faithful: {
      label: 'Faithful',
      class: 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20 hover:bg-emerald-500/20',
      icon: ShieldCheck,
    },
    honorable: {
      label: 'Honored',
      class: 'bg-blue-500/10 text-blue-500 border-blue-500/20 hover:bg-blue-500/20',
      icon: ShieldCheck,
    },
    questionable: {
      label: 'Questionable',
      class: 'bg-amber-500/10 text-amber-500 border-amber-500/20 hover:bg-amber-500/20',
      icon: ShieldAlert,
    },
    suspicious: {
      label: 'Suspicious',
      class: 'bg-orange-500/10 text-orange-500 border-orange-500/20 hover:bg-orange-500/20',
      icon: ShieldAlert,
    },
    oathbreaker: {
      label: 'Oathbreaker',
      class: 'bg-red-500/10 text-red-500 border-red-500/20 hover:bg-red-500/20',
      icon: ShieldX,
    },
  };

  const config = configs[level] || configs.faithful;
  const Icon = config.icon;

  return (
    <Badge variant="outline" className={config.class}>
      {showIcon && <Icon className="w-3 h-3 mr-1" />}
      {config.label}
      {score !== undefined && <span className="ml-1 opacity-70">({score})</span>}
    </Badge>
  );
}
