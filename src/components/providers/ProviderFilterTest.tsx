import React, { useState, useEffect } from 'react';
import { useProviderList } from '../../hooks/useProviderList';
import { Select } from '../ui/Select';
import { MultiSelect } from '../ui/MultiSelect';
import { Loader2, Bug, AlertTriangle, ChevronDown, ChevronUp } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { Medication } from '../../types';
import { debugDatabaseTables } from '../../lib/debugDatabase';
import { checkDatabaseHealth, formatHealthCheckResults } from '../../lib/databaseHealth';
import { Button } from '../ui/Button';

export function ProviderFilterTest() {
  const {
    filteredProviders,
    matchingCount,
    isLoading,
    loadingProgress,
    error,
    isInitialized,
    filterByCategory,
    filterByMedications,
    filterBySpecialties,
    filterByRegions
  } = useProviderList();

  // Local state for form inputs
  const [category, setCategory] = useState('');
  const [includedMeds, setIncludedMeds] = useState<string[]>([]);
  const [excludedMeds, setExcludedMeds] = useState<string[]>([]);
  const [specialties, setSpecialties] = useState<string[]>([]);
  const [regions, setRegions] = useState<string[]>([]);

  // State for reference data
  const [categories, setCategories] = useState<string[]>([]);
  const [medications, setMedications] = useState<Medication[]>([]);
  const [specialtyOptions, setSpecialtyOptions] = useState<{ value: string; label: string }[]>([]);
  const [regionOptions, setRegionOptions] = useState<{ value: string; label: string }[]>([]);
  const [isLoadingOptions, setIsLoadingOptions] = useState(true);
  const [isDebugging, setIsDebugging] = useState(false);
  const [dbAccessError, setDbAccessError] = useState<string | null>(null);
  const [healthCheckResults, setHealthCheckResults] = useState<string | null>(null);
  const [showDebugPanel, setShowDebugPanel] = useState(false);

  // Run database access check on mount
  useEffect(() => {
    const checkDatabaseAccess = async () => {
      const healthResults = await checkDatabaseHealth();
      setHealthCheckResults(formatHealthCheckResults(healthResults));
      if (!healthResults.isHealthy) {
        setDbAccessError('Database health check failed. Check debug panel for details.');
      }
    };
    checkDatabaseAccess();
  }, []);

  // Handle debug button click
  const handleDebugClick = async () => {
    setIsDebugging(true);
    try {
      await debugDatabaseTables();
      const healthResults = await checkDatabaseHealth();
      setHealthCheckResults(formatHealthCheckResults(healthResults));
      if (!healthResults.isHealthy) {
        setDbAccessError('Database health check failed. Check debug panel for details.');
      } else {
        setDbAccessError(null);
      }
    } finally {
      setIsDebugging(false);
    }
  };

  // Load reference data
  useEffect(() => {
    const loadReferenceData = async () => {
      setIsLoadingOptions(true);
      try {
        // Get medications and categories
        const { data: meds } = await supabase
          .from('medications')
          .select('*')
          .order('name');
        
        if (meds) {
          console.log('Loaded medications:', meds.length);
          setMedications(meds);
          const uniqueCategories = [...new Set(meds.map(m => m.category).filter(Boolean))].sort();
          console.log('Unique categories:', uniqueCategories);
          setCategories(uniqueCategories);
        }

        // Get unique specialties
        const { data: providers } = await supabase
          .from('providers')
          .select('specialty')
          .order('specialty');
        
        if (providers) {
          const uniqueSpecialties = [...new Set(providers.map(p => p.specialty).filter(Boolean))];
          console.log('Unique specialties:', uniqueSpecialties);
          setSpecialtyOptions(
            uniqueSpecialties.map(specialty => ({
              value: specialty,
              label: specialty
            }))
          );
        }

        // Get unique regions
        const { data: regionProviders } = await supabase
          .from('providers')
          .select('geographic_area')
          .order('geographic_area');
        
        if (regionProviders) {
          const uniqueRegions = [...new Set(regionProviders.map(p => p.geographic_area).filter(Boolean))];
          console.log('Unique regions:', uniqueRegions);
          setRegionOptions(
            uniqueRegions.map(region => ({
              value: region,
              label: region
            }))
          );
        }
      } catch (error) {
        console.error('Error loading reference data:', error);
      } finally {
        setIsLoadingOptions(false);
      }
    };

    loadReferenceData();
  }, []);

  // Handle category change
  const handleCategoryChange = async (value: string) => {
    setCategory(value);
    await filterByCategory(value);
  };

  // Handle included medications change
  const handleIncludedMedsChange = async (values: string[]) => {
    setIncludedMeds(values);
    await filterByMedications(values, excludedMeds);
  };

  // Handle excluded medications change
  const handleExcludedMedsChange = async (values: string[]) => {
    setExcludedMeds(values);
    await filterByMedications(includedMeds, values);
  };

  // Handle specialties change
  const handleSpecialtiesChange = async (values: string[]) => {
    setSpecialties(values);
    await filterBySpecialties(values);
  };

  // Handle regions change
  const handleRegionsChange = async (values: string[]) => {
    setRegions(values);
    await filterByRegions(values);
  };

  if (!isInitialized || isLoadingOptions) {
    return (
      <div className="flex flex-col items-center justify-center h-96">
        <div className="flex items-center mb-4">
          <Loader2 className="h-8 w-8 animate-spin text-primary-600 mr-3" />
          <span className="text-lg text-gray-600">Loading providers...</span>
        </div>
        {loadingProgress > 0 && (
          <div className="w-64">
            <div className="bg-gray-200 rounded-full h-2.5">
              <div 
                className="bg-primary-600 h-2.5 rounded-full transition-all duration-500"
                style={{ width: `${loadingProgress}%` }}
              />
            </div>
            <p className="text-sm text-gray-500 text-center mt-2">
              {loadingProgress}% complete
            </p>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <h2 className="text-2xl font-bold">Provider Filter Test</h2>
        <div className="flex items-center space-x-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowDebugPanel(!showDebugPanel)}
            className="flex items-center space-x-2"
          >
            {showDebugPanel ? (
              <ChevronUp className="h-4 w-4" />
            ) : (
              <ChevronDown className="h-4 w-4" />
            )}
            <span>Debug Panel</span>
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={handleDebugClick}
            disabled={isDebugging}
            className="flex items-center space-x-2"
          >
            {isDebugging ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Bug className="h-4 w-4" />
            )}
            <span>Debug Tables</span>
          </Button>
        </div>
      </div>

      {/* Debug Panel */}
      {showDebugPanel && healthCheckResults && (
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap">
          {healthCheckResults}
        </div>
      )}

      {/* Database access error */}
      {dbAccessError && (
        <div className="bg-error-50 border border-error-200 rounded-lg p-4 flex items-start space-x-3">
          <AlertTriangle className="h-5 w-5 text-error-500 flex-shrink-0 mt-0.5" />
          <div className="flex-1">
            <h3 className="text-sm font-medium text-error-800">Database Access Error</h3>
            <p className="mt-1 text-sm text-error-700">{dbAccessError}</p>
          </div>
        </div>
      )}

      {/* Status display */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <div className="flex items-center justify-between">
          <p className="text-lg font-medium">
            Matching Providers: {matchingCount.toLocaleString()}
          </p>
          {isLoading && (
            <div className="flex items-center text-primary-600">
              <Loader2 className="h-5 w-5 animate-spin mr-2" />
              <span>Updating...</span>
            </div>
          )}
        </div>
        {error && (
          <p className="mt-2 text-sm text-error-600 bg-error-50 p-2 rounded">
            {error}
          </p>
        )}
      </div>

      {/* Filter controls */}
      <div className="space-y-4">
        {/* Category filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Medication Category
          </label>
          <Select
            options={[
              { value: '', label: 'All Categories' },
              ...categories.map(cat => ({ value: cat, label: cat }))
            ]}
            value={category}
            onChange={handleCategoryChange}
          />
        </div>

        {/* Included medications */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Include Medications
          </label>
          <MultiSelect
            options={medications.map(med => ({ value: med.id, label: med.name }))}
            value={includedMeds}
            onChange={handleIncludedMedsChange}
          />
        </div>

        {/* Excluded medications */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Exclude Medications
          </label>
          <MultiSelect
            options={medications.map(med => ({ value: med.id, label: med.name }))}
            value={excludedMeds}
            onChange={handleExcludedMedsChange}
          />
        </div>

        {/* Specialties */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Specialties
          </label>
          <MultiSelect
            options={specialtyOptions}
            value={specialties}
            onChange={handleSpecialtiesChange}
          />
        </div>

        {/* Regions */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Regions
          </label>
          <MultiSelect
            options={regionOptions}
            value={regions}
            onChange={handleRegionsChange}
          />
        </div>
      </div>

      {/* Results */}
      <div className="mt-8">
        <h3 className="text-lg font-semibold mb-4">
          Filtered Providers ({matchingCount.toLocaleString()})
        </h3>
        <div className="bg-white shadow overflow-hidden rounded-md">
          {filteredProviders.length > 0 ? (
            <>
              <ul className="divide-y divide-gray-200">
                {filteredProviders.slice(0, 50).map(provider => (
                  <li key={provider.provider_id || `provider-${provider.id}`} className="px-6 py-4">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm font-medium text-gray-900">{provider.name}</p>
                        <p className="text-sm text-gray-500">{provider.specialty}</p>
                      </div>
                      <div className="text-sm text-gray-500">
                        <p>{provider.geographic_area}</p>
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
              {filteredProviders.length > 50 && (
                <div className="px-6 py-4 bg-gray-50 text-center text-sm text-gray-500">
                  Showing first 50 of {filteredProviders.length.toLocaleString()} providers
                </div>
              )}
            </>
          ) : (
            <div className="px-6 py-4 text-center text-sm text-gray-500">
              No providers match the selected filters
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
