# Medication and Prescription Data Migration Guide

This guide outlines the proper sequence for running the migration files to create a comprehensive medication and prescription dataset in your database.

## Migration Sequence

For best results, run the migration files in the following order:

1. **20250330390000_update_medications_schema.sql**
   - Updates the medications table schema to support the comprehensive medication dataset
   - Adds columns for subcategory, specialty, generic_name, is_brand_name, etc.
   - Creates necessary indexes for performance

2. **20250330400000_comprehensive_medication_dataset.sql**
   - Populates the medications table with a rich dataset of medications
   - Includes proper categorization with generic and brand name versions
   - First part of the medication dataset

3. **20250330401000_comprehensive_medication_dataset_part2.sql**
   - Continues populating additional medications
   - Second part of the comprehensive medication dataset

4. **Micro-Batched Patient Prescription Generation with Synthetic Patients**

   Due to the large volume of data being processed, the prescription generation has been split into three micro-batches, each focusing on a single specialty. Each batch uses synthetic patient IDs instead of querying the patients table, which dramatically reduces database load and avoids timeout issues:

   a. **20250330701000_patient_prescription_family_med.sql**
      - Handles only Family Medicine providers
      - Drops and recreates the patient_prescriptions table with proper indexes
      - Sets the batch_id to 1 for tracking
      - Uses a longer statement timeout (5 minutes)

   b. **20250330701100_patient_prescription_internal_med.sql**
      - Handles only Internal Medicine providers
      - Sets the batch_id to 2 for tracking

   c. **20250330701200_patient_prescription_primary_care.sql**
      - Handles only Primary Care providers
      - Sets the batch_id to 3 for tracking

   Each batch:
   - Generates synthetic patient IDs using gen_random_uuid()
   - Creates approximately 150 synthetic patients per provider
   - Generates 250-750 prescriptions per provider (based on volume)
   - Processes each provider individually to avoid window function issues
   - Ensures appropriate medication-to-brand name distribution based on practice type

## Expected Results

After running these migrations in order, you should have:

1. **Updated Medication Table** with comprehensive medication data including:
   - Clear categorization (category, subcategory)
   - Proper relationships between generic and brand name medications
   - Specialty associations
   - Proper flagging of target medications (your company's products)

2. **Comprehensive Patient Prescriptions** with realistic patterns:
   - ~1000 prescriptions per provider (varies by volume designation)
   - ~75 patients per provider
   - Specialty-appropriate medication prescribing
   - Realistic refill patterns and fill dates
   - Proper distribution across time
   - Geographic coherence between patients and providers
   - Proper tracking of which batch created each prescription (via the batch_id column)

## Verifying Success

You can verify the success of the migrations with these SQL queries:

```sql
-- Count medications by category
SELECT category, COUNT(*) FROM medications GROUP BY category ORDER BY COUNT(*) DESC;

-- Check brand vs generic distribution
SELECT is_brand_name, COUNT(*) FROM medications GROUP BY is_brand_name;

-- Check provider prescription counts
SELECT provider_id, COUNT(*) 
FROM patient_prescriptions 
GROUP BY provider_id 
ORDER BY COUNT(*) DESC
LIMIT 10;

-- Check patient counts per provider
SELECT provider_id, COUNT(DISTINCT patient_id) as patient_count
FROM patient_prescriptions
GROUP BY provider_id
ORDER BY patient_count DESC
LIMIT 10;

-- Check specialty-medication alignment
SELECT m.category, p.specialty, COUNT(*) as prescription_count
FROM patient_prescriptions pp
JOIN medications m ON pp.medication_id = m.id
JOIN providers p ON pp.provider_id = p.provider_id
GROUP BY m.category, p.specialty
ORDER BY COUNT(*) DESC
LIMIT 20;
```

## Performance Notes

- Each batch processes providers one-by-one to avoid window function limitations
- All migrations use a shorter statement timeout (5 minutes)
- The loop-based approach generates prescriptions for one provider at a time
- Synthetic patients are generated on-the-fly instead of querying the patients table
- Temporary tables and indexes are used for better performance
- Minimal RAISE NOTICE statements for lightweight progress reporting
- Each batch file is completely independent and can be run in any order (except the first one which creates the table)
- The process is designed to be resumable - if any batch fails, you can fix and re-run just that batch
- You can run queries afterward to generate statistics on the complete dataset

Refer to the README files for more detailed information about each dataset:
- See `COMPREHENSIVE_PATIENT_PRESCRIPTIONS_README.md` for details on the prescription dataset
