# Ambiguous Column Reference Fix

## Problem

When running the `update_sample_campaign_status_dates.sql` migration, the following error occurred:

```
ERROR:  42702: column reference "start_date" is ambiguous
DETAIL:  It could refer to either a PL/pgSQL variable or a table column.
QUERY:  UPDATE public.campaigns
  SET
    status = 'completed',
    start_date = start_date,
    end_date = end_date
  WHERE
    is_sample = TRUE
CONTEXT:  PL/pgSQL function update_existing_sample_campaigns() line 9 at SQL statement
```

## Root Cause

The error occurred because in the `update_existing_sample_campaigns()` function, there was an ambiguity between:

1. The PL/pgSQL variables `start_date` and `end_date` declared in the function
2. The columns `start_date` and `end_date` in the `campaigns` table

When PostgreSQL sees the following statement:

```sql
UPDATE public.campaigns
SET
  status = 'completed',
  start_date = start_date,  
  end_date = end_date       
WHERE
  is_sample = TRUE;
```

It cannot determine if you're referring to the local variables or the column names, since they have the same names.

## Solution

To fix this issue, we've created a new migration (`20250330090500_fix_ambiguous_column_reference.sql`) that properly qualifies the variable references:

```sql
UPDATE public.campaigns
SET
  status = 'completed',
  start_date = update_existing_sample_campaigns.start_date,
  end_date = update_existing_sample_campaigns.end_date
WHERE
  is_sample = TRUE;
```

By explicitly qualifying the variable names with the function name (`update_existing_sample_campaigns.start_date`), we tell PostgreSQL to use the variables defined in the function scope rather than the column names.

## Best Practices to Avoid This Issue

1. Use different names for PL/pgSQL variables vs. column names (e.g., `p_start_date` for parameters or variables)
2. Always qualify ambiguous names when both a column and variable/parameter share the same name
3. When assigning values in SQL statements, be explicit about which is the source and which is the target

## Migration Execution Order

Apply this fix after the original migration:

1. First run `20250330090100_update_sample_campaign_status_dates.sql` (original)
2. Then run `20250330090500_fix_ambiguous_column_reference.sql` (fix)

The fix migration replaces the function definition and executes it again to apply the correct date values to sample campaigns.
