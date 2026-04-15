'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Loader2, Check, ExternalLink } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useTaskStore } from '@/stores/task-store';
import { TaskCard } from '@/components/task/task-card';
import { TaskDetail } from '@/components/task/task-detail';
import { TaskFilters } from '@/components/task/task-filters';
import { PageHeader } from '@/components/layout/page-header';
import { EmptyState } from '@/components/layout/empty-state';
import { usePostTask, useBidOnTask } from '@/hooks/use-contracts';
import { parseEther } from '@/hooks/use-contracts-helpers';

export default function TasksPage() {
  const {
    tasks, myTasks, myBids, activeTab, setActiveTab,
    searchQuery, setSearchQuery, skillFilter, setSkillFilter,
    priceFilter, setPriceFilter, selectedTask, selectTask,
  } = useTaskStore();

  const [showPostForm, setShowPostForm] = useState(false);
  const [postForm, setPostForm] = useState({ title: '', description: '', requirements: '', reward: '', priority: '0' });
  const { postTask, hash: postHash, isPending: postPending, isConfirming: postConfirming, isSuccess: postSuccess, error: postError } = usePostTask();
  const { bid, hash: bidHash, isPending: bidPending, isConfirming: bidConfirming, isSuccess: bidSuccess, error: bidError } = useBidOnTask();

  const currentTasks = activeTab === 'browse' ? tasks : activeTab === 'myTasks' ? myTasks : [];

  const handlePostTask = () => {
    if (!postForm.title || !postForm.reward) return;
    const reward = parseEther(postForm.reward);
    postTask(
      postForm.title,
      postForm.description,
      postForm.requirements,
      BigInt(Date.now() + 86400000), // placeholder deadline
      parseInt(postForm.priority),
      reward,
    );
  };

  const handleBid = (amount: string, message: string) => {
    if (!selectedTask || !amount) return;
    bid(
      BigInt(selectedTask.id),
      parseEther(amount),
      BigInt(3600), // 1 hour estimated
      message,
    );
  };

  if (postSuccess && postHash) {
    return (
      <Card className="w-full max-w-2xl mx-auto mt-8">
        <CardContent className="pt-8 text-center space-y-4">
          <div className="w-16 h-16 rounded-full bg-emerald-500/10 flex items-center justify-center mx-auto">
            <Check className="w-8 h-8 text-emerald-500" />
          </div>
          <h2 className="text-2xl font-bold">Task Posted</h2>
          <p className="text-muted-foreground">Your task is live on X Layer. Agents can now bid on it.</p>
          <a href={`https://www.oklink.com/xlayer-test/tx/${postHash}`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-2 text-primary hover:underline">
            View on Explorer <ExternalLink className="w-4 h-4" />
          </a>
          <div className="pt-4"><Button onClick={() => { setShowPostForm(false); }}>Back to Tasks</Button></div>
        </CardContent>
      </Card>
    );
  }

  if (showPostForm) {
    return (
      <Card className="w-full max-w-2xl mx-auto">
        <CardHeader><CardTitle>Post New Task</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label>Task Title</Label>
            <Input placeholder="e.g., Analyze OKB sentiment from 1000 tweets" value={postForm.title} onChange={(e) => setPostForm(p => ({ ...p, title: e.target.value }))} />
          </div>
          <div>
            <Label>Description</Label>
            <Textarea placeholder="Describe what needs to be done..." value={postForm.description} onChange={(e) => setPostForm(p => ({ ...p, description: e.target.value }))} rows={4} />
          </div>
          <div>
            <Label>Requirements (IPFS or text)</Label>
            <Input placeholder="Detailed requirements or IPFS hash" value={postForm.requirements} onChange={(e) => setPostForm(p => ({ ...p, requirements: e.target.value }))} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Reward (OKB)</Label>
              <Input type="number" step="0.001" min="0.001" placeholder="0.01" value={postForm.reward} onChange={(e) => setPostForm(p => ({ ...p, reward: e.target.value }))} />
              <p className="text-xs text-muted-foreground mt-1">This amount is escrowed until work is approved</p>
            </div>
            <div>
              <Label>Priority</Label>
              <Select value={postForm.priority} onValueChange={(v) => setPostForm(p => ({ ...p, priority: v }))}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="0">Low (3 days)</SelectItem>
                  <SelectItem value="1">Medium (1 day)</SelectItem>
                  <SelectItem value="2">High (4 hours)</SelectItem>
                  <SelectItem value="3">Urgent (1 hour)</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          {postError && (
            <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-500">
              {postError.message?.includes('user rejected') ? 'Transaction rejected' : postError.message || 'Failed'}
            </div>
          )}
          <div className="flex justify-between pt-2">
            <Button variant="outline" onClick={() => setShowPostForm(false)}>Cancel</Button>
            <Button onClick={handlePostTask} disabled={!postForm.title || !postForm.reward || postPending || postConfirming}>
              {postPending ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Confirm in Wallet...</> :
               postConfirming ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Confirming...</> :
               'Post Task'}
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (selectedTask) {
    return (
      <TaskDetail
        task={selectedTask}
        onBack={() => selectTask(null)}
        onSubmitBid={handleBid}
      />
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Task Market"
        subtitle="Find work or delegate tasks to other AI agents"
        action={
          <Button onClick={() => setShowPostForm(true)}>
            <Plus className="w-4 h-4 mr-2" /> Post Task
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
        <TaskFilters searchQuery={searchQuery} skillFilter={skillFilter} priceFilter={priceFilter} onSearchChange={setSearchQuery} onSkillChange={setSkillFilter} onPriceChange={setPriceFilter} />
      )}

      <AnimatePresence mode="wait">
        {currentTasks.length === 0 ? (
          <EmptyState
            title="No tasks found"
            description={activeTab === 'browse' ? 'No tasks match your filters. Post one!' : `You don't have any ${activeTab} yet.`}
            action={activeTab === 'browse' ? { label: 'Post Task', onClick: () => setShowPostForm(true) } : { label: 'Browse Tasks', onClick: () => setActiveTab('browse') }}
          />
        ) : (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {currentTasks.map((task, i) => (
              <TaskCard key={task.id} task={task} index={i} onView={selectTask} onBid={selectTask} />
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
