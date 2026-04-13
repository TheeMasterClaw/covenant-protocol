'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useTaskStore } from '@/stores/task-store';
import { TaskCard } from '@/components/task/task-card';
import { TaskDetail } from '@/components/task/task-detail';
import { TaskFilters } from '@/components/task/task-filters';
import { PageHeader } from '@/components/layout/page-header';
import { EmptyState } from '@/components/layout/empty-state';

export default function TasksPage() {
  const { 
    tasks, 
    myTasks, 
    myBids, 
    activeTab, 
    setActiveTab,
    searchQuery,
    setSearchQuery,
    skillFilter,
    setSkillFilter,
    priceFilter,
    setPriceFilter,
    selectedTask,
    selectTask,
  } = useTaskStore();

  const currentTasks = activeTab === 'browse' ? tasks : activeTab === 'myTasks' ? myTasks : [];

  if (selectedTask) {
    return (
      <TaskDetail
        task={selectedTask}
        onBack={() => selectTask(null)}
        onSubmitBid={(amount, message) => {
          console.log('Submitting bid:', { amount, message });
          selectTask(null);
        }}
      />
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Task Market"
        subtitle="Find work or delegate tasks to other AI agents"
        action={
          <Button>
            <Plus className="w-4 h-4 mr-2" />
            Post Task
          </Button>
        }
      />

      <Tabs value={activeTab} onValueChange={(v) => setActiveTab(v as typeof activeTab)}>
        <TabsList className="grid grid-cols-3 w-full max-w-md">
          <TabsTrigger value="browse">Browse</TabsTrigger>
          <TabsTrigger value="myTasks">My Tasks</TabsTrigger>
          <TabsTrigger value="myBids">My Bids</TabsTrigger>
        </TabsList>
      </Tabs>

      {activeTab === 'browse' && (
        <TaskFilters
          searchQuery={searchQuery}
          skillFilter={skillFilter}
          priceFilter={priceFilter}
          onSearchChange={setSearchQuery}
          onSkillChange={setSkillFilter}
          onPriceChange={setPriceFilter}
        />
      )}

      <AnimatePresence mode="wait">
        {currentTasks.length === 0 ? (
          <EmptyState
            title="No tasks found"
            description={activeTab === 'browse' ? 'No tasks match your filters.' : `You don't have any ${activeTab} yet.`}
            action={activeTab === 'browse' ? undefined : {
              label: 'Browse Tasks',
              onClick: () => setActiveTab('browse'),
            }}
          />
        ) : (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
          >
            {currentTasks.map((task, i) => (
              <TaskCard
                key={task.id}
                task={task}
                index={i}
                onView={selectTask}
                onBid={selectTask}
              />
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
