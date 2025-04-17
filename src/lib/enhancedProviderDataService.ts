import { mockDataService, MOCK_REGIONS } from './mockDataService';

/**
 * Enhanced Provider Filter interface
 * At least one primary filter is required
 */
export interface EnhancedProviderFilter {
  // Primary filters (at least one required)
  specialties?: string[];
  medicationCategory?: string | string[];
  includedMedications?: string[];
  
  // Secondary filters
  excludedMedications?: string[];
  brandPreference?: 'brand' | 'generic' | 'both';
  regions?: string[];
  timeframe?: 'month' | 'quarter' | 'year';
  gender?: 'male' | 'female' | 'all';
}

/**
 * Response containing filtered providers with prescription counts
 */
export interface FilteredProviderResponse {
  provider_id: string;
  prescription_count: number;
}

/**
 * Get available medication categories
 */
export async function getMedicationCategories(): Promise<string[]> {
  return mockDataService.getMedicationCategories();
}

/**
 * Get medications by category
 */
export async function getMedicationsByCategory(category?: string | string[]): Promise<any[]> {
  if (Array.isArray(category)) {
    // If multiple categories are provided, fetch medications for each category
    if (category.length === 0) {
      return mockDataService.getMedicationsByCategory(); // Get all medications
    }
    
    // Get medications for each category and combine them
    const medicationsPromises = category.map(cat => mockDataService.getMedicationsByCategory(cat));
    const medicationsByCategory = await Promise.all(medicationsPromises);
    
    // Flatten the array of arrays and remove duplicates
    const allMedications = medicationsByCategory.flat();
    const uniqueMedications = allMedications.filter((med, index, self) => 
      index === self.findIndex(m => m.id === med.id)
    );
    
    return uniqueMedications;
  }
  
  // Single category or undefined (all medications)
  return mockDataService.getMedicationsByCategory(category);
}

/**
 * Get available specialties
 */
export async function getAvailableSpecialties(): Promise<string[]> {
  return mockDataService.getSpecialties();
}

/**
 * Get available regions
 */
export async function getAvailableRegions(): Promise<string[]> {
  const regions = await mockDataService.getRegions();
  return regions.map(region => region.name);
}

/**
 * Validate that the filter has at least one primary filter selected
 */
export function validatePrimaryFilter(filter: EnhancedProviderFilter): boolean {
  return !!(
    (filter.specialties && filter.specialties.length > 0) ||
    (typeof filter.medicationCategory === 'string' && filter.medicationCategory !== '') ||
    (Array.isArray(filter.medicationCategory) && filter.medicationCategory.length > 0) ||
    (filter.includedMedications && filter.includedMedications.length > 0)
  );
}

/**
 * Get estimated provider count based on filter criteria
 */
export async function estimateFilteredProviderCount(filter: EnhancedProviderFilter): Promise<number> {
  // Validate primary filter requirement
  if (!validatePrimaryFilter(filter)) {
    return 0;
  }
  
  // Convert filter to the format expected by mockDataService
  const mockFilter = {
    specialties: filter.specialties,
    regions: filter.regions,
    gender: filter.gender,
    medicationIds: filter.includedMedications,
    excludedMedicationIds: filter.excludedMedications
  };
  
  return mockDataService.estimateProviderCount(mockFilter);
}

/**
 * Get providers filtered by the enhanced filter criteria
 */
export async function getProvidersByEnhancedFilter(
  filter: EnhancedProviderFilter
): Promise<FilteredProviderResponse[]> {
  // Validate primary filter requirement
  if (!validatePrimaryFilter(filter)) {
    throw new Error('At least one primary filter must be selected (specialty, category, or medications)');
  }
  
  // Convert filter to the format expected by mockDataService
  const mockFilter = {
    specialties: filter.specialties,
    regions: filter.regions,
    gender: filter.gender,
    medicationIds: filter.includedMedications,
    excludedMedicationIds: filter.excludedMedications
  };
  
  // Get provider IDs
  const providerIds = await mockDataService.getProvidersByFilter(mockFilter);
  
  // Generate prescription counts for each provider
  return providerIds.map(id => ({
    provider_id: id,
    prescription_count: Math.floor(Math.random() * 500) + 50
  }));
}

/**
 * Get provider details by IDs
 */
export async function getProviderDetailsByIds(providerIds: string[]): Promise<any[]> {
  return mockDataService.getProviderDetails(providerIds);
}

/**
 * Combine filtering and detail fetching in one operation
 */
export async function getFilteredProviderDetails(
  filter: EnhancedProviderFilter,
  limit: number = 500
): Promise<any[]> {
  // Get filtered provider IDs with prescription counts
  const filteredProviders = await getProvidersByEnhancedFilter(filter);
  
  if (!filteredProviders.length) {
    return [];
  }
  
  // Limit the number of providers to fetch details for
  const limitedProviderIds = filteredProviders
    .slice(0, limit)
    .map(p => p.provider_id);
  
  // Fetch provider details
  const providerDetails = await getProviderDetailsByIds(limitedProviderIds);
  
  // Add prescription count to provider details
  return providerDetails.map(provider => {
    const matchingProvider = filteredProviders.find(p => p.provider_id === provider.provider_id);
    return {
      ...provider,
      prescription_count: matchingProvider ? matchingProvider.prescription_count : 0
    };
  });
}

/**
 * Get recommended specialties based on selected medications
 * This helps with smart suggestions when a medication is selected
 */
export async function getRecommendedSpecialties(medicationIds: string[]): Promise<string[]> {
  if (!medicationIds.length) {
    return [];
  }
  
  // Get specialties first, then shuffle and return a subset
  const specialties = await mockDataService.getSpecialties();
  const shuffled = [...specialties].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, 5);
}
