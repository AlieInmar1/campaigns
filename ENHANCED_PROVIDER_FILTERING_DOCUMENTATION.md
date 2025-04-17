# Enhanced Provider Filtering System

This document outlines the provider filtering system implemented to improve medication provider targeting based on prescription data.

## System Components

### 1. Database Optimization

The system leverages a pre-aggregated index table (`medication_provider_time_index`) to significantly improve filtering performance:

- **Key Features**:
  - Aggregates prescription data by provider, medication, and month
  - Tracks brand vs. generic prescriptions
  - Distinguishes between new prescriptions and refills
  - Optimized for fast querying with appropriate indexes

### 2. SQL Functions

We've implemented PostgreSQL functions to handle filtering efficiently:

- **`populate_medication_provider_time_index()`** - Aggregates raw prescription data into the index
- **`get_filtered_providers()`** - Main filtering function supporting multiple filter criteria
- **`estimate_filtered_provider_count()`** - Quick estimation of matching provider counts without fetching all records

### 3. TypeScript Service Layer

The `enhancedProviderDataService.ts` file provides a clean API for frontend components:

- **Data Access Functions**:
  - `getMedicationCategories()` - Get available medication categories
  - `getMedicationsByCategory()` - Get medications within a category
  - `getAvailableSpecialties()` - Get available provider specialties
  - `getAvailableRegions()` - Get available geographic regions
  - `getProvidersByEnhancedFilter()` - Apply filters and get providers
  - `getRecommendedSpecialties()` - Smart recommendations based on medication selection

### 4. React Hook

The `useEnhancedProviderFilter` hook provides state management for filtering:

- Maintains filter state and validation
- Handles async operations (loading states, errors)
- Provides utility functions for applying/resetting filters
- Returns estimated counts and filtered provider results

### 5. React Component

The `EnhancedProviderFilter` component provides a complete UI:

- Two-column layout with primary and secondary filters
- Real-time validation and feedback
- Smart recommendations for specialties based on medication selection
- Support for cascading selections (category → medications)

## Filter Approach

The filtering system is designed around primary and secondary filters:

### Primary Filters (at least one required)
- **Provider Specialties** - Filter by medical specialties
- **Medication Category** - Filter by medication therapeutic category
- **Included Medications** - Filter for specific medications

### Secondary Filters (optional)
- **Excluded Medications** - Filter out providers who prescribe these
- **Brand Preference** - Filter for brand name, generic, or both
- **Geographic Regions** - Filter by provider location
- **Timeframe** - Filter by prescription recency (month, quarter, year)

## Usage Example

```tsx
// In a Campaign targeting component
import { EnhancedProviderFilter } from '../providers/EnhancedProviderFilter';

function CampaignTargeting() {
  const handleProvidersFiltered = (providers) => {
    console.log(`Matched ${providers.length} providers`);
    // Update campaign targeting with filtered providers
  };

  return (
    <div>
      <h2>Target Providers</h2>
      <EnhancedProviderFilter 
        onFilterApplied={handleProvidersFiltered}
        onFilterCountChange={(count) => console.log(`Estimated matches: ${count}`)}
        defaultSpecialties={["Cardiology"]}
      />
    </div>
  );
}
```

## How the Filtering Works

1. The UI component collects filter criteria from the user
2. When "Apply" is clicked, the filter is sent to the backend
3. The SQL function `get_filtered_providers` executes an optimized query
4. Results are returned to the frontend
5. Provider details are fetched for the matching provider IDs
6. Results are rendered in the UI and made available via callbacks

The performance improvement comes from:
- Pre-aggregated data in the index table
- Efficient SQL queries using proper indexes
- Pagination/limiting of results when needed
- Separation of counting vs. fetching full provider details

## Technical Notes

1. The filtering system starts with specialty selection as a primary approach, which works well for targeting specific provider groups.
2. The database index includes time-based aggregation for filtering by prescription recency.
3. Smart recommendations feature analyzes prescription patterns to suggest relevant specialties.

## Implementation Status

The current implementation includes:

- ✅ SQL schema and functions for efficient filtering
- ✅ TypeScript service layer for data access
- ✅ React hooks for state management
- ✅ React component UI for filtering

The system is ready for integration with the campaign targeting workflow.
