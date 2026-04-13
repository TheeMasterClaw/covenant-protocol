import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AppState {
  theme: 'dark' | 'light' | 'system';
  sidebarOpen: boolean;
  network: number | null;
  setTheme: (theme: 'dark' | 'light' | 'system') => void;
  setSidebarOpen: (open: boolean) => void;
  setNetwork: (network: number | null) => void;
  toggleSidebar: () => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      theme: 'dark',
      sidebarOpen: true,
      network: null,
      setTheme: (theme) => set({ theme }),
      setSidebarOpen: (sidebarOpen) => set({ sidebarOpen }),
      setNetwork: (network) => set({ network }),
      toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
    }),
    {
      name: 'covenant-app-store',
    }
  )
);
