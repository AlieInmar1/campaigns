import React from 'react';
import { Loader2 } from 'lucide-react';

interface ProviderMatchSummaryProps {
  providerCount: number | null;
  potentialReach: number | null;
  isCalculating: boolean;
  error: string | null;
  className?: string;
}

/**
 * Component to display summary of matching providers
 * Shows current provider count and potential patient reach
 */
export function ProviderMatchSummary({
  providerCount,
  potentialReach,
  isCalculating,
  error,
  className = '',
}: ProviderMatchSummaryProps) {
  if (isCalculating) {
    return (
      <div className={`mb-4 p-3 bg-gray-50 rounded-lg border border-gray-200 ${className}`}>
        <div className="flex items-center justify-center">
          <Loader2 className="h-4 w-4 animate-spin text-primary-600 mr-2" />
          <p className="text-sm text-gray-500">
            Calculating provider matches...
          </p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className={`mb-4 p-3 bg-red-50 rounded-lg border border-red-200 ${className}`}>
        <p className="text-sm text-red-600">
          {error}
        </p>
        <p className="text-xs text-red-500 mt-1">
          Using fallback calculation method. Results may be estimates.
        </p>
      </div>
    );
  }

  if (!providerCount && !potentialReach) {
    return (
      <div className={`mb-4 p-3 bg-gray-50 rounded-lg border border-gray-200 ${className}`}>
        <p className="text-sm text-gray-500">
          Provider count will be calculated as you select targeting criteria
        </p>
      </div>
    );
  }

  return (
    <div className={`mb-4 p-3 bg-primary-50 rounded-lg border border-primary-100 ${className}`}>
      <div className="flex justify-between">
        <div>
          <span className="text-sm font-medium text-gray-500">Matching Providers:</span>
          <span className="ml-2 text-lg font-semibold text-primary-700">
            {providerCount?.toLocaleString() || '0'}
          </span>
        </div>
        <div>
          <span className="text-sm font-medium text-gray-500">Potential Patient Reach:</span>
          <span className="ml-2 text-lg font-semibold text-primary-700">
            {potentialReach?.toLocaleString() || '0'}
          </span>
        </div>
      </div>
      
      <div className="mt-2 text-xs text-gray-600 bg-primary-50 p-2 rounded border border-primary-100">
        Adding more medications or broadening your specialty/geographic criteria increases your provider count and potential reach.
      </div>
    </div>
  );
}
