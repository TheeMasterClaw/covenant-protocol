'use client';

import Link from 'next/link';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { Button } from '@/components/ui/button';
import { useAppStore } from '@/stores/app-store';
import { NetworkSwitcher } from '@/components/layout/network-switcher';
import { Menu, Hexagon, Moon, Sun } from 'lucide-react';

export function AppHeader() {
  const { sidebarOpen, toggleSidebar, theme, setTheme } = useAppStore();

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 px-4 lg:px-8">
      <div className="flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={toggleSidebar} className="lg:hidden">
          <Menu className="w-5 h-5" />
        </Button>
        <Link href="/" className="lg:hidden flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
            <Hexagon className="w-5 h-5 text-primary-foreground" />
          </div>
          <span className="font-bold">COVENANT</span>
        </Link>
      </div>

      <div className="flex items-center gap-3">
        <NetworkSwitcher />
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
          className="hidden sm:flex"
        >
          {theme === 'dark' ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
        </Button>
        <ConnectButton 
          showBalance={false}
          chainStatus="icon"
          accountStatus="address"
        />
      </div>
    </header>
  );
}
