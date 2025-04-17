# User Signup and Profile Creation Fixes

This document outlines the fixes implemented to address issues with user signup, profile creation, and the "missing FROM-clause entry for table 'old'" error.

## Problem Description

When a new user signs up, the system was encountering an error:

```
ERROR: 42P01: missing FROM-clause entry for table "old"
```

This error occurs in PostgreSQL when a trigger function tries to reference the `OLD` record in an `INSERT` trigger. Since `INSERT` operations don't have an `OLD` record (only `NEW`), this causes the error.

## Solution

We've implemented several fixes to address this issue:

### 1. Fixed Trigger Functions

The main issue was in the `handle_new_user()` trigger function, which was incorrectly trying to reference the `OLD` record during an `INSERT` operation. We've updated this function to:

- Only reference the `NEW` record in `INSERT` triggers
- Properly create a profile for new users
- Assign sample campaigns to new users
- Generate sample campaign results and script lift data

### 2. Updated Timestamp Functions

We've also updated all timestamp-related trigger functions to properly handle both `INSERT` and `UPDATE` operations:

- For `INSERT` operations, both `created_at` and `updated_at` are set to the current time
- For `UPDATE` operations, only `updated_at` is updated

### 3. Fixed RLS Policies

We've updated the Row Level Security (RLS) policies for the profiles table to ensure that:

- Users can view their own profiles
- Users can update their own profiles

### 4. Ensured Correct Table Structure

We've added a check to ensure the profiles table has the correct structure, including a `role` column with a default value of 'user'.

## Migration Files

The fixes are implemented in the following migration files:

1. `20250330210000_fix_user_signup_profile_creation.sql` - Initial fix for user signup and profile creation
2. `20250330220000_fix_old_reference_error.sql` - Specific fix for the "missing FROM-clause entry for table 'old'" error
3. `20250330230000_combined_user_signup_and_old_reference_fix.sql` - Combined fix that addresses all issues

## Testing

To test these fixes:

1. Apply the migration: `npx supabase migration up`
2. Create a new user through the signup process
3. Verify that a profile is created for the user
4. Verify that sample campaigns are assigned to the user
5. Verify that sample campaign results and script lift data are generated

## Additional Notes

- The `handle_new_user()` function is set to `SECURITY DEFINER` to ensure it has the necessary permissions to create profiles and update campaigns.
- The sample data generation functions are designed to create realistic-looking data for new users.
- All trigger functions now properly check the operation type (`TG_OP`) before attempting to reference `OLD` or `NEW` records.
