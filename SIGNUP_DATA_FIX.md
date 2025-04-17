# User Sign-up Fix: Sample Campaign Data

## Problem

New user sign-ups were failing with the error:

```
Failed to load resource: the server responded with a status of 500 ()
AuthApiError: Database error saving new user
```

After investigating, we found that this was caused by the `copy_sample_data_for_new_user` function. When a new user signs up, this function attempts to copy sample campaigns with hardcoded IDs 'c1', 'c2', 'c3', but these campaigns didn't exist in the database with those exact IDs. Our sample campaigns use random UUIDs instead of these fixed IDs.

## Solution

We've created a new migration script that:

1. Creates a dedicated `sample_campaign_templates` table to store campaign templates for new users
2. Populates this table with the three sample campaigns using fixed IDs ('template1', 'template2', 'template3')
3. Rewrites the `copy_sample_data_for_new_user` function to copy from this template table
4. Adds robust error handling to prevent sign-up failures

## Implementation Details

The new migration script `20250330091000_fix_user_signup_sample_data.sql` includes:

### 1. Campaign Templates Storage

We created a dedicated table for campaign templates:

```sql
CREATE TABLE IF NOT EXISTS public.sample_campaign_templates (
  id VARCHAR(20) PRIMARY KEY, -- Fixed ID for reliable reference
  name VARCHAR(255) NOT NULL,
  target_medication_id UUID,
  -- other fields...
);
```

### 2. Template Campaigns

We populate this table with three sample campaigns:
- CardioGuard Plus Launch
- NeuroBalance Multi-Specialty Initiative
- ImmunoTherapy Access Program

Each with a fixed, reliable ID for easy reference.

### 3. Improved Copy Function

The new `copy_sample_data_for_new_user` function:

- Loops through all templates in the dedicated table
- Creates a campaign for each template
- Adds proper campaign results and script lift data using existing functions
- Includes robust error handling to prevent sign-up failures
- Continues even if one template fails, so partial data is better than no data

### 4. Key Improvements

- **Reliability**: Uses fixed template IDs instead of hoping specific campaigns exist
- **Isolation**: Separates templates from actual campaigns
- **Error Handling**: Prevents failures from cascading into sign-up errors
- **Maintainability**: Makes it easy to update sample campaign templates

## How to Apply the Fix

1. Run the migration script:

```sql
-- In your Supabase SQL Editor or through migration system
\i supabase/migrations/20250330091000_fix_user_signup_sample_data.sql
```

2. Test by creating a new user account

This fix ensures that all new users will receive sample campaign data when they sign up, even if database schema or data changes over time.
