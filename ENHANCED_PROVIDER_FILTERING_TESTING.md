# Testing Guide for Enhanced Provider Filtering

This guide outlines the steps to test the enhanced provider filtering functionality we've implemented.

## Prerequisites

1. Ensure the database migration has been applied:
   - The SQL migration in `supabase/migrations/20250330900000_create_provider_filtering_index.sql` should be executed against your database
   - This creates the optimized index table and filtering functions

## Setup Steps

1. **Replace the Campaign Creator component:**
   ```bash
   # Backup the original first (optional)
   cp src/components/campaigns/CampaignCreator.tsx src/components/campaigns/CampaignCreator.tsx.backup
   
   # Replace with the new version
   cp src/components/campaigns/CampaignCreator.tsx.new src/components/campaigns/CampaignCreator.tsx
   ```

2. **Start the development server:**
   ```bash
   npm run dev
   ```

## Testing Flow

### Test 1: Basic Functionality

1. Navigate to the Campaign Creator page
2. Verify the "Using Enhanced Filtering" toggle is visible and enabled by default
3. Fill in a campaign name in Step 1
4. Proceed to Step 2 (Provider Targeting)
5. Verify the enhanced provider filter interface appears with:
   - Primary filter section (specialties, medication category, included medications)
   - Secondary filter section (excluded medications, brand preference, regions, timeframe)
6. Select a specialty (e.g., "Cardiology")
7. Verify the estimated provider count updates

### Test 2: Specialty Recommendations

1. In Step 2, select a medication category
2. Select one or more specific medications
3. Verify that specialty recommendations appear based on the selected medications
4. Click on a recommended specialty tag to add it to your selection
5. Click "Apply all recommendations" to select all recommended specialties

### Test 3: Enhanced vs. Standard Mode

1. Click the "Using Enhanced Filtering" toggle to switch to standard mode
2. Verify that the flow changes from 4 steps to 5 steps
3. Navigate through the standard filtering steps
4. Toggle back to enhanced mode
5. Verify the steps change back to the streamlined 4-step process

### Test 4: Filter Result Integration

1. In enhanced mode, configure filters in Step 2 to target specific providers
2. Note the estimated provider count
3. Proceed to Step 3 (Review)
4. Verify the selected filters are shown in the review summary
5. Proceed to identity matching and complete the campaign creation
6. Verify the campaign is created with the correct target providers

## Troubleshooting

### Database Issues

If the provider count always shows zero or filtering doesn't work:

1. Check that the migration was successfully applied:
   ```sql
   SELECT * FROM medication_provider_time_index LIMIT 10;
   ```

2. Verify the index has data:
   ```sql
   SELECT COUNT(*) FROM medication_provider_time_index;
   ```

3. Try manually running the index population function:
   ```sql
   SELECT populate_medication_provider_time_index();
   ```

### React Component Issues

1. Check the browser console for JavaScript errors
2. Verify that all new components are properly imported 
3. If components aren't rendering correctly, try clearing your browser cache

## Performance Testing

For large datasets, test the performance:

1. Time how long it takes for filter updates to complete
2. Compare with the previous filtering approach
3. Test with increasingly complex filter combinations to evaluate scaling
