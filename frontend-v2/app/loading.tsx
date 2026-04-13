import { PageSkeleton } from '@/components/layout/loading-skeleton';

export default function Loading() {
  return (
    <div className="p-8">
      <PageSkeleton cards={4} />
    </div>
  );
}
