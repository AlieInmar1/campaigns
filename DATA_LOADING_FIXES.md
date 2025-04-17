# Campaign Data and UI Display Fixes

This document outlines the fixes implemented to resolve the issues with displaying campaign data in the Dashboard and Prescription Impact tabs.

## Issues Addressed

1. **Missing Prescription Impact Data**: The prescription impact tab was showing no data.
2. **Empty Dashboard Sections**: The dashboard was missing data in various sections.
3. **404 Error on Creative Templates**: The original error related to missing creative templates in the API.
4. **SQL Loop Variable Error**: PL/pgSQL syntax errors in FOR loops in migration scripts.

## Solution Components

We've created several SQL migration scripts to fix these issues:

### 1. Fix Ambiguous Column Reference (Script 090600)

- Fixed the issue with ambiguous column references in the update statement
- Used different naming conventions for PL/pgSQL variables vs. table columns
- Implemented a WITH clause for cleaner SQL that avoids ambiguity

### 2. Verify and Fix Results Data (Script 090700 & 090750)

- Checks if campaign_results data exists for all campaigns
- Verifies script_lift_data exists for all campaigns
- Ensures campaign_results have proper nested structure
- Fixes campaign statuses to ensure they're all "completed"
- Makes sure all sample campaigns have past dates
- Fixed PL/pgSQL loop variable declaration issue (Script 090750)

### 3. Force Load Sample Campaign Data (Script 090800 & 090850)

- Creates robust functions to generate properly structured data
- Forces regeneration of campaign_results with nested JSONB structure
- Creates script_lift_data for all campaigns
- Ensures creative_templates exist and are assigned to campaigns
- Rebuilds all necessary data for the UI components
- Fixed additional PL/pgSQL loop variable declaration issue (Script 090850)

## How to Run the Scripts

**Run these scripts in order:**

1. `20250330090600_direct_update_sample_campaigns.sql` - Fixes ambiguous column references
2. `20250330090950_final_fix_all_functions.sql` - Fully fixes all PL/pgSQL functions with proper error handling
3. `20250330091000_fix_user_signup_sample_data.sql` - Fixes user sign-up and sample data copying

**Important Notes:**
- The scripts must be run in order as each builds on the previous ones
- Script `090950` properly drops and recreates all functions with correct parameter names and error handling
- Script `091000` fixes the user sign-up process by creating a dedicated table for sample campaign templates
- You can skip all intermediate scripts (`090700`, `090750`, `090755`, `090800`, `090850`, `090855`, `090900`)

## Key Functions Fixed

## Key Functions and Fixes

Functions fixed by script `090950`:
1. `generate_script_lift_data` - Creates script lift data with comprehensive error handling
2. `ensure_script_lift_data` - Simplified wrapper that correctly calls the fixed generate function
3. `force_regenerate_campaign_data` - Properly handles errors for a single campaign
4. `force_regenerate_all_campaign_data` - Properly loops through all campaigns with error handling

Functions added by script `091000`:
1. `copy_sample_data_for_new_user` - Completely rewritten to use template table instead of hardcoded campaign IDs

All functions now have:
- Proper parameter naming (p_campaign_id instead of campaign_id)
- Full error handling with try/catch blocks
- Local variable extraction with defaults
- Table aliases to avoid ambiguity

## Data Structure Fixes

We addressed several structural issues:

1. **Campaign Results Structure**: Campaign results now have properly structured nested JSONB fields:
   - metrics
   - engagement_metrics
   - demographic_metrics
   - roi_metrics
   - prescription_metrics

2. **Script Lift Data Structure**: We ensure each campaign has:
   - lift_percentage
   - baseline
   - projected
   - confidence_score

3. **Creative Templates**: We ensure:
   - The creative_templates table exists
   - It has sample templates of different types
   - Campaigns have a creative_template_id column
   - All campaigns are assigned a template

4. **PL/pgSQL Syntax Fixes**:
   - Added proper UUID type declaration for loop variables
   - Fixed ambiguous reference to campaign_id in loops
   - Created a proper standalone function for regenerating all campaign data

## Frontend Component Fixes

1. **ScriptLiftComparison Component**: Modified to directly fetch script lift data without checking creative templates.

## Expected Results After Fixes

After running these scripts:

1. The dashboard should display metrics, charts and visualizations
2. The prescription impact tab should show script lift data
3. The 404 error for creative templates should be resolved

If you're still experiencing issues after running these scripts, you may need to reload the application to clear any cached state.
