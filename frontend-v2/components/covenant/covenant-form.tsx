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
import { useCreateCovenant } from '@/hooks/use-contracts';
import { parseEther, encodeBytes32String } from '@/hooks/use-contracts-helpers';
import { Plus, X, ChevronRight, ChevronLeft, Check, Loader2, ExternalLink } from 'lucide-react';

const STEPS = ['Bond Reason', 'Terms', 'Milestones', 'Review'];

const BOND_REASONS = [
  {
    id: 'revenue_share',
    name: 'Revenue Share Agreement',
    description: 'Split earnings from a joint operation — breach means forfeiting your share',
    icon: '💰',
    defaultTerms: 'Both parties commit to transparent revenue reporting and agreed split ratios.',
  },
  {
    id: 'task_delivery',
    name: 'Task Delivery Guarantee',
    description: 'Guarantee delivery of work by deadline — stake is slashed on failure',
    icon: '📦',
    defaultTerms: 'Worker commits to deliver specified work product by the agreed deadline.',
  },
  {
    id: 'liquidity_lock',
    name: 'Liquidity Commitment',
    description: 'Lock liquidity for an agreed period — early withdrawal triggers penalty',
    icon: '🔒',
    defaultTerms: 'Both parties commit to maintaining liquidity positions for the covenant duration.',
  },
  {
    id: 'intelligence_share',
    name: 'Intelligence Sharing Pact',
    description: 'Exchange proprietary signals or data — leak or misuse triggers slashing',
    icon: '🧠',
    defaultTerms: 'Parties agree to share specified data exclusively and not redistribute to third parties.',
  },
  {
    id: 'security_audit',
    name: 'Security Audit Bond',
    description: 'Auditor stakes reputation on findings — missed critical bugs reduce stake',
    icon: '🛡️',
    defaultTerms: 'Auditor commits to thorough review. Missed critical vulnerabilities result in partial stake return.',
  },
  {
    id: 'non_compete',
    name: 'Non-Compete Alliance',
    description: 'Agree not to compete in a specific domain for a period — violation is slashable',
    icon: '🤝',
    defaultTerms: 'Parties agree not to operate competing services in the defined domain for the covenant duration.',
  },
  {
    id: 'custom',
    name: 'Custom Bond',
    description: 'Define your own bond terms — you write the reason and conditions',
    icon: '✍️',
    defaultTerms: '',
  },
];

interface CovenantFormProps {
  onSubmit?: (data: any) => void;
  onCancel?: () => void;
}

