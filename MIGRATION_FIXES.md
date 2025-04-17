# Migration Fixes for Sample Data and Creative Templates

This document outlines the fixes implemented for three issues:

1. SQL Error in sample data architecture migration files
2. 404 error accessing creative_templates table
3. PostgreSQL ANYELEMENT type error and nested dollar-quoted string syntax error

## 1. Sample Data Architecture Fix

### Problem Identified

The original sample data architecture was split into two files:
- `20250330072827_sample_data_architecture.sql`
- `20250330072827_sample_data_architecture_part2.sql`

The error occurred because the first file ended with an incomplete SQL function definition:
```
ERROR: 42601: unterminated dollar-quoted string at or near "$$
DECLARE
  diabetes_campaign_id UUID;
  [...]
LINE 723: RETURNS VOID AS $$
```

This happened because the `create_sample_campaigns_for_user` function started in the first file but wasn't properly terminated before the end of the file. The second file then tried to continue the function, which isn't valid SQL syntax.

### Solution Implemented

To fix this issue, we created a logical split of the migration into four self-contained files:

1. **Tables and Basic Functions** (Part 1: `20250330075000_sample_data_tables_and_functions.sql`)
   - Defines all sample data tables: provider_targets, prescriptions, campaign_metrics
   - Creates helper utility functions (random_int, random_date, etc.)
   - Sets up necessary indexes

2. **Provider and Medication Generation** (Part 2: `20250330075100_sample_provider_medication_generation.sql`)
   - Functions for generating provider data
   - Functions for generating medication data
   - Test function to execute both generators

3. **Campaign Metrics Functions** (Part 3: `20250330075200_sample_campaign_metrics_functions.sql`)
   - Functions for generating campaign targets
   - Functions for generating prescription data
   - Functions for generating metrics
   - Master function to orchestrate data generation

4. **User Data Assignment** (Part 4: `20250330075300_sample_user_data_assignment.sql`)
   - Creating and assigning campaigns to users
   - Functions to copy sample data to user accounts
   - Trigger setup for new user signup

Each file is completely self-contained with proper BEGIN/COMMIT statements and contains only complete function definitions, eliminating the original error.

## 2. Creative Templates Fix

### Problem Identified

The error `vemjcmefzurxujqcxpib.supabase.co/rest/v1/creative_templates?select=*:1 Failed to load resource: the server responded with a status of 404 ()` indicated that the `creative_templates` table was either missing or improperly configured.

### Solution Implemented

Created migration `20250330073500_fix_creative_templates_table.sql` which:

1. Creates the `creative_templates` table if it doesn't exist:
   ```sql
   CREATE TABLE IF NOT EXISTS public.creative_templates (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     name VARCHAR(255) NOT NULL,
     description TEXT,
     headline TEXT NOT NULL,
     body TEXT NOT NULL,
     cta TEXT NOT NULL,
     image_url TEXT,
     theme VARCHAR(100),
     created_by UUID REFERENCES auth.users(id),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
   );
   ```

2. Sets up Row Level Security (RLS) policies to control access:
   - Everyone can view templates
   - Users can create their own templates
   - Users can update/delete their own templates
   - Admins can update/delete any template

3. Adds default template examples for common use cases:
   - Clinical Study Results
   - New Treatment Option
   - Patient Support Program

4. Creates a reusable `fix_creative_templates()` function that can be called from other migrations if needed.

## 3. PostgreSQL Type Issues

### Problem 1: ANYELEMENT Type Error

After implementing the split migrations, we encountered a PostgreSQL error:

```
ERROR: 0A000: variable "result" has pseudo-type anyelement
CONTEXT: compilation of PL/pgSQL function "random_array_element" near line 3
```

This error occurs because PostgreSQL can't handle local variables with polymorphic types (like `ANYELEMENT`) in PL/pgSQL functions. The issue was in the `random_array_element` function that uses a generic type to pick a random item from an array of any type.

### Solution for ANYELEMENT Type Error

