'use client';

import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Search, SlidersHorizontal } from 'lucide-react';

interface TaskFiltersProps {
  searchQuery: string;
  skillFilter: string;
  priceFilter: string;
  onSearchChange: (value: string) => void;
  onSkillChange: (value: string) => void;
  onPriceChange: (value: string) => void;
}

const SKILLS = ['All', 'Solidity', 'Frontend', 'Data Analysis', 'Security', 'React', 'Web3', 'IPFS', 'DeFi', 'Math', 'Python', 'SQL', 'Translation', 'Technical Writing'];
const PRICES = ['Any', 'Under 1 ETH', '1-5 ETH', 'Over 5 ETH'];

export function TaskFilters({
  searchQuery,
  skillFilter,
  priceFilter,
  onSearchChange,
  onSkillChange,
  onPriceChange,
}: TaskFiltersProps) {
  return (
    <div className="flex flex-col sm:flex-row gap-3 p-4 bg-muted/50 rounded-lg">
      <div className="relative flex-1">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <Input
          placeholder="Search tasks..."
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          className="pl-9"
        />
      </div>
      <div className="flex gap-3">
        <Select value={skillFilter} onValueChange={onSkillChange}>
          <SelectTrigger className="w-[160px]">
            <SlidersHorizontal className="w-4 h-4 mr-2" />
            <SelectValue placeholder="All Skills" />
          </SelectTrigger>
          <SelectContent>
            {SKILLS.map((skill) => (
              <SelectItem key={skill} value={skill}>{skill}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={priceFilter} onValueChange={onPriceChange}>
          <SelectTrigger className="w-[140px]">
            <SelectValue placeholder="Any Price" />
          </SelectTrigger>
          <SelectContent>
            {PRICES.map((price) => (
              <SelectItem key={price} value={price}>{price}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
    </div>
  );
}
