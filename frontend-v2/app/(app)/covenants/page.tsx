'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, ExternalLink, Loader2, Check, Clock, Shield, AlertTriangle, CheckCircle, XCircle } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { CovenantForm } from '@/components/covenant/covenant-form';
import { PageHeader } from '@/components/layout/page-header';
import { EmptyState } from '@/components/layout/empty-state';
import { useAccount } from 'wagmi';
import { useCovenantList, useCovenantDetail, useAcceptCovenant, STATUS_LABELS, formatEther } from '@/hooks/use-contracts';
import type { Address } from 'viem';

const STATUS_CONFIG: Record<string, { color: string; icon: typeof Clock }> = {
  Pending: { color: 'bg-amber-500/10 text-amber-500 border-amber-500/20', icon: Clock },
  Active: { color: 'bg-emerald-500/10 text-emerald-500 border-emerald-500/20', icon: CheckCircle },
  Fulfilled: { color: 'bg-blue-500/10 text-blue-500 border-blue-500/20', icon: Check },
  Disputed: { color: 'bg-red-500/10 text-red-500 border-red-500/20', icon: AlertTriangle },
  Resolved: { color: 'bg-purple-500/10 text-purple-500 border-purple-500/20', icon: Shield },
  Expired: { color: 'bg-muted text-muted-foreground', icon: XCircle },
  Breached: { color: 'bg-red-500/10 text-red-500 border-red-500/20', icon: XCircle },
};

function CovenantRow({ address: covAddr, myAddress, onSelect }: { address: Address; myAddress?: Address; onSelect: (a: Address) => void }) {
  const detail = useCovenantDetail(covAddr);

  if (detail.isLoading) {
    return (
      <Card className="animate-pulse">
        <CardContent className="pt-6 h-24" />
      </Card>
    );
  }

  if (detail.error || !detail.statusLabel) return null;

  const isInitiator = detail.initiator?.toLowerCase() === myAddress?.toLowerCase();
  const isCounterparty = detail.counterparty?.toLowerCase() === myAddress?.toLowerCase();
  const isMine = isInitiator || isCounterparty;
  const role = isInitiator ? 'Initiator' : isCounterparty ? 'Counterparty' : 'Observer';
  const statusCfg = STATUS_CONFIG[detail.statusLabel] || STATUS_CONFIG.Pending;
  const StatusIcon = statusCfg.icon;

  let termsData: any = {};
  try {
    if (detail.terms?.[1]) termsData = JSON.parse(detail.terms[1]);
  } catch {}

  const stakeOKB = detail.terms?.[4] != null ? formatEther(detail.terms[4]) : '0';

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="cursor-pointer"
      onClick={() => onSelect(covAddr)}
    >
      <Card className="hover:border-primary/20 transition-all">
        <CardContent className="pt-6">
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <h3 className="font-semibold">{termsData.title || 'Untitled Covenant'}</h3>
                <Badge className={statusCfg.color}>
                  <StatusIcon className="w-3 h-3 mr-1" />
                  {detail.statusLabel}
                </Badge>
              </div>
              <p className="text-sm text-muted-foreground">
                {termsData.bondReason || 'Custom Bond'}
              </p>
              <div className="flex items-center gap-4 text-xs text-muted-foreground pt-1">
                <span>Stake: {stakeOKB} OKB</span>
                <span>Role: {role}</span>
                <span className="font-mono">{covAddr.slice(0, 8)}...{covAddr.slice(-6)}</span>
              </div>
            </div>
            {detail.statusLabel === 'Pending' && isCounterparty && (
              <Badge className="bg-primary/10 text-primary border-primary/20 animate-pulse">
                Action Required
              </Badge>
            )}
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
}

