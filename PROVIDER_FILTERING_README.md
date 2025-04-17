# Provider Filtering Service

This document describes the provider filtering service implemented in the marketing reconciliation application. The service allows filtering providers based on various criteria, including medications prescribed, specialties, and geographic regions.

## Overview

The provider filtering service consists of three main components:

1. **Provider Data Service** (`src/lib/providerDataService.ts`): Core service that handles database queries and filtering logic.
2. **Provider List Hook** (`src/hooks/useProviderList.ts`): React hook that provides a convenient interface for components to use the filtering service.
3. **UI Components** (`src/components/resources/ExploreDatabase.tsx`): User interface for interacting with the filtering service.

## Database Structure

The service relies on the following database tables:

- `providers`: Contains provider information (ID, name, specialty, geographic area)
- `patient_prescriptions`: Contains prescription data linking providers to medications
- `medications`: Contains medication information (ID, name, category)
- `feature_flags`: Contains feature flags for enabling/disabling features

## Provider Data Service

The provider data service (`src/lib/providerDataService.ts`) provides the following functions:

- `isPatientPrescriptionsEnabled()`: Checks if the patient prescriptions feature flag is enabled
- `enablePatientPrescriptionsFeature()`: Enables the patient prescriptions feature flag
- `getProvidersByFilter(filter)`: Gets provider IDs based on filter criteria
- `getProvidersByCombinedFilter(filter)`: Gets provider IDs using a more efficient combined query
- `getProviderDetails(providerIds)`: Gets full provider details for a list of provider IDs
- `countProvidersByFilter(filter)`: Counts providers matching filter criteria

### Filter Criteria

The filter criteria is defined by the `ProviderFilter` interface:

```typescript
interface ProviderFilter {
  medicationIds?: string[];        // Medications to include
  excludedMedicationIds?: string[]; // Medications to exclude
  specialties?: string[];          // Specialties to include
  regions?: string[];              // Regions to include
  useAndLogic?: boolean;           // Whether to use AND logic for filters
}
```

## Provider List Hook

The provider list hook (`src/hooks/useProviderList.ts`) provides a React hook that components can use to access the filtering functionality. It handles:

- Loading initial provider data
- Managing filter state
- Applying filters
- Tracking loading state and errors

### Usage

```typescript
const {
  filteredProviders,    // Array of providers matching filters
  matchingCount,        // Total count of matching providers
  isLoading,            // Whether data is currently loading
  error,                // Any error that occurred
  filterByCategory,     // Function to filter by medication category
  filterByMedications,  // Function to filter by specific medications
  filterBySpecialties,  // Function to filter by specialties
  filterByRegions,      // Function to filter by regions
  resetFilters          // Function to reset all filters
} = useProviderList();
```

## Performance Considerations

The service is designed to handle large datasets efficiently:

1. **Chunking**: Large queries are broken into smaller chunks to avoid timeouts and memory issues
2. **Lazy Loading**: Only a sample of providers is loaded initially, with more loaded as needed
3. **Combined Queries**: When possible, filters are combined into a single query for better performance
4. **Feature Flags**: The patient prescriptions feature can be enabled/disabled as needed

## Example Usage

```typescript
// Filter providers by category
filterByCategory('ACE Inhibitor');

// Filter providers by medications
filterByMedications(['med-123', 'med-456'], ['med-789']);

// Filter providers by specialties
filterBySpecialties(['Cardiology', 'Internal Medicine']);

// Filter providers by regions
filterByRegions(['Northeast', 'West']);

// Reset all filters
resetFilters();
```

## UI Components

The `ExploreDatabase` component provides a user interface for filtering providers. It includes:

- Dropdown for selecting medication category
- Multi-select for including/excluding specific medications
- Multi-select for filtering by specialties
- Multi-select for filtering by regions
- Results table showing matching providers

## Future Improvements

Potential future improvements to the provider filtering service:

1. **Pagination**: Add pagination to the results table for better performance with large result sets
2. **Saved Filters**: Allow users to save and reuse filter combinations
3. **Export**: Add ability to export filtered provider lists
4. **Advanced Filtering**: Add more advanced filtering options (e.g., prescription date ranges, prescription counts)
5. **Performance Optimizations**: Further optimize database queries for large datasets
