# Sample Campaign Improvements

This document outlines the changes made to improve sample campaign data functionality. The following issues were addressed:

## 1. Sample Campaign Status and Dates

**Problem:** Sample campaigns were created with "Active" status and current dates, but there were inconsistencies between the expected status handling in the frontend.

**Solution:** 
- Changed sample campaigns status from "Active" to "completed" to ensure they show up with results
- Set start_date to 6 months ago and end_date to 1 month ago to place them in the past
- Updated the `create_sample_campaigns_for_user` function to use these settings for new users
- Directly updated existing sample campaigns with the corrected status and dates

**Files:** 
- `supabase/migrations/20250330090600_direct_update_sample_campaigns.sql` (Combined solution that avoids ambiguous column references)

**Note:**  
The original scripts (`20250330090100` and `20250330090500`) had issues with ambiguous column references. The combined fix in `20250330090600` solves this by using:
1. Different variable names to avoid ambiguity
2. A WITH clause for the UPDATE statement

## 2. Campaign Results Structure

**Problem:** Results data was stored in raw campaign_metrics table, but frontend expected a properly structured campaign_results object with nested properties.

**Solution:**
- Created a transformation function to convert raw metrics to properly structured results data
- Generated nested objects for metrics, engagement_metrics, demographic_metrics, roi_metrics, and prescription_metrics
- Data is properly formatted to match what the frontend components expect
- Updated the sample data generation process to create this structured data for all sample campaigns

**File:** `supabase/migrations/20250330090200_create_campaign_results_from_metrics.sql`

## 3. Script Lift Data

**Problem:** Script lift comparison component needed properly structured data to function.

**Solution:**
- Ensured script_lift_data table exists with proper schema
- Created function to generate realistic script lift data for all sample campaigns
- Generated varying metrics based on campaign specialty and medication type
- Added script lift data generation to the user onboarding process

**File:** `supabase/migrations/20250330090300_add_script_lift_data.sql`

## 4. Creative Templates

**Problem:** Both campaign creator and audience explorer sections had 404 errors when trying to load creative templates.

**Solution:**
- Created and populated creative_templates table if it doesn't exist
- Added creative_template_id column to campaigns table if needed
- Assigned creative templates to sample campaigns
- Included a variety of template types: display, email, social, and resource

**File:** `supabase/migrations/20250330090400_ensure_creative_templates_table.sql`

## How to Apply These Changes

These migrations should be run in sequence:

1. `20250330090000_check_campaign_results_structure.sql` - Verifies campaign_results table structure
2. `20250330090600_direct_update_sample_campaigns.sql` - Updates campaign status and dates 
3. `20250330090200_create_campaign_results_from_metrics.sql` - Creates properly structured results
4. `20250330090300_add_script_lift_data.sql` - Adds script lift data for charts and comparisons
5. `20250330090400_ensure_creative_templates_table.sql` - Resolves creative templates 404 errors

**Notes:**
- Skip the original scripts `20250330090100` and `20250330090500` as they have been replaced by `20250330090600`
- All migrations use conditional logic to check if tables/columns already exist, making them safe to run multiple times
