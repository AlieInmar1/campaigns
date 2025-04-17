# Patient Prescriptions Data Generation

## Problem

We encountered an issue when trying to generate prescription data for patients. The error was:

```
ERROR: 42703: column "patient_id" of relation "prescriptions" does not exist
```

This occurred because we were trying to use the existing `prescriptions` table, but that table has a different schema than what we needed for patient-level prescription data.

## Solution

We implemented a two-part solution:

1. Created a new table called `patient_prescriptions` specifically for patient-level prescription data
2. Modified our data generation script to use this new table instead of the existing `prescriptions` table

### Migration Files

1. **20250330120000_check_prescriptions_table_structure.sql**
   - Diagnostic script to check the structure of existing tables
   - Helps identify schema differences and issues

2. **20250330125000_create_patients_table.sql**
   - Creates the patients table needed for patient-level prescription data
   - Sets up appropriate indexes and RLS policies

3. **20250330130000_create_patient_prescriptions_table.sql**
   - Creates a new table `patient_prescriptions` with the schema we need for patient-level data
   - Sets up appropriate indexes and RLS policies

4. **20250330140000_generate_patient_prescriptions.sql**
   - Generates 10,000 prescriptions per provider
   - Populates the patients table if needed
   - Ensures prescriptions are related to provider specialties
   - Includes a mix of new and refill prescriptions

5. **20250330150000_fix_patient_prescriptions_generation.sql**
   - Fixes issues with NULL provider_ids in the prescription generation
   - Adds robust error handling to prevent failures
   - Includes transaction handling for each provider
   - Adds validation checks before inserting data
   - Limits to 10 providers for testing purposes

6. **20250330180000_simplified_data_population.sql**
   - Simplified version that doesn't use savepoints (which caused syntax errors)
   - Uses nested exception blocks for error handling
   - Generates patients (up to 100,000)
   - Generates prescriptions for 10 providers (1,000 per provider)
   - Includes detailed progress reporting and summary statistics

## Table Structure Differences

### Existing `prescriptions` Table (Campaign-Level)
The existing `prescriptions` table is designed for campaign-level aggregated data:
- Has `campaign_id` as a foreign key
- Contains aggregated metrics like `baseline_count` and `current_count`
- Includes campaign-specific fields like `is_target` and `is_competitor`

### New `patient_prescriptions` Table (Patient-Level)
The new table is designed for individual patient prescription records:
- Has `patient_id` as a foreign key
- Contains prescription-specific fields like `prescription_date`, `fill_date`, `quantity`, etc.
- Includes refill information like `refills` and `refill_number`

## Data Generation Details

The prescription generation process:
1. Creates 100,000 patient records (if they don't already exist)
2. For each provider:
   - Selects medications appropriate for their specialty
   - Selects patients primarily from their geographic region
   - Generates 10,000 prescriptions with realistic distribution:
     - 60% of patients have multiple prescriptions (1-6)
     - 40% of prescriptions are refills
     - 80% of medications are specialty-appropriate
     - Prescription dates span the last year

## Usage

These migrations should be run in order:
1. First run `20250330120000_check_prescriptions_table_structure.sql` (optional, for diagnostics)
2. Then run `20250330125000_create_patients_table.sql` to create the patients table
3. Next run `20250330130000_create_patient_prescriptions_table.sql` to create the patient prescriptions table
4. Run `20250330140000_generate_patient_prescriptions.sql` to generate the data
   - If this fails with a NULL provider_id error, proceed to step 5
5. Run `20250330150000_fix_patient_prescriptions_generation.sql` to generate data with improved error handling
   - If this fails with a syntax error about savepoints, proceed to step 6
6. Run `20250330180000_simplified_data_population.sql` to generate data with a simplified approach that doesn't use savepoints

The data generation scripts include summary queries at the end that show prescription counts by specialty and medication category. All versions are limited to 10 providers for testing purposes, but you can remove this limit by editing the script if needed.

For more details on the simplified data population approach, see the `SIMPLIFIED_DATA_POPULATION_README.md` file.
