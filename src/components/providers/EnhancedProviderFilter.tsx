import React, { useState, useEffect, useMemo } from 'react';
import { useEnhancedProviderFilter } from '../../hooks/useEnhancedProviderFilter';
import { MultiSelect } from '../ui/MultiSelect';
import { Button } from '../ui/Button';
import {
  getAvailableSpecialties,
  getAvailableRegions,
  getMedicationCategories,
  getMedicationsByCategory,
  getRecommendedSpecialties
} from '../../lib/enhancedProviderDataService';

interface EnhancedProviderFilterProps {
  onFilterApplied: (providers: any[]) => void;
  onFilterCountChange?: (count: number) => void;
  defaultSpecialties?: string[];
}

export function EnhancedProviderFilter({
  onFilterApplied,
  onFilterCountChange,
  defaultSpecialties = []
}: EnhancedProviderFilterProps) {
  // Use the enhanced filter hook
  const {
    filter,
    isValidFilter,
    isLoading,
    isEstimating,
    estimatedCount,
    filteredProviders,
    error,
    updateFilter,
    updateFilters,
    applyFilters,
    resetFilters
  } = useEnhancedProviderFilter();

  // State for available options
  const [availableSpecialties, setAvailableSpecialties] = useState<{value: string, label: string}[]>([]);
  const [availableRegions, setAvailableRegions] = useState<{value: string, label: string}[]>([]);
  const [medicationCategories, setMedicationCategories] = useState<{value: string, label: string}[]>([]);
  const [medications, setMedications] = useState<{value: string, label: string, category: string}[]>([]);
  const [recommendedSpecialties, setRecommendedSpecialties] = useState<string[]>([]);
  const [isFetchingOptions, setIsFetchingOptions] = useState<boolean>(true);

  const timeframeOptions = [
    { value: 'month', label: 'Last Month' },
    { value: 'quarter', label: 'Last Quarter' },
    { value: 'year', label: 'Last Year' }
  ];

  const brandOptions = [
    { value: 'both', label: 'Both' },
    { value: 'brand', label: 'Brand Name Only' },
    { value: 'generic', label: 'Generic Only' }
  ];
  
  const genderOptions = [
    { value: 'all', label: 'All Genders' },
    { value: 'male', label: 'Male Providers' },
    { value: 'female', label: 'Female Providers' }
  ];

  // Load filter options on component mount
  useEffect(() => {
    async function loadFilterOptions() {
      setIsFetchingOptions(true);
      try {
        // Fetch specialties, regions, and categories in parallel
        const [specialties, regions, categories] = await Promise.all([
          getAvailableSpecialties(),
          getAvailableRegions(),
          getMedicationCategories()
        ]);

        // Map to option format
        setAvailableSpecialties(
          specialties.map(specialty => ({ value: specialty, label: specialty }))
        );
        setAvailableRegions(
          regions.map(region => ({ value: region, label: region }))
        );
        setMedicationCategories(
          categories.map(category => ({ value: category, label: category }))
        );

        // If a default category is provided, load medications for it
        if (filter.medicationCategory) {
          const medsForCategory = await getMedicationsByCategory(filter.medicationCategory);
          setMedications(
            medsForCategory.map(med => ({
              value: med.id,
              label: med.name,
              category: med.category
            }))
          );
        }
      } catch (error) {
        console.error('Error loading filter options:', error);
      } finally {
        setIsFetchingOptions(false);
      }
    }

    loadFilterOptions();
  }, []);

  // Set default specialties
  useEffect(() => {
    if (defaultSpecialties.length > 0 && availableSpecialties.length > 0) {
      // Filter to only include valid specialties that exist in availableSpecialties
      const validSpecialties = defaultSpecialties.filter(spec => 
        availableSpecialties.some(option => option.value === spec)
      );
      
      if (validSpecialties.length > 0) {
        updateFilter('specialties', validSpecialties);
      }
    }
  }, [defaultSpecialties, availableSpecialties, updateFilter]);

  // Load all medications once
  useEffect(() => {
    async function loadAllMedications() {
      setIsFetchingOptions(true);
      try {
        const allMeds = await getMedicationsByCategory();
        setMedications(
          allMeds.map(med => ({
            value: med.id,
            label: med.name,
            category: med.category
          }))
        );
      } catch (error) {
        console.error('Error loading medications:', error);
      } finally {
        setIsFetchingOptions(false);
      }
    }

    loadAllMedications();
  }, []);
  
  // Filter medications based on selected categories
  const filteredMedications = useMemo(() => {
    if (!filter.medicationCategory || filter.medicationCategory.length === 0) {
      return medications;
    }
    
    return medications.filter(med => 
      Array.isArray(filter.medicationCategory) 
        ? filter.medicationCategory.includes(med.category)
        : med.category === filter.medicationCategory
    );
  }, [medications, filter.medicationCategory]);

  // Get specialty recommendations when medications are selected
  useEffect(() => {
    async function getSpecialtyRecommendations() {
      if (filter.includedMedications && filter.includedMedications.length > 0) {
        try {
          const recommendations = await getRecommendedSpecialties(filter.includedMedications);
          setRecommendedSpecialties(recommendations);
        } catch (error) {
          console.error('Error getting specialty recommendations:', error);
        }
      } else {
        setRecommendedSpecialties([]);
      }
    }

    getSpecialtyRecommendations();
  }, [filter.includedMedications]);

  // Update output when providers are filtered
  useEffect(() => {
    if (filteredProviders.length > 0) {
      onFilterApplied(filteredProviders);
    }
  }, [filteredProviders, onFilterApplied]);

  // Notify parent of estimated count changes
  useEffect(() => {
    if (onFilterCountChange) {
      onFilterCountChange(estimatedCount);
    }
  }, [estimatedCount, onFilterCountChange]);

  // Handler for applying recommended specialties
  const handleApplyRecommendations = () => {
    if (recommendedSpecialties.length > 0) {
      updateFilter('specialties', recommendedSpecialties);
    }
  };

  return (
    <div className="bg-white p-4 rounded-lg shadow-sm space-y-4">
      <h3 className="text-lg font-semibold mb-4">Enhanced Provider Filter</h3>

      {/* Filter groups */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Primary filters - Required group (at least one must be selected) */}
        <div className="space-y-4 border rounded-md p-4">
          <h4 className="font-medium text-gray-700">Primary Filters</h4>
          <p className="text-sm text-gray-500 italic mb-2">At least one selection required</p>

          {/* Specialties */}
          <div>
            <label className="block text-sm font-medium mb-1">Provider Specialties</label>
            <MultiSelect
              options={availableSpecialties}
              value={filter.specialties || []}
              onChange={(value) => updateFilter('specialties', value)}
              placeholder="Select specialties..."
              isDisabled={isFetchingOptions}
            />
            {recommendedSpecialties.length > 0 && (
              <div className="mt-1">
                <p className="text-xs text-blue-600">
                  Recommendations for selected medications:
                </p>
                <div className="flex flex-wrap gap-1 mt-1">
                  {recommendedSpecialties.map(specialty => (
                    <span 
                      key={specialty}
                      className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded cursor-pointer hover:bg-blue-100"
                      onClick={() => {
                        // Add to current specialties if not already included
                        const currentSpecialties = filter.specialties || [];
                        if (!currentSpecialties.includes(specialty)) {
                          updateFilter('specialties', [...currentSpecialties, specialty]);
                        }
                      }}
                    >
                      {specialty}
                    </span>
                  ))}
                </div>
                <button 
                  className="text-xs text-blue-700 underline mt-1"
                  onClick={handleApplyRecommendations}
                >
                  Apply all recommendations
                </button>
              </div>
            )}
          </div>

          {/* Medication Category (now multi-select) */}
          <div>
            <label className="block text-sm font-medium mb-1">Medication Categories</label>
            <MultiSelect
              options={medicationCategories}
              value={Array.isArray(filter.medicationCategory) ? filter.medicationCategory : filter.medicationCategory ? [filter.medicationCategory] : []}
              onChange={(values) => {
                // Update the filter with the selected categories
                updateFilter('medicationCategory', values);
              }}
              placeholder="Select categories..."
              isDisabled={isFetchingOptions}
            />
          </div>

          {/* Specific Medications */}
          <div>
            <label className="block text-sm font-medium mb-1">Include Medications</label>
            <MultiSelect
              options={filteredMedications}
              value={filter.includedMedications || []}
              onChange={(value) => updateFilter('includedMedications', value)}
              placeholder="Select medications..."
              isDisabled={isFetchingOptions}
            />
          </div>
        </div>

        {/* Secondary filters - Optional group */}
        <div className="space-y-4 border rounded-md p-4">
          <h4 className="font-medium text-gray-700">Secondary Filters</h4>
          <p className="text-sm text-gray-500 italic mb-2">Optional refinements</p>

          {/* Excluded Medications */}
          <div>
            <label className="block text-sm font-medium mb-1">Exclude Medications</label>
            <MultiSelect
              options={filteredMedications}
              value={filter.excludedMedications || []}
              onChange={(value) => updateFilter('excludedMedications', value)}
              placeholder="Select medications to exclude..."
              isDisabled={isFetchingOptions}
            />
          </div>

          {/* Brand Preference */}
          <div>
            <label className="block text-sm font-medium mb-1">Brand Preference</label>
            <select
              className="w-full rounded-md border border-gray-300 py-2 px-3 text-sm"
              value={filter.brandPreference || 'both'}
              onChange={(e) => updateFilter('brandPreference', e.target.value as 'brand' | 'generic' | 'both')}
            >
              {brandOptions.map(option => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>

          {/* Regions */}
          <div>
            <label className="block text-sm font-medium mb-1">Geographic Regions</label>
            <MultiSelect
              options={availableRegions}
              value={filter.regions || []}
              onChange={(value) => updateFilter('regions', value)}
              placeholder="Select regions..."
              isDisabled={isFetchingOptions}
            />
          </div>

          {/* Timeframe */}
          <div>
            <label className="block text-sm font-medium mb-1">Prescription Timeframe</label>
            <select
              className="w-full rounded-md border border-gray-300 py-2 px-3 text-sm"
              value={filter.timeframe || 'year'}
              onChange={(e) => updateFilter('timeframe', e.target.value as 'month' | 'quarter' | 'year')}
            >
              {timeframeOptions.map(option => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
          
          {/* Provider Gender */}
          <div>
            <label className="block text-sm font-medium mb-1">Provider Gender</label>
            <select
              className="w-full rounded-md border border-gray-300 py-2 px-3 text-sm"
              value={filter.gender || 'all'}
              onChange={(e) => updateFilter('gender', e.target.value as 'male' | 'female' | 'all')}
            >
              {genderOptions.map(option => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Results summary */}
      <div className="mt-4 border-t pt-4">
        {isEstimating ? (
          <p className="text-sm text-gray-600">Estimating provider count...</p>
        ) : (
          <p className="text-sm text-gray-600">
            {isValidFilter
              ? `Estimated matching providers: ${estimatedCount}`
              : 'Please select at least one primary filter'}
          </p>
        )}

        {error && (
          <p className="mt-2 text-sm text-red-600">{error}</p>
        )}
      </div>

      {/* Action buttons */}
      <div className="flex justify-end space-x-3 mt-4">
        <Button
          type="button"
          variant="outline"
          onClick={resetFilters}
          disabled={isLoading}
        >
          Reset
        </Button>
        <Button
          type="button"
          variant="default"
          onClick={applyFilters}
          disabled={isLoading || !isValidFilter}
        >
          {isLoading ? 'Loading...' : 'Apply Filters'}
        </Button>
      </div>
    </div>
  );
}
