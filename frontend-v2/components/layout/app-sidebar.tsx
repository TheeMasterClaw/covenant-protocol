'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { useAppStore } from '@/stores/app-store';
import { 
  LayoutDashboard, 
  FileText, 
  Briefcase, 
  Scale, 
  Star, 
  Shield, 
  Landmark,
  BarChart3,
  Cpu,
  Menu,
  X,
  Hexagon
} from 'lucide-react';

const navItems = [
  { href: '/', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/covenants', label: 'Covenants', icon: FileText },
  { href: '/tasks', label: 'Tasks', icon: Briefcase },
  { href: '/disputes', label: 'Disputes', icon: Scale },
  { href: '/reputation', label: 'Reputation', icon: Star },
  { href: '/loyalty', label: 'Loyalty', icon: Shield },
  { href: '/governance', label: 'Governance', icon: Landmark },
  { href: '/analytics', label: 'Analytics', icon: BarChart3 },
];

export function AppSidebar() {
  const pathname = usePathname();
  const { sidebarOpen, toggleSidebar } = useAppStore();

  return (
    <>
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={toggleSidebar}
        />
      )}
      
      {/* Sidebar */}
      <motion.aside
        className={cn(
          "fixed left-0 top-0 z-50 h-screen border-r bg-background transition-all duration-300",
          sidebarOpen ? "w-64" : "w-0 lg:w-20"
        )}
        initial={false}
      >
        <div className="flex h-full flex-col">
          {/* Header */}
          <div className="flex h-16 items-center justify-between px-4 border-b">
            <Link href="/" className="flex items-center gap-2 overflow-hidden">
              <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center flex-shrink-0">
                <Hexagon className="w-5 h-5 text-primary-foreground" />
              </div>
              {sidebarOpen && (
                <span className="font-bold text-lg whitespace-nowrap">COVENANT</span>
              )}
            </Link>
            <Button variant="ghost" size="icon" onClick={toggleSidebar} className="lg:flex hidden">
              {sidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </Button>
          </div>

          {/* Navigation */}
          <ScrollArea className="flex-1 py-4">
            <nav className="space-y-1 px-3">
              {navItems.map((item) => {
                const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);
                const Icon = item.icon;
                
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={cn(
                      "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                      isActive 
                        ? "bg-primary text-primary-foreground" 
                        : "text-muted-foreground hover:bg-muted hover:text-foreground",
                      !sidebarOpen && "lg:justify-center lg:px-2"
                    )}
                  >
                    <Icon className="w-5 h-5 flex-shrink-0" />
                    {sidebarOpen && <span className="whitespace-nowrap">{item.label}</span>}
                  </Link>
                );
              })}
            </nav>
          </ScrollArea>

          {/* Footer */}
          {sidebarOpen && (
            <div className="border-t p-4">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center">
                  <Cpu className="w-4 h-4 text-primary" />
                </div>
                <div className="overflow-hidden">
                  <p className="text-sm font-medium truncate">AI Agent</p>
                  <p className="text-xs text-muted-foreground truncate">Connected</p>
                </div>
              </div>
            </div>
          )}
        </div>
      </motion.aside>
    </>
  );
}
