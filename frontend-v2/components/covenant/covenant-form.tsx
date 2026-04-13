'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Milestone } from '@/stores/covenant-store';
import { Plus, X, ChevronRight, ChevronLeft, Check } from 'lucide-react';

const STEPS = ['Counterparty', 'Terms', 'Milestones', 'Review'];

const TEMPLATES = [
  { id: 'development', name: 'Development Partnership', description: 'Collaborative development with milestone-based payments', icon: '💻' },
  { id: 'liquidity', name: 'Liquidity Provision', description: 'Joint liquidity provision for DeFi strategies', icon: '💧' },
  { id: 'arbitrage', name: 'Arbitrage Alliance', description: 'Cross-chain arbitrage opportunity sharing', icon: '⚡' },
  { id: 'analysis', name: 'Intelligence Sharing', description: 'Market analysis and signal sharing agreement', icon: '📊' },
  { id: 'custom', name: 'Custom Covenant', description: 'Define your own terms and conditions', icon: '⚙️' },
];

interface CovenantFormProps {
  onSubmit?: (data: any) => void;
  onCancel?: () => void;
}

export function CovenantForm({ onSubmit, onCancel }: CovenantFormProps) {
  const [step, setStep] = useState(0);
  const [formData, setFormData] = useState({
    counterparty: '',
    covenantType: 'development',
    title: '',
    description: '',
    totalValue: '',
    duration: '30',
    milestones: [
      { title: 'Kickoff', description: 'Initial setup and planning', amount: '20', deadline: '7', status: 'pending' as const },
      { title: 'Milestone 1', description: '', amount: '40', deadline: '14', status: 'pending' as const },
      { title: 'Completion', description: 'Final delivery', amount: '40', deadline: '30', status: 'pending' as const },
    ] as Milestone[],
  });

  const updateField = (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const addMilestone = () => {
    setFormData(prev => ({
      ...prev,
      milestones: [...prev.milestones, { title: '', description: '', amount: '0', deadline: '', status: 'pending' }],
    }));
  };

  const removeMilestone = (index: number) => {
    setFormData(prev => ({
      ...prev,
      milestones: prev.milestones.filter((_, i) => i !== index),
    }));
  };

  const updateMilestone = (index: number, field: keyof Milestone, value: string) => {
    setFormData(prev => ({
      ...prev,
      milestones: prev.milestones.map((m, i) => i === index ? { ...m, [field]: value } : m),
    }));
  };

  const totalAmount = formData.milestones.reduce((sum, m) => sum + (parseFloat(m.amount) || 0), 0);
  const isValid = totalAmount === 100;

  const renderStep = () => {
    switch (step) {
      case 0:
        return (
          <div className="space-y-4">
            <div>
              <Label>Counterparty Address</Label>
              <Input
                placeholder="0x..."
                value={formData.counterparty}
                onChange={(e) => updateField('counterparty', e.target.value)}
              />
            </div>
          </div>
        );
      case 1:
        return (
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-4">
              {TEMPLATES.map((template) => (
                <div
                  key={template.id}
                  onClick={() => updateField('covenantType', template.id)}
                  className={`p-4 rounded-lg border cursor-pointer transition-all ${
                    formData.covenantType === template.id
                      ? 'border-primary bg-primary/5'
                      : 'border-border hover:border-primary/50'
                  }`}
                >
                  <div className="text-2xl mb-2">{template.icon}</div>
                  <h4 className="font-medium">{template.name}</h4>
                  <p className="text-xs text-muted-foreground mt-1">{template.description}</p>
                </div>
              ))}
            </div>
            <div className="space-y-4">
              <div>
                <Label>Title</Label>
                <Input
                  placeholder="e.g., Cross-Chain Arbitrage Partnership"
                  value={formData.title}
                  onChange={(e) => updateField('title', e.target.value)}
                />
              </div>
              <div>
                <Label>Description</Label>
                <Textarea
                  placeholder="Describe the covenant terms..."
                  value={formData.description}
                  onChange={(e) => updateField('description', e.target.value)}
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Total Value (ETH)</Label>
                  <Input
                    type="number"
                    step="0.01"
                    placeholder="0.00"
                    value={formData.totalValue}
                    onChange={(e) => updateField('totalValue', e.target.value)}
                  />
                </div>
                <div>
                  <Label>Duration (days)</Label>
                  <Input
                    type="number"
                    value={formData.duration}
                    onChange={(e) => updateField('duration', e.target.value)}
                  />
                </div>
              </div>
            </div>
          </div>
        );
      case 2:
        return (
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-muted/50 rounded-lg">
              <div>
                <span className="text-sm text-muted-foreground">Total Value: </span>
                <span className="font-semibold">{formData.totalValue || '0'} ETH</span>
              </div>
              <div>
                <span className="text-sm text-muted-foreground">Milestone Total: </span>
                <span className={`font-semibold ${!isValid ? 'text-red-500' : ''}`}>
                  {totalAmount}%
                </span>
              </div>
            </div>
            <ScrollArea className="h-[300px]">
              <div className="space-y-4">
                {formData.milestones.map((milestone, index) => (
                  <div key={index} className="p-4 border rounded-lg space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Milestone #{index + 1}</span>
                      {formData.milestones.length > 1 && (
                        <Button variant="ghost" size="sm" onClick={() => removeMilestone(index)}>
                          <X className="w-4 h-4" />
                        </Button>
                      )}
                    </div>
                    <div className="grid grid-cols-3 gap-2">
                      <Input
                        placeholder="Title"
                        value={milestone.title}
                        onChange={(e) => updateMilestone(index, 'title', e.target.value)}
                      />
                      <Input
                        type="number"
                        placeholder="Amount %"
                        value={milestone.amount}
                        onChange={(e) => updateMilestone(index, 'amount', e.target.value)}
                      />
                      <Input
                        type="number"
                        placeholder="Days"
                        value={milestone.deadline}
                        onChange={(e) => updateMilestone(index, 'deadline', e.target.value)}
                      />
                    </div>
                    <Input
                      placeholder="Description"
                      value={milestone.description}
                      onChange={(e) => updateMilestone(index, 'description', e.target.value)}
                    />
                  </div>
                ))}
              </div>
            </ScrollArea>
            <Button variant="outline" onClick={addMilestone} className="w-full">
              <Plus className="w-4 h-4 mr-2" />
              Add Milestone
            </Button>
          </div>
        );
      case 3:
        return (
          <div className="space-y-4">
            <div className="p-4 bg-muted/50 rounded-lg space-y-3">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Type</span>
                <span className="font-medium">{TEMPLATES.find(t => t.id === formData.covenantType)?.name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Title</span>
                <span className="font-medium">{formData.title || 'Untitled'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Counterparty</span>
                <span className="font-medium">{formData.counterparty || 'Not set'}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Value</span>
                <span className="font-medium">{formData.totalValue} ETH</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Duration</span>
                <span className="font-medium">{formData.duration} days</span>
              </div>
            </div>
            <Separator />
            <div>
              <h4 className="font-medium mb-2">Milestones</h4>
              {formData.milestones.map((m, i) => (
                <div key={i} className="flex justify-between py-1 text-sm">
                  <span>{m.title}</span>
                  <span className="text-muted-foreground">{m.amount}%</span>
                </div>
              ))}
            </div>
          </div>
        );
      default:
        return null;
    }
  };

  return (
    <Card className="w-full max-w-2xl mx-auto">
      <CardHeader>
        <CardTitle>Create New Covenant</CardTitle>
        <div className="flex items-center gap-2 mt-4">
          {STEPS.map((s, i) => (
            <div key={s} className="flex items-center">
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center text-sm ${
                  i < step ? 'bg-primary text-primary-foreground' :
                  i === step ? 'bg-primary/20 text-primary border-2 border-primary' :
                  'bg-muted text-muted-foreground'
                }`}
              >
                {i < step ? <Check className="w-4 h-4" /> : i + 1}
              </div>
              {i < STEPS.length - 1 && (
                <div className={`w-8 h-0.5 ${i < step ? 'bg-primary' : 'bg-muted'}`} />
              )}
            </div>
          ))}
        </div>
      </CardHeader>
      <CardContent>
        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            {renderStep()}
          </motion.div>
        </AnimatePresence>

        <div className="flex justify-between mt-6">
          <Button variant="outline" onClick={onCancel}>
            Cancel
          </Button>
          <div className="flex gap-2">
            {step > 0 && (
              <Button variant="outline" onClick={() => setStep(step - 1)}>
                <ChevronLeft className="w-4 h-4 mr-2" />
                Back
              </Button>
            )}
            {step < STEPS.length - 1 ? (
              <Button onClick={() => setStep(step + 1)}>
                Next
                <ChevronRight className="w-4 h-4 ml-2" />
              </Button>
            ) : (
              <Button onClick={() => onSubmit?.(formData)} disabled={!isValid}>
                Create Covenant
              </Button>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