We converted the `random_array_element` function from a PL/pgSQL function to a SQL function:

```sql
-- OLD VERSION (problematic)
CREATE OR REPLACE FUNCTION public.random_array_element(arr ANYARRAY)
RETURNS ANYELEMENT AS $$
DECLARE
  result ANYELEMENT;  -- This caused the error
BEGIN
  SELECT arr[1 + floor(random() * array_length(arr, 1))::INTEGER] INTO result;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- NEW VERSION (fixed)
CREATE OR REPLACE FUNCTION public.random_array_element(arr ANYARRAY)
RETURNS ANYELEMENT AS $$
  SELECT arr[1 + floor(random() * array_length(arr, 1))::INTEGER];
$$ LANGUAGE sql;
```

The SQL function handles polymorphic types better than PL/pgSQL, as it doesn't need to declare local variables.

### Problem 2: Nested Dollar-Quoted String Syntax Error

When implementing the preceding function within a DO block for conditional creation, we encountered another error:

```
ERROR: 42601: syntax error at or near "SELECT"
LINE 13: SELECT arr[1 + floor(random() * array_length(arr, 1))::INTEGER];
```

This error occurred because of nested dollar-quoted strings with the same identifier. In PostgreSQL, when nesting dollar-quoted strings, each level must use a different identifier.

### Solution for Nested Dollar-Quote Error

We fixed the issue by using different dollar-quote identifiers for the nested function definition:

```sql
-- PROBLEMATIC VERSION (syntax error)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'random_array_element'
  ) THEN
    EXECUTE $func$
      CREATE OR REPLACE FUNCTION public.random_array_element(arr ANYARRAY)
      RETURNS ANYELEMENT AS $$  -- This $$ conflicts with the outer $$
        SELECT arr[1 + floor(random() * array_length(arr, 1))::INTEGER];
      $$ LANGUAGE sql;         -- This $$ also conflicts
    $func$;
  END IF;
END $$;

-- FIXED VERSION
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'random_array_element'
  ) THEN
    EXECUTE $func$
      CREATE OR REPLACE FUNCTION public.random_array_element(arr ANYARRAY)
      RETURNS ANYELEMENT AS $body$  -- Using $body$ instead of $$ for inner quotes
        SELECT arr[1 + floor(random() * array_length(arr, 1))::INTEGER];
      $body$ LANGUAGE sql;         -- Matching $body$ tag
    $func$;
  END IF;
END $$;
```

We implemented this fix in all three dependent migration files to ensure consistency.

## Using the Fixed Migrations

To apply these fixes, run the migrations in this order:

1. Fix creative templates:
   ```
   supabase migration apply 20250330073500_fix_creative_templates_table.sql
   ```

2. Apply the modular sample data architecture migrations:
   ```
   supabase migration apply 20250330075000_sample_data_tables_and_functions.sql
   supabase migration apply 20250330075100_sample_provider_medication_generation.sql
   supabase migration apply 20250330075200_sample_campaign_metrics_functions.sql
   supabase migration apply 20250330075300_sample_user_data_assignment.sql
   ```

Each migration is independent and properly self-contained, eliminating the parsing errors from the original implementation.

## Advantages of the New Migration Structure

1. **Modularity**: Each file focuses on a specific aspect of the sample data architecture
2. **Self-containment**: No function definitions span across multiple files
3. **Maintainability**: Easier to understand, debug, and extend
4. **Reliability**: Proper BEGIN/COMMIT blocks in each file ensure atomic operations
5. **Reusability**: Functions are grouped logically for potential reuse in other contexts
6. **Type Safety**: Proper handling of polymorphic types in PostgreSQL functions
7. **Syntax Correctness**: Proper nesting of dollar-quoted strings

## Validation

After applying these migrations:

1. The 404 error for creative_templates should no longer appear
2. Sample data should be properly generated for new users
3. The system should function correctly in both the Campaign Creator and Audience Explorer components
4. No PostgreSQL errors related to ANYELEMENT types or nested dollar-quotes
