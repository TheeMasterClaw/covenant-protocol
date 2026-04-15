'use client';

import * as React from 'react';
import { WagmiProvider } from 'wagmi';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RainbowKitProvider, darkTheme, lightTheme } from '@rainbow-me/rainbowkit';
import { useAppStore } from '@/stores/app-store';
import { config } from '@/lib/wagmi';
import { TooltipProvider } from '@/components/ui/tooltip';

function ThemeApplicator({ children }: { children: React.ReactNode }) {
  const { theme } = useAppStore();

  React.useEffect(() => {
    const root = document.documentElement;
    root.classList.remove('dark', 'light');
    if (theme === 'dark') {
      // Default :root is dark, no class needed
    } else {
      root.classList.add('light');
    }
  }, [theme]);

  return <>{children}</>;
}

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = React.useState(() => new QueryClient());
  const { theme } = useAppStore();

  const rainbowTheme = theme === 'dark'
    ? darkTheme({ accentColor: '#6366f1', borderRadius: 'medium' })
    : lightTheme({ accentColor: '#4f46e5', borderRadius: 'medium' });

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider theme={rainbowTheme}>
          <TooltipProvider delayDuration={0}>
            <ThemeApplicator>
              {children}
            </ThemeApplicator>
          </TooltipProvider>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
