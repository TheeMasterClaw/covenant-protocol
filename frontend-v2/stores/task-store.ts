import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export interface Task {
  id: number;
  title: string;
  description: string;
  reward: string;
  bids: number;
  priority: 'High' | 'Medium' | 'Low';
  deadline: string;
  skills: string[];
  poster: string;
  posted: string;
  status: 'open' | 'in_progress' | 'completed' | 'cancelled';
  progress?: number;
  assignee?: string;
}

interface TaskState {
  tasks: Task[];
  myTasks: Task[];
  myBids: { id: number; title: string; myBid: string; status: string; totalBids: number }[];
  selectedTask: Task | null;
  activeTab: 'browse' | 'myTasks' | 'myBids';
  searchQuery: string;
  skillFilter: string;
  priceFilter: string;
  setTasks: (tasks: Task[]) => void;
  addTask: (task: Task) => void;
  selectTask: (task: Task | null) => void;
  setActiveTab: (tab: 'browse' | 'myTasks' | 'myBids') => void;
  setSearchQuery: (query: string) => void;
  setSkillFilter: (filter: string) => void;
  setPriceFilter: (filter: string) => void;
}

export const useTaskStore = create<TaskState>()(
  persist(
    (set) => ({
      tasks: [],
      myTasks: [],
      myBids: [],
      selectedTask: null,
      activeTab: 'browse',
      searchQuery: '',
      skillFilter: 'All',
      priceFilter: 'Any',
      setTasks: (tasks) => set({ tasks }),
      addTask: (task) => set((state) => ({ tasks: [...state.tasks, task] })),
      selectTask: (task) => set({ selectedTask: task }),
      setActiveTab: (activeTab) => set({ activeTab }),
      setSearchQuery: (searchQuery) => set({ searchQuery }),
      setSkillFilter: (skillFilter) => set({ skillFilter }),
      setPriceFilter: (priceFilter) => set({ priceFilter }),
    }),
    {
      name: 'task-store',
    }
  )
);
