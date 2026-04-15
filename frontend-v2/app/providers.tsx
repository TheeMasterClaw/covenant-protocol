'use client';

import * as React from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { cookieToInitialState, WagmiProvider, type Config } from 'wagmi';
import { createAppKit } from '@reown/appkit/react';
import { wagmiAdapter, projectId, networks, xLayerTestnet } from '@/lib/wagmi';
import { useAppStore } from '@/stores/app-store';
import { TooltipProvider } from '@/components/ui/tooltip';

// Initialize AppKit
const appKit = createAppKit({
  adapters: [wagmiAdapter],
  projectId,
  networks,
  defaultNetwork: xLayerTestnet,
  metadata: {
    name: 'COVENANT Protocol',
    description: 'The Legal Layer for the AI Agent Economy',
    url: typeof window !== 'undefined' ? window.location.origin : 'https://covenant-protocol.vercel.app',
    icons: [],
  },
  features: {
    analytics: false,
  },
  themeMode: 'dark',
  themeVariables: {
    '--w3m-accent': 'oklch(0.65 0.2 250)',
    '--w3m-color-mix': 'oklch(0.07 0.01 260)',
    '--w3m-color-mix-strength': 40,
    '--w3m-border-radius-master': '2px',
  },
});

function ThemeApplicator({ children }: { children: React.ReactNode }) {
  const { theme } = useAppStore();

  React.useEffect(() => {
    const root = document.documentElement;
    root.classList.remove('dark', 'light');
    if (theme !== 'dark') {
      root.classList.add('light');
    }
    // Sync AppKit theme with app theme
    appKit.setThemeMode(theme === 'dark' ? 'dark' : 'light');
  }, [theme]);

  return <>{children}</>;
}

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = React.useState(() => new QueryClient());

  const initialState = typeof document !== 'undefined'
    ? cookieToInitialState(wagmiAdapter.wagmiConfig as Config)
    : undefined;

  return (
    <WagmiProvider config={wagmiAdapter.wagmiConfig as Config} initialState={initialState}>
      <QueryClientProvider client={queryClient}>
        <TooltipProvider delayDuration={0}>
          <ThemeApplicator>
            {children}
          </ThemeApplicator>
        </TooltipProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
