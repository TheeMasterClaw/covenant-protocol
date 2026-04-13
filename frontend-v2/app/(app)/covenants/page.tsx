'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useCovenantStore } from '@/stores/covenant-store';
import { CovenantCard } from '@/components/covenant/covenant-card';
import { CovenantDetail } from '@/components/covenant/covenant-detail';
import { CovenantForm } from '@/components/covenant/covenant-form';
import { PageHeader } from '@/components/layout/page-header';
import { EmptyState } from '@/components/layout/empty-state';

const tabs = ['all', 'active', 'pending', 'completed', 'disputed'] as const;

export default function CovenantsPage() {
  const { covenants, filter, setFilter, selectedCovenant, selectCovenant } = useCovenantStore();
  const [showForm, setShowForm] = useState(false);

  const filteredCovenants = covenants.filter(c => 
    filter === 'all' ? true : c.status.toLowerCase() === filter
  );

  if (showForm) {
    return (
      <CovenantForm 
        onSubmit={(data) => {
          console.log('Creating covenant:', data);
          setShowForm(false);
        }}
        onCancel={() => setShowForm(false)}
      />
    );
  }

  if (selectedCovenant) {
    return (
      <CovenantDetail
        covenant={selectedCovenant}
        onBack={() => selectCovenant(null)}
        onUpdateProgress={() => console.log('Update progress')}
        onTestLoyalty={() => console.log('Test loyalty')}
      />
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Covenants"
        subtitle="Manage your active and pending covenant agreements"
        action={
          <Button onClick={() => setShowForm(true)}>
            <Plus className="w-4 h-4 mr-2" />
            Create Covenant
          </Button>
        }
      />

      <Tabs value={filter} onValueChange={(v) => setFilter(v as typeof filter)}>
        <TabsList className="grid grid-cols-5 w-full max-w-md">
          {tabs.map((tab) => (
            <TabsTrigger key={tab} value={tab} className="capitalize">
              {tab}
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>

      <AnimatePresence mode="wait">
        {filteredCovenants.length === 0 ? (
          <EmptyState
            title="No covenants found"
            description={`You don't have any ${filter} covenants yet.`}
            action={{
              label: 'Create Covenant',
              onClick: () => setShowForm(true),
            }}
          />
        ) : (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
          >
            {filteredCovenants.map((covenant, i) => (
              <CovenantCard
                key={covenant.id}
                covenant={covenant}
                index={i}
                onView={selectCovenant}
              />
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
