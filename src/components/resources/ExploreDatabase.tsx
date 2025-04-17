import React, { useState, useEffect, useCallback } from 'react';
import { useEnhancedProviderFilter } from '../../hooks/useEnhancedProviderFilter';
import { Loader2 } from 'lucide-react';
import { 
  getMedicationCategories, 
  getMedicationsByCategory,
  getAvailableSpecialties,
  getAvailableRegions,
} from '../../lib/enhancedProviderDataService';

// Type for medication with simplified fields
interface Medication {
  id: string;
  name: string; // Using name instead of medication_name for compatibility
  category: string;
  subcategory: string;
  is_brand_name: boolean;
  is_target_medication: boolean;
}

// Type for medications organized by category
interface MedicationsByCategory {
  [category: string]: Medication[];
}

export function ExploreDatabase() {
  // Use the enhanced provider filter hook
  const {
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
  } = useEnhancedProviderFilter();

  // State for reference data
  const [categories, setCategories] = useState<string[]>([]);
  const [medications, setMedications] = useState<Medication[]>([]);
  const [medicationsByCategory, setMedicationsByCategory] = useState<MedicationsByCategory>({});
  const [specialtyOptions, setSpecialtyOptions] = useState<string[]>([]);
  const [regionOptions, setRegionOptions] = useState<string[]>([]);
  const [isLoadingOptions, setIsLoadingOptions] = useState(true);
  const [isInitialLoad, setIsInitialLoad] = useState(true); // Track initial load
  
  // Search state
  const [searchTerm, setSearchTerm] = useState('');
  const [filteredMedicationsByCategory, setFilteredMedicationsByCategory] = useState<MedicationsByCategory>({});
  const [filteredSpecialtyOptions, setFilteredSpecialtyOptions] = useState<string[]>([]);
  const [filteredRegionOptions, setFilteredRegionOptions] = useState<string[]>([]);

  // Function to initialize filters but not apply them automatically
  const initializeFilters = useCallback(() => {
    console.log('Initializing filters with default values');
    updateFilters({
      // Default to 'both' for brand preference
      brandPreference: 'both',
      // Default to 'year' for timeframe
      timeframe: 'year',
      // Default to 'all' for gender
      gender: 'all',
    });
    
    // Don't auto-apply filters on initial load to prevent render loops
    console.log('Filters initialized but not auto-applied');
    setIsInitialLoad(false);
  }, [updateFilters]);
  
  // Load reference data
  useEffect(() => {
    console.log('ExploreDatabase component mounted or dependencies changed');
    
    const loadReferenceData = async () => {
      console.log('Starting to load reference data...');
      setIsLoadingOptions(true);
      try {
        // Get medication categories
        console.log('Fetching medication categories...');
        const categoryList = await getMedicationCategories();
        console.log('Medication categories:', categoryList);
        setCategories(categoryList);
        
        // Get all medications
        console.log('Fetching all medications...');
        const allMedications = await getMedicationsByCategory();
        console.log('Got medications:', allMedications.length);
        setMedications(allMedications);
        
        // Organize medications by category
        organizeMedications(allMedications);

        // Get specialties
        console.log('Fetching specialties...');
        const specialties = await getAvailableSpecialties();
        console.log('Specialties:', specialties);
        setSpecialtyOptions(specialties);

        // Get regions
        console.log('Fetching regions...');
        const regions = await getAvailableRegions();
        console.log('Regions:', regions);
        setRegionOptions(regions);
      } catch (error) {
        console.error('Error loading reference data:', error);
      } finally {
        setIsLoadingOptions(false);
        console.log('Finished loading reference data');
        
        // Call the initialization function but don't auto-apply filters
        initializeFilters();
      }
    };

    loadReferenceData();
    
    // Cleanup function to help prevent memory leaks
    return () => {
      console.log('ExploreDatabase component unmounting');
    };
  }, [initializeFilters]); // Only depend on initializeFilters
  
  // Organize medications by category
  const organizeMedications = (meds: Medication[]) => {
    if (!meds || meds.length === 0) return;
    
    console.log('Organizing medications by category');
    const medsByCategory: MedicationsByCategory = {};
    
    meds.forEach(med => {
      if (!med.category) return;
      
      // Initialize category if needed
      if (!medsByCategory[med.category]) {
        medsByCategory[med.category] = [];
      }
      
      // Add medication to the appropriate category
      medsByCategory[med.category].push(med);
    });
    
    console.log('Medications organized by category:', Object.keys(medsByCategory));
    setMedicationsByCategory(medsByCategory);
    setFilteredMedicationsByCategory(medsByCategory); // Initialize filtered medications
  };
  
  // Handle search term change
  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const term = e.target.value.toLowerCase();
    setSearchTerm(term);
    
    // Filter medications
    if (term === '') {
      setFilteredMedicationsByCategory(medicationsByCategory);
      setFilteredSpecialtyOptions(specialtyOptions);
      setFilteredRegionOptions(regionOptions);
      return;
    }
    
    // Filter medications by search term
    const filteredMeds: MedicationsByCategory = {};
    Object.keys(medicationsByCategory).forEach(category => {
      const matchingMeds = medicationsByCategory[category].filter(med => 
        med.name.toLowerCase().includes(term)
      );
      
      if (matchingMeds.length > 0) {
        filteredMeds[category] = matchingMeds;
      }
    });
    
    // Filter specialties by search term
    const filteredSpecs = specialtyOptions.filter(specialty => 
      specialty.toLowerCase().includes(term)
    );
    
    // Filter regions by search term
    const filteredRegs = regionOptions.filter(region => 
      region.toLowerCase().includes(term)
    );
    
    setFilteredMedicationsByCategory(filteredMeds);
    setFilteredSpecialtyOptions(filteredSpecs);
    setFilteredRegionOptions(filteredRegs);
  };

  // Handle category change
  const handleCategoryChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value;
    updateFilter('medicationCategory', value);
  };

  // Handle included medications change
  const handleIncludedMedsChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const options = e.target.options;
    const selectedValues: string[] = [];
    
    for (let i = 0; i < options.length; i++) {
      if (options[i].selected) {
        selectedValues.push(options[i].value);
      }
    }
    
    updateFilter('includedMedications', selectedValues);
  };

  // Handle excluded medications change
  const handleExcludedMedsChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const options = e.target.options;
    const selectedValues: string[] = [];
    
    for (let i = 0; i < options.length; i++) {
      if (options[i].selected) {
        selectedValues.push(options[i].value);
      }
    }
    
    updateFilter('excludedMedications', selectedValues);
  };

  // Handle specialties change
  const handleSpecialtiesChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const options = e.target.options;
    const selectedValues: string[] = [];
    
    for (let i = 0; i < options.length; i++) {
      if (options[i].selected) {
        selectedValues.push(options[i].value);
      }
    }
    
    updateFilter('specialties', selectedValues);
  };

  // Handle regions change
  const handleRegionsChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const options = e.target.options;
    const selectedValues: string[] = [];
    
    for (let i = 0; i < options.length; i++) {
      if (options[i].selected) {
        selectedValues.push(options[i].value);
      }
    }
    
    updateFilter('regions', selectedValues);
  };

  // Handle brand preference change
  const handleBrandPreferenceChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value as 'brand' | 'generic' | 'both';
    updateFilter('brandPreference', value);
  };

  // Handle gender change
  const handleGenderChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const value = e.target.value as 'male' | 'female' | 'all';
    updateFilter('gender', value);
  };

  // Create a handler for manual filter application (even though we won't show the button)
  const handleApplyFilters = useCallback(() => {
    console.log('Manually applying filters:', filter);
    applyFilters();
  }, [applyFilters, filter]);
  
  // Auto-apply filters when they change
  useEffect(() => {
    // Skip initial render
    if (isInitialLoad) return;
    
    // Debounce filter application to prevent too many updates
    const debounceTimer = setTimeout(() => {
      console.log('Auto-applying filters:', filter);
      applyFilters();
    }, 500); // 500ms debounce
    
    return () => clearTimeout(debounceTimer);
  }, [filter, applyFilters, isInitialLoad]);

  // Handle reset filters - with added logging
  const handleResetFilters = useCallback(() => {
    console.log('Resetting filters');
    resetFilters();
  }, [resetFilters]);

  if (isLoadingOptions) {
    return (
      <div className="flex flex-col items-center justify-center h-96">
        <div className="flex items-center mb-4">
          <Loader2 className="h-8 w-8 animate-spin text-primary-600 mr-3" />
          <span className="text-lg text-gray-600">Loading providers...</span>
        </div>
      </div>
    );
  }

  // Effect to update filtered options when the original data changes
  useEffect(() => {
    if (searchTerm === '') {
      setFilteredMedicationsByCategory(medicationsByCategory);
      setFilteredSpecialtyOptions(specialtyOptions);
      setFilteredRegionOptions(regionOptions);
    } else {
      handleSearchChange({ target: { value: searchTerm } } as React.ChangeEvent<HTMLInputElement>);
    }
  }, [medicationsByCategory, specialtyOptions, regionOptions]);

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-6">Explore Database</h2>
      
      {/* Search box */}
      <div className="mb-6">
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Search
        </label>
        <input
          type="text"
          className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
          placeholder="Search medications, specialties, or regions..."
          value={searchTerm}
          onChange={handleSearchChange}
        />
      </div>

      {/* Filter controls */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        {/* Category filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Medication Category
          </label>
          <select
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
            value={filter.medicationCategory || ''}
            onChange={handleCategoryChange}
          >
            <option value="">All Categories</option>
            {categories.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>
        </div>

        {/* Included medications */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Include Medications (hold Ctrl/Cmd to select multiple)
          </label>
          <select
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
            multiple
            size={7}
            value={filter.includedMedications || []}
            onChange={handleIncludedMedsChange}
          >
            {Object.keys(filteredMedicationsByCategory).map(categoryName => (
              <optgroup key={`included-${categoryName}`} label={categoryName}>
                {filteredMedicationsByCategory[categoryName]?.map(med => (
                  <option 
                    key={`included-${med.id}`} 
                    value={med.id}
                  >
                    {med.name} ({med.is_brand_name ? 'Brand' : 'Generic'})
                  </option>
                ))}
              </optgroup>
            ))}
          </select>
        </div>

        {/* Excluded medications */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Exclude Medications (hold Ctrl/Cmd to select multiple)
          </label>
          <select
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
            multiple
            size={7}
            value={filter.excludedMedications || []}
            onChange={handleExcludedMedsChange}
          >
            {Object.keys(filteredMedicationsByCategory).map(categoryName => (
              <optgroup key={`excluded-${categoryName}`} label={categoryName}>
                {filteredMedicationsByCategory[categoryName]?.map(med => (
                  <option 
                    key={`excluded-${med.id}`} 
                    value={med.id}
                  >
                    {med.name} ({med.is_brand_name ? 'Brand' : 'Generic'})
                  </option>
                ))}
              </optgroup>
            ))}
          </select>
        </div>

        {/* Specialties */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Specialties (hold Ctrl/Cmd to select multiple)
          </label>
          <select
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
            multiple
            size={5}
            value={filter.specialties || []}
            onChange={handleSpecialtiesChange}
          >
            {filteredSpecialtyOptions.map(specialty => (
              <option key={specialty} value={specialty}>{specialty}</option>
            ))}
          </select>
        </div>

        {/* Regions */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Regions (hold Ctrl/Cmd to select multiple)
          </label>
          <select
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
            multiple
            size={5}
            value={filter.regions || []}
            onChange={handleRegionsChange}
          >
            {filteredRegionOptions.map(region => (
              <option key={region} value={region}>{region}</option>
            ))}
          </select>
        </div>

        {/* Brand Preference */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Brand Preference
          </label>
          <select
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
            value={filter.brandPreference || 'both'}
            onChange={handleBrandPreferenceChange}
          >
            <option value="both">Both Brand & Generic</option>
            <option value="brand">Brand Only</option>
            <option value="generic">Generic Only</option>
          </select>
        </div>

        {/* Provider Gender */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Provider Gender
          </label>
          <select
            className="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm rounded-md"
            value={filter.gender || 'all'}
            onChange={handleGenderChange}
          >
            <option value="all">All Genders</option>
            <option value="male">Male</option>
            <option value="female">Female</option>
          </select>
        </div>

        {/* Reset button */}
        <div className="flex items-end">
          <button
            type="button"
            className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
            onClick={handleResetFilters}
          >
            Reset Filters
          </button>
        </div>
      </div>

      {/* Results */}
      <div className="bg-white rounded-lg shadow">
        <div className="px-4 py-3 border-b border-gray-200">
          <h3 className="text-lg font-medium">
            Results
          </h3>
        </div>

        {isLoading ? (
          <div className="p-4 text-center text-gray-500">
            <Loader2 className="h-8 w-8 animate-spin text-primary-600 mx-auto mb-2" />
            <p>Loading...</p>
          </div>
        ) : error ? (
          <div className="p-4 text-center text-red-500">{error}</div>
        ) : (
          <div className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-gray-50 p-4 rounded-lg">
                <h4 className="text-lg font-medium text-gray-700 mb-2">Total Matching Providers</h4>
                <p className="text-3xl font-bold text-primary-600">{estimatedCount.toLocaleString()}</p>
              </div>
              
              <div className="bg-gray-50 p-4 rounded-lg">
                <h4 className="text-lg font-medium text-gray-700 mb-2">Total Prescriptions</h4>
                <p className="text-3xl font-bold text-primary-600">
                  {filteredProviders.reduce((total, provider) => total + (provider.prescription_count || 0), 0).toLocaleString()}
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
