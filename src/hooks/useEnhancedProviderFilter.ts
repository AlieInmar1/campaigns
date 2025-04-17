import { useState, useCallback, useEffect } from 'react';
import {
  EnhancedProviderFilter,
  FilteredProviderResponse,
  estimateFilteredProviderCount,
  getFilteredProviderDetails,
  validatePrimaryFilter
} from '../lib/enhancedProviderDataService';

export interface UseEnhancedProviderFilterResult {
  // Filter state
  filter: EnhancedProviderFilter;
  isValidFilter: boolean;
  
  // Loading states
  isLoading: boolean;
  isEstimating: boolean;
  estimatedCount: number;
  
  // Results
  filteredProviders: any[];
  totalMatchingCount: number;
  
  // Error state
  error?: string;
  
  // Filter methods
  updateFilter: <K extends keyof EnhancedProviderFilter>(key: K, value: EnhancedProviderFilter[K]) => void;
  updateFilters: (updates: Partial<EnhancedProviderFilter>) => void;
  applyFilters: () => Promise<void>;
  resetFilters: () => void;
}

const initialFilter: EnhancedProviderFilter = {
  specialties: [],
  medicationCategory: '',
  includedMedications: [],
  excludedMedications: [],
  brandPreference: 'both',
  regions: [],
  timeframe: 'year',
  gender: 'all'
};

/**
 * Hook for managing enhanced provider filtering
 * This hook handles the filter state, validation, and loading states
 */
export function useEnhancedProviderFilter(): UseEnhancedProviderFilterResult {
  // State for current filter
  const [filter, setFilter] = useState<EnhancedProviderFilter>(initialFilter);
  const [isValidFilter, setIsValidFilter] = useState<boolean>(false);
  
  // Loading and results state
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isEstimating, setIsEstimating] = useState<boolean>(false);
  const [estimatedCount, setEstimatedCount] = useState<number>(0);
  const [filteredProviders, setFilteredProviders] = useState<any[]>([]);
  const [totalMatchingCount, setTotalMatchingCount] = useState<number>(0);
  const [error, setError] = useState<string | undefined>(undefined);
  
  // Validate filter whenever it changes, but don't trigger auto-estimate
  useEffect(() => {
    console.log('Filter changed, validating:', filter);
    const isValid = validatePrimaryFilter(filter);
    setIsValidFilter(isValid);
  }, [filter]);
  
  // Separate effect for auto-estimation with debounce
  useEffect(() => {
    // Skip if filter is not valid
    if (!isValidFilter) {
      setEstimatedCount(0);
      return;
    }
    
    // Debounce the estimate to prevent too many API calls
    const debounceTimer = setTimeout(() => {
      // Get estimated count when filter changes and is valid
      const updateEstimate = async () => {
        console.log('Estimating count for filter:', filter);
        setIsEstimating(true);
        try {
          const count = await estimateFilteredProviderCount(filter);
          console.log('Estimated count:', count);
          setEstimatedCount(count);
        } catch (err) {
          console.error('Error estimating count:', err);
        } finally {
          setIsEstimating(false);
        }
      };
      
      updateEstimate();
    }, 1000); // 1000ms debounce
    
    // Clean up the timer
    return () => clearTimeout(debounceTimer);
  }, [filter, isValidFilter]);
  
  // Update a single filter property
  const updateFilter = useCallback(<K extends keyof EnhancedProviderFilter>(
    key: K, 
    value: EnhancedProviderFilter[K]
  ) => {
    setFilter((prev: EnhancedProviderFilter) => ({
      ...prev,
      [key]: value
    }));
  }, []);
  
  // Update multiple filter properties at once
  const updateFilters = useCallback((updates: Partial<EnhancedProviderFilter>) => {
    setFilter((prev: EnhancedProviderFilter) => ({
      ...prev,
      ...updates
    }));
  }, []);
  
  // Apply filters to get actual results
  const applyFilters = useCallback(async () => {
    console.log('Manually applying filters');
    
    if (!validatePrimaryFilter(filter)) {
      setError('At least one primary filter must be selected');
      return;
    }
    
    setIsLoading(true);
    setError(undefined);
    
    try {
      // First get an updated estimate
      console.log('Getting updated estimate before applying filters');
      const count = await estimateFilteredProviderCount(filter);
      setEstimatedCount(count);
      
      // Limit to 500 providers for UI performance
      console.log('Fetching filtered provider details');
      const results = await getFilteredProviderDetails(filter, 500);
      
      console.log(`Got ${results.length} providers out of ${count} total`);
      setFilteredProviders(results);
      setTotalMatchingCount(count);
    } catch (err: any) {
      console.error('Error applying filters:', err);
      setError(err.message || 'Error applying filters');
      setFilteredProviders([]);
      setTotalMatchingCount(0);
    } finally {
      setIsLoading(false);
    }
  }, [filter]); // Only depend on filter, not estimatedCount
  
  // Reset filters to initial state
  const resetFilters = useCallback(() => {
    setFilter(initialFilter);
    setFilteredProviders([]);
    setTotalMatchingCount(0);
    setEstimatedCount(0);
    setError(undefined);
  }, []);
  
  return {
    filter,
    isValidFilter,
    isLoading,
    isEstimating,
    estimatedCount,
    filteredProviders,
    totalMatchingCount,
    error,
    updateFilter,
    updateFilters,
    applyFilters,
    resetFilters
  };
}
