import { AppSidebar } from '@/components/layout/app-sidebar';
import { AppHeader } from '@/components/layout/app-header';
import { cn } from '@/lib/utils';
import { useAppStore } from '@/stores/app-store';

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-background">
      <AppSidebar />
      <div className={cn(
        "transition-all duration-300 lg:ml-64",
      )}>
        <AppHeader />
        <main className="p-4 lg:p-8">
          {children}
        </main>
      </div>
    </div>
  );
}