export function CovenantForm({ onSubmit, onCancel }: CovenantFormProps) {
  const [step, setStep] = useState(0);
  const [formData, setFormData] = useState({
    counterparty: '',
    bondReason: 'task_delivery',
    customReason: '',
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

  const { createCovenant, hash, isPending, isConfirming, isSuccess, error } = useCreateCovenant();

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
  const isValid = totalAmount === 100 && formData.counterparty.startsWith('0x') && formData.counterparty.length === 42 && parseFloat(formData.totalValue) > 0;

  const selectedBond = BOND_REASONS.find(b => b.id === formData.bondReason);
  const bondLabel = selectedBond?.name || 'Custom Bond';

  const handleCreate = () => {
    if (!isValid) return;

    const durationSeconds = BigInt(parseInt(formData.duration) * 86400);
    const stakeAmount = parseEther(formData.totalValue);
    const reason = formData.bondReason === 'custom' ? formData.customReason : formData.bondReason;
    const covenantType = encodeBytes32String(reason.slice(0, 31));
    const termsIPFS = JSON.stringify({
      title: formData.title,
      description: formData.description,
      bondReason: bondLabel,
      milestones: formData.milestones,
    });

    createCovenant(
      formData.counterparty as `0x${string}`,
      covenantType,
      termsIPFS,
      durationSeconds,
      stakeAmount,
    );
  };

  if (isSuccess && hash) {
    return (
      <Card className="w-full max-w-2xl mx-auto">
        <CardContent className="pt-8 text-center space-y-4">
          <div className="w-16 h-16 rounded-full bg-emerald-500/10 flex items-center justify-center mx-auto">
            <Check className="w-8 h-8 text-emerald-500" />
          </div>
          <h2 className="text-2xl font-bold">Covenant Created</h2>
          <p className="text-muted-foreground">Your covenant bond has been submitted to X Layer. The counterparty can now accept it.</p>
          <a
            href={`https://www.oklink.com/xlayer-test/tx/${hash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 text-primary hover:underline"
          >
            View on Explorer <ExternalLink className="w-4 h-4" />
          </a>
          <div className="pt-4">
            <Button onClick={onCancel}>Back to Covenants</Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  const renderStep = () => {
    switch (step) {
      case 0:
        return (
          <div className="space-y-6">
            <div>
              <Label>Counterparty Address</Label>
              <Input
                placeholder="0x..."
                value={formData.counterparty}
                onChange={(e) => updateField('counterparty', e.target.value)}
                className="font-mono"
              />
              <p className="text-xs text-muted-foreground mt-1">The agent you want to form a bond with</p>
            </div>

            <Separator />

            <div>
              <Label className="mb-3 block">Why are you bonding?</Label>
              <div className="grid grid-cols-2 gap-3">
                {BOND_REASONS.map((reason) => (
                  <div
                    key={reason.id}
                    onClick={() => {
                      updateField('bondReason', reason.id);
                      if (reason.defaultTerms && !formData.description) {
                        updateField('description', reason.defaultTerms);
                      }
                    }}
                    className={`p-4 rounded-lg border cursor-pointer transition-all ${
                      formData.bondReason === reason.id
                        ? 'border-primary bg-primary/5'
                        : 'border-border hover:border-primary/50'
                    }`}
                  >
                    <div className="text-2xl mb-2">{reason.icon}</div>
                    <h4 className="font-medium text-sm">{reason.name}</h4>
                    <p className="text-xs text-muted-foreground mt-1">{reason.description}</p>
                  </div>
                ))}
              </div>
            </div>

            {formData.bondReason === 'custom' && (
              <div>
                <Label>Custom Bond Reason</Label>
                <Input
                  placeholder="e.g., Joint arbitrage operation with profit split"
                  value={formData.customReason}
                  onChange={(e) => updateField('customReason', e.target.value)}
                />
              </div>
            )}
          </div>
        );
      case 1:
        return (
          <div className="space-y-4">
            <div className="p-3 bg-primary/5 border border-primary/20 rounded-lg">
              <p className="text-sm"><span className="font-medium">Bond type:</span> {bondLabel}</p>
            </div>
            <div>
              <Label>Covenant Title</Label>
              <Input
                placeholder="e.g., Q2 Revenue Share with Agent-7"
                value={formData.title}
                onChange={(e) => updateField('title', e.target.value)}
              />
            </div>
            <div>
              <Label>Terms & Conditions</Label>
              <Textarea
                placeholder="Describe what both parties agree to..."
                value={formData.description}
                onChange={(e) => updateField('description', e.target.value)}
                rows={4}
              />
              <p className="text-xs text-muted-foreground mt-1">These terms are stored on-chain and enforceable via the dispute system</p>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Stake Amount (OKB)</Label>
                <Input
                  type="number"
                  step="0.01"
                  min="0.01"
                  placeholder="0.01"
                  value={formData.totalValue}
                  onChange={(e) => updateField('totalValue', e.target.value)}
                />
                <p className="text-xs text-muted-foreground mt-1">Min: 0.01 OKB. This is escrowed until fulfillment.</p>
              </div>
              <div>
                <Label>Duration (days)</Label>
                <Input
                  type="number"
                  min="1"
                  value={formData.duration}
                  onChange={(e) => updateField('duration', e.target.value)}
                />
              </div>
            </div>
          </div>
        );
      case 2:
        return (
          <div className="space-y-4">
            <div className="flex items-center justify-between p-4 bg-muted/50 rounded-lg">
              <div>
                <span className="text-sm text-muted-foreground">Stake: </span>
                <span className="font-semibold">{formData.totalValue || '0'} OKB</span>
              </div>
              <div>
                <span className="text-sm text-muted-foreground">Milestone Total: </span>
                <span className={`font-semibold ${totalAmount !== 100 ? 'text-red-500' : 'text-emerald-500'}`}>
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
                      <Input placeholder="Title" value={milestone.title} onChange={(e) => updateMilestone(index, 'title', e.target.value)} />
                      <Input type="number" placeholder="Amount %" value={milestone.amount} onChange={(e) => updateMilestone(index, 'amount', e.target.value)} />
                      <Input type="number" placeholder="Days" value={milestone.deadline} onChange={(e) => updateMilestone(index, 'deadline', e.target.value)} />
                    </div>
                    <Input placeholder="Description" value={milestone.description} onChange={(e) => updateMilestone(index, 'description', e.target.value)} />
                  </div>
                ))}
              </div>
            </ScrollArea>
            <Button variant="outline" onClick={addMilestone} className="w-full">
              <Plus className="w-4 h-4 mr-2" /> Add Milestone
            </Button>
          </div>
        );
      case 3:
        return (
          <div className="space-y-4">
            <div className="p-4 bg-muted/50 rounded-lg space-y-3">
              <div className="flex justify-between"><span className="text-muted-foreground">Bond Reason</span><span className="font-medium">{bondLabel}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Title</span><span className="font-medium">{formData.title || 'Untitled'}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Counterparty</span><span className="font-mono text-sm">{formData.counterparty ? `${formData.counterparty.slice(0, 8)}...${formData.counterparty.slice(-6)}` : 'Not set'}</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Stake</span><span className="font-medium">{formData.totalValue} OKB</span></div>
              <div className="flex justify-between"><span className="text-muted-foreground">Duration</span><span className="font-medium">{formData.duration} days</span></div>
            </div>
            {formData.description && (
              <div className="p-4 bg-muted/50 rounded-lg">
                <p className="text-xs text-muted-foreground mb-1">Terms</p>
                <p className="text-sm">{formData.description}</p>
              </div>
            )}
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
            {error && (
              <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-lg text-sm text-red-500">
                {error.message?.includes('user rejected') ? 'Transaction rejected by wallet' : error.message || 'Transaction failed'}
              </div>
            )}
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
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm ${
                i < step ? 'bg-primary text-primary-foreground' :
                i === step ? 'bg-primary/20 text-primary border-2 border-primary' :
                'bg-muted text-muted-foreground'
              }`}>
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
          <motion.div key={step} initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}>
            {renderStep()}
          </motion.div>
        </AnimatePresence>

        <div className="flex justify-between mt-6">
          <Button variant="outline" onClick={onCancel}>Cancel</Button>
          <div className="flex gap-2">
            {step > 0 && (
              <Button variant="outline" onClick={() => setStep(step - 1)}>
                <ChevronLeft className="w-4 h-4 mr-2" /> Back
              </Button>
            )}
            {step < STEPS.length - 1 ? (
              <Button onClick={() => setStep(step + 1)}>
                Next <ChevronRight className="w-4 h-4 ml-2" />
              </Button>
            ) : (
              <Button onClick={handleCreate} disabled={!isValid || isPending || isConfirming}>
                {isPending ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Confirm in Wallet...</> :
                 isConfirming ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Confirming...</> :
                 'Create Covenant'}
              </Button>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
