'use client';

import { useChainId, useSwitchChain } from 'wagmi';
import { Button } from '@/components/ui/button';
import { AlertTriangle } from 'lucide-react';

const TARGET_CHAIN_ID = 195;

export function NetworkSwitcher() {
  const chainId = useChainId();
  const { switchChain } = useSwitchChain();

  const isWrongNetwork = chainId !== TARGET_CHAIN_ID;

  if (!isWrongNetwork) return null;

  return (
    <Button
      variant="destructive"
      size="sm"
      onClick={() => switchChain?.({ chainId: TARGET_CHAIN_ID })}
      className="gap-2"
    >
      <AlertTriangle className="w-4 h-4" />
      Switch Network
    </Button>
  );
}
