'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Button } from '@/components/ui/button';
import { ThumbsUp, ThumbsDown, Minus } from 'lucide-react';

interface VoteButtonsProps {
  onVote: (vote: 'for' | 'against' | 'abstain') => void;
  disabled?: boolean;
}

export function VoteButtons({ onVote, disabled = false }: VoteButtonsProps) {
  const [selected, setSelected] = useState<'for' | 'against' | 'abstain' | null>(null);

  const handleVote = (vote: 'for' | 'against' | 'abstain') => {
    setSelected(vote);
    onVote(vote);
  };

  return (
    <div className="flex gap-2">
      <Button
        variant={selected === 'for' ? 'default' : 'outline'}
        size="sm"
        className={`flex-1 gap-2 ${
          selected === 'for' 
            ? 'bg-emerald-500 hover:bg-emerald-600' 
            : 'border-emerald-500/30 hover:bg-emerald-500/10 hover:text-emerald-500'
        }`}
        onClick={() => handleVote('for')}
        disabled={disabled}
      >
        <ThumbsUp className="w-4 h-4" />
        For
      </Button>
      <Button
        variant={selected === 'against' ? 'default' : 'outline'}
        size="sm"
        className={`flex-1 gap-2 ${
          selected === 'against' 
            ? 'bg-red-500 hover:bg-red-600' 
            : 'border-red-500/30 hover:bg-red-500/10 hover:text-red-500'
        }`}
        onClick={() => handleVote('against')}
        disabled={disabled}
      >
        <ThumbsDown className="w-4 h-4" />
        Against
      </Button>
      <Button
        variant={selected === 'abstain' ? 'default' : 'outline'}
        size="sm"
        className={`flex-1 gap-2 ${
          selected === 'abstain' 
            ? 'bg-slate-500 hover:bg-slate-600' 
            : 'border-slate-500/30 hover:bg-slate-500/10 hover:text-slate-500'
        }`}
        onClick={() => handleVote('abstain')}
        disabled={disabled}
      >
        <Minus className="w-4 h-4" />
        Abstain
      </Button>
    </div>
  );
}
