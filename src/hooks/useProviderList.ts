import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';
import { Provider } from '../types';
import { ProviderListState, ProviderFilterCriteria } from '../types/providerList';
import { 
  enablePatientPrescriptionsFeature, 
  getProvidersByFilter, 
  getProvidersByCombinedFilter, 
  getProviderDetails 
} from '../lib/providerDataService';

// Initial state for provider list
const initialState: ProviderListState = {
  allProviders: [],
  filteredProviders: [],
  matchingCount: 0,
  isLoading: false,
  loadingProgress: 0,
  error: undefined
};

/**
 * Hook for managing provider lists with filtering capabilities
 * This hook provides methods to filter providers by various criteria
 */
export function useProviderList() {
  // State management
  const [state, setState] = useState<ProviderListState>(initialState);
  const [currentFilters, setCurrentFilters] = useState<ProviderFilterCriteria>({});
  const [isInitialized, setIsInitialized] = useState(false);
  
  // Initialize the hook
  useEffect(() => {
    const initialize = async () => {
      setState(prev => ({ 
        ...prev, 
        isLoading: true, 
        loadingProgress: 0,
        error: undefined 
      }));
      
      try {
        // Enable patient prescriptions feature
        await enablePatientPrescriptionsFeature();
        
        // Start with all 150k providers
        const providerIds = await getProvidersByFilter({});
        
        // For display, we only need a sample
        const sampleSize = Math.min(providerIds.length, 100);
        const sampleProviderIds = providerIds.slice(0, sampleSize);
        
        // Get provider details for the sample
        const providers = await getProviderDetails(sampleProviderIds);
        
        setState(prev => ({
          ...prev,
          allProviders: providers,
          filteredProviders: providers,
          matchingCount: providerIds.length, // Total count, not just the sample
          isLoading: false,
          loadingProgress: 100
        }));
        
        setIsInitialized(true);
      } catch (error) {
        console.error('Error initializing provider list:', error);
        setState(prev => ({
          ...prev,
          error: 'Failed to initialize provider list',
          isLoading: false,
          loadingProgress: 0
        }));
      }
    };
    
    initialize();
  }, []);

  /**
   * Apply all filters at once
   * This is more efficient than applying filters one by one
   */
  const applyAllFilters = useCallback(async (filters: ProviderFilterCriteria) => {
    setState(prev => ({ ...prev, isLoading: true, error: undefined }));
    
    try {
      // Convert filter criteria to provider filter format
      const providerFilter = {
        medicationIds: filters.includedMedications || [],
        excludedMedicationIds: filters.excludedMedications || [],
        specialties: filters.specialties || [],
        regions: filters.regions || []
      };
      
      // Try to use the combined filter method first (more efficient)
      let providerIds: string[] = [];
      
      // If we have simple filters, use the combined method
      if (!filters.category) {
        providerIds = await getProvidersByCombinedFilter(providerFilter);
      } else {
        // If we have a category filter, we need to get medications in that category first
        const { data: medications } = await supabase
          .from('medications')
          .select('id')
          .eq('category', filters.category);
          
        if (medications?.length) {
          // Add category medications to included medications
          const medicationIds = medications.map((m: { id: string }) => m.id);
          providerFilter.medicationIds = [...(providerFilter.medicationIds || []), ...medicationIds];
          
          // Use the regular filter method
          providerIds = await getProvidersByFilter(providerFilter);
        } else {
          // No medications in this category
          providerIds = [];
        }
      }
      
      // Get provider details (limited to a reasonable number for display)
      const displayLimit = Math.min(providerIds.length, 500);
      const displayProviderIds = providerIds.slice(0, displayLimit);
      const filteredProviders = await getProviderDetails(displayProviderIds);
      
      setState(prev => ({
        ...prev,
        filteredProviders,
        matchingCount: providerIds.length, // Total count, not just displayed providers
        isLoading: false
      }));
    } catch (error) {
      console.error('Error applying filters:', error);
      setState(prev => ({
        ...prev,
        error: 'Failed to apply filters',
        isLoading: false
      }));
    }
  }, []);

  /**
   * Filter providers by medication category
   */
  const filterByCategory = useCallback(async (category: string) => {
    // Update current filters
    setCurrentFilters(prev => {
      const newFilters = { ...prev, category };
      
      // Apply all filters
      applyAllFilters(newFilters);
      
      return newFilters;
    });
  }, [applyAllFilters]);

  /**
   * Filter providers by specific medications
   */
  const filterByMedications = useCallback(async (includedMeds: string[], excludedMeds: string[] = []) => {
    // Update current filters
    setCurrentFilters(prev => {
      const newFilters = { 
        ...prev, 
        includedMedications: includedMeds,
        excludedMedications: excludedMeds
      };
      
      // Apply all filters
      applyAllFilters(newFilters);
      
      return newFilters;
    });
  }, [applyAllFilters]);

  /**
   * Filter providers by specialties
   */
  const filterBySpecialties = useCallback(async (specialties: string[]) => {
    // Update current filters
    setCurrentFilters(prev => {
      const newFilters = { ...prev, specialties };
      
      // Apply all filters
      applyAllFilters(newFilters);
      
      return newFilters;
    });
  }, [applyAllFilters]);

  /**
   * Filter providers by regions
   */
  const filterByRegions = useCallback(async (regions: string[]) => {
    // Update current filters
    setCurrentFilters(prev => {
      const newFilters = { ...prev, regions };
      
      // Apply all filters
      applyAllFilters(newFilters);
      
      return newFilters;
    });
  }, [applyAllFilters]);

  /**
   * Reset all filters
   */
  const resetFilters = useCallback(async () => {
    setCurrentFilters({});
    
    setState(prev => ({ ...prev, isLoading: true, error: undefined }));
    
    try {
      // Get a sample of providers
      const providerIds = await getProvidersByFilter({});
      const totalCount = providerIds.length;
      const sampleSize = Math.min(totalCount, 100);
      const sampleProviderIds = providerIds.slice(0, sampleSize);
      
      // Get provider details
      const providers = await getProviderDetails(sampleProviderIds);
      
      setState(prev => ({
        ...prev,
        filteredProviders: providers,
        matchingCount: totalCount,
        isLoading: false
      }));
    } catch (error) {
      console.error('Error resetting filters:', error);
      setState(prev => ({
        ...prev,
        error: 'Failed to reset filters',
        isLoading: false
      }));
    }
  }, []);

  return {
    ...state,
    currentFilters,
    isInitialized,
    filterByCategory,
    filterByMedications,
    filterBySpecialties,
    filterByRegions,
    resetFilters,
    applyAllFilters
  };
}