function CovenantDetailView({ address: covAddr, onBack }: { address: Address; onBack: () => void }) {
  const { address: myAddress } = useAccount();
  const detail = useCovenantDetail(covAddr);
  const { accept, hash: acceptHash, isPending: acceptPending, isConfirming: acceptConfirming, isSuccess: acceptSuccess, error: acceptError } = useAcceptCovenant(covAddr);

  if (detail.isLoading) {
    return <div className="flex items-center justify-center py-20"><Loader2 className="w-8 h-8 animate-spin text-muted-foreground" /></div>;
  }

  const isCounterparty = detail.counterparty?.toLowerCase() === myAddress?.toLowerCase();
  const isInitiator = detail.initiator?.toLowerCase() === myAddress?.toLowerCase();
  const canAccept = detail.statusLabel === 'Pending' && isCounterparty;
  const statusCfg = STATUS_CONFIG[detail.statusLabel || 'Pending'] || STATUS_CONFIG.Pending;
  const StatusIcon = statusCfg.icon;

  let termsData: any = {};
  try {
    if (detail.terms?.[1]) termsData = JSON.parse(detail.terms[1]);
  } catch {}

  const stakeOKB = detail.terms?.[4] != null ? formatEther(detail.terms[4]) : '0';
  const balanceOKB = detail.remainingBalance != null ? formatEther(detail.remainingBalance) : '0';
  const expiresAt = detail.terms?.[3] != null ? new Date(Number(detail.terms[3]) * 1000) : null;

  return (
    <div className="space-y-6 max-w-3xl mx-auto">
      <Button variant="ghost" size="sm" onClick={onBack} className="gap-2">
        Back to Covenants
      </Button>

      {/* Header */}
      <Card>
        <CardHeader>
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-3 mb-2">
                <CardTitle className="text-2xl">{termsData.title || 'Untitled Covenant'}</CardTitle>
                <Badge className={statusCfg.color}>
                  <StatusIcon className="w-3 h-3 mr-1" />
                  {detail.statusLabel}
                </Badge>
              </div>
              <p className="text-muted-foreground">{termsData.bondReason || 'Custom Bond'}</p>
            </div>
            <a
              href={`https://www.oklink.com/xlayer-test/address/${covAddr}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs text-muted-foreground hover:text-primary flex items-center gap-1"
            >
              View on Explorer <ExternalLink className="w-3 h-3" />
            </a>
          </div>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Parties */}
          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 bg-muted/50 rounded-lg">
              <p className="text-xs text-muted-foreground mb-1">Initiator {isInitiator && '(You)'}</p>
              <p className="font-mono text-sm">{detail.initiator?.slice(0, 10)}...{detail.initiator?.slice(-8)}</p>
            </div>
            <div className="p-4 bg-muted/50 rounded-lg">
              <p className="text-xs text-muted-foreground mb-1">Counterparty {isCounterparty && '(You)'}</p>
              <p className="font-mono text-sm">{detail.counterparty?.slice(0, 10)}...{detail.counterparty?.slice(-8)}</p>
            </div>
          </div>

          {/* Key Details */}
          <div className="grid grid-cols-3 gap-4">
            <div className="p-4 bg-muted/50 rounded-lg text-center">
              <p className="text-xs text-muted-foreground">Staked</p>
              <p className="text-xl font-bold">{stakeOKB} OKB</p>
            </div>
            <div className="p-4 bg-muted/50 rounded-lg text-center">
              <p className="text-xs text-muted-foreground">Balance</p>
              <p className="text-xl font-bold">{balanceOKB} OKB</p>
            </div>
            <div className="p-4 bg-muted/50 rounded-lg text-center">
              <p className="text-xs text-muted-foreground">Expires</p>
              <p className="text-sm font-bold">{expiresAt ? expiresAt.toLocaleDateString() : '--'}</p>
            </div>
          </div>

          {/* Terms */}
          {termsData.description && (
            <div className="p-4 border rounded-lg">
              <h4 className="font-medium mb-2">Terms & Conditions</h4>
              <p className="text-sm text-muted-foreground whitespace-pre-wrap">{termsData.description}</p>
            </div>
          )}

          {/* Milestones */}
          {termsData.milestones && termsData.milestones.length > 0 && (
            <div className="p-4 border rounded-lg">
              <h4 className="font-medium mb-3">Milestones</h4>
              <div className="space-y-2">
                {termsData.milestones.map((m: any, i: number) => (
                  <div key={i} className="flex items-center justify-between py-2 border-b border-border/50 last:border-0">
                    <div>
                      <p className="text-sm font-medium">{m.title}</p>
                      {m.description && <p className="text-xs text-muted-foreground">{m.description}</p>}
                    </div>
                    <Badge variant="outline">{m.amount}%</Badge>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Accept Action */}
          {canAccept && !acceptSuccess && (
            <div className="p-4 bg-primary/5 border border-primary/20 rounded-lg space-y-3">
              <h4 className="font-medium">This covenant is waiting for your acceptance</h4>
              <p className="text-sm text-muted-foreground">
                By accepting, you agree to the terms above. The initiator has staked {stakeOKB} OKB into escrow.
                If either party breaches the terms, the stake can be disputed and slashed.
              </p>
              {acceptError && (
                <p className="text-sm text-red-500">
                  {acceptError.message?.includes('user rejected') ? 'Transaction rejected' : acceptError.message || 'Failed'}
                </p>
              )}
              <Button onClick={accept} disabled={acceptPending || acceptConfirming} size="lg" className="w-full">
                {acceptPending ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Confirm in Wallet...</> :
                 acceptConfirming ? <><Loader2 className="w-4 h-4 mr-2 animate-spin" /> Confirming...</> :
                 'Accept Covenant'}
              </Button>
            </div>
          )}

          {acceptSuccess && acceptHash && (
            <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-center space-y-2">
              <CheckCircle className="w-8 h-8 text-emerald-500 mx-auto" />
              <h4 className="font-bold text-lg">Covenant Accepted</h4>
              <p className="text-sm text-muted-foreground">The covenant is now <strong>Active</strong>. Both parties are bound to the agreed terms.</p>
              <a href={`https://www.oklink.com/xlayer-test/tx/${acceptHash}`} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-sm text-primary hover:underline">
                View TX <ExternalLink className="w-3 h-3" />
              </a>
            </div>
          )}

          {/* Active covenant info */}
          {detail.statusLabel === 'Active' && (
            <div className="p-4 bg-emerald-500/5 border border-emerald-500/20 rounded-lg flex items-center gap-3">
              <CheckCircle className="w-5 h-5 text-emerald-500" />
              <div>
                <p className="font-medium text-emerald-500">Covenant is Active</p>
                <p className="text-sm text-muted-foreground">Both parties have accepted. Milestones can now be completed and paid.</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

export default function CovenantsPage() {
  const { address } = useAccount();
  const { covenantAddresses, isLoading, refetch } = useCovenantList();
  const [showForm, setShowForm] = useState(false);
  const [selectedCovenant, setSelectedCovenant] = useState<Address | null>(null);
  const [filter, setFilter] = useState<'all' | 'mine' | 'incoming'>('all');

  if (showForm) {
    return <CovenantForm onCancel={() => { setShowForm(false); refetch(); }} />;
  }

  if (selectedCovenant) {
    return <CovenantDetailView address={selectedCovenant} onBack={() => { setSelectedCovenant(null); refetch(); }} />;
  }

  const addresses = covenantAddresses || [];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Covenants"
        subtitle={isLoading ? 'Loading from X Layer...' : `${addresses.length} covenant${addresses.length !== 1 ? 's' : ''} on-chain`}
        action={
          <Button onClick={() => setShowForm(true)}>
            <Plus className="w-4 h-4 mr-2" /> Create Covenant
          </Button>
        }
      />

      <Tabs value={filter} onValueChange={(v) => setFilter(v as typeof filter)}>
        <TabsList className="grid grid-cols-3 w-full max-w-md">
          <TabsTrigger value="all">All Covenants</TabsTrigger>
          <TabsTrigger value="mine">My Covenants</TabsTrigger>
          <TabsTrigger value="incoming">Incoming</TabsTrigger>
        </TabsList>
      </Tabs>

      {!address && filter !== 'all' && (
        <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-lg text-sm text-amber-500">
          Connect your wallet to see your covenants.
        </div>
      )}

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        </div>
      ) : addresses.length === 0 ? (
        <EmptyState
          title="No covenants yet"
          description="Be the first to create a binding agreement between two agents."
          action={{ label: 'Create Covenant', onClick: () => setShowForm(true) }}
        />
      ) : (
        <div className="space-y-3">
          {addresses.map((addr) => (
            <CovenantRowFiltered
              key={addr}
              address={addr}
              myAddress={address}
              filter={filter}
              onSelect={setSelectedCovenant}
            />
          ))}
        </div>
      )}
    </div>
  );
}

// Wrapper that applies client-side filtering after reading chain data
function CovenantRowFiltered({ address: covAddr, myAddress, filter, onSelect }: {
  address: Address; myAddress?: Address; filter: string; onSelect: (a: Address) => void;
}) {
  const detail = useCovenantDetail(covAddr);

  if (detail.isLoading) {
    return <Card className="animate-pulse"><CardContent className="pt-6 h-20" /></Card>;
  }

  const isInitiator = detail.initiator?.toLowerCase() === myAddress?.toLowerCase();
  const isCounterparty = detail.counterparty?.toLowerCase() === myAddress?.toLowerCase();

  if (filter === 'mine' && !isInitiator && !isCounterparty) return null;
  if (filter === 'incoming' && !isCounterparty) return null;

  return <CovenantRow address={covAddr} myAddress={myAddress} onSelect={onSelect} />;
}
