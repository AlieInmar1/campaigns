/*
  # Patient Prescriptions: Internal Medicine Providers with Synthetic Patients
  
  This migration populates the patient_prescriptions table with data for
  Internal Medicine providers. It uses synthetic patient IDs instead of
  querying the actual patients table, greatly reducing database load.
*/

-- Set a longer statement timeout for this large operation (5 minutes)
SET statement_timeout = '300000';

-- Start transaction
BEGIN;

-- Main procedure to generate prescriptions
DO $$
DECLARE
  -- Batch identifier
  batch_id CONSTANT INTEGER := 2;
  specialty_name CONSTANT TEXT := 'Internal Medicine';
  
  -- Variables for the processing
  provider_count INTEGER;
  patients_per_provider INTEGER := 150; -- Synthetic patients per provider
  
  -- Date range for prescriptions
  start_date DATE := '2023-01-01'::DATE;
  end_date DATE := CURRENT_DATE;
  date_range INTEGER := end_date - start_date;
  
  -- Provider variables for patient generation
  curr_provider_id TEXT;
  curr_brand_preference NUMERIC;
  curr_target_count INTEGER;
BEGIN
  -- Create temporary table for this batch's providers
  CREATE TEMP TABLE temp_batch_providers AS
  SELECT 
    provider_id,
    CASE
      WHEN prescribing_volume = 'high' THEN 750
      WHEN prescribing_volume = 'medium' THEN 500
      ELSE 250
    END as target_prescription_count,
    CASE
      WHEN practice_size IN ('hospital', 'academic') THEN 0.7  -- More likely to prescribe brand names
      WHEN practice_size = 'large' THEN 0.6
      WHEN practice_size = 'solo' THEN 0.45  -- Less likely to prescribe brand names
      ELSE 0.55
    END as brand_preference
  FROM providers
  WHERE specialty = specialty_name
  ORDER BY provider_id;
  
  -- Get count of providers for reporting
  SELECT COUNT(*) INTO provider_count FROM temp_batch_providers;
  
  -- Find appropriate medications for internal medicine providers
  CREATE TEMP TABLE temp_batch_medications AS
  SELECT 
    id,
    name,
    category,
    is_brand_name
  FROM medications;
  
  -- Process each provider individually to avoid window function issues
  FOR curr_provider_id, curr_brand_preference, curr_target_count IN 
    SELECT provider_id, brand_preference, target_prescription_count 
    FROM temp_batch_providers
  LOOP
    -- Generate prescriptions for the current provider only
    INSERT INTO patient_prescriptions (
      provider_id,
      patient_id,
      medication_id,
      medication_name,
      medication_category,
      prescription_date,
      fill_date,
      quantity,
      days_supply,
      refills,
      refill_number,
      is_new,
      batch_id
    )
    WITH provider_patients AS (
      -- Generate synthetic patients specifically for this provider
      SELECT 
        gen_random_uuid() as patient_id,
        generate_series as patient_num 
      FROM generate_series(1, patients_per_provider)
    ),
    medication_candidates AS (
      -- Select medications with brand preference filter
      SELECT 
        m.id, 
        m.name, 
        m.category,
        -- Only keep rows that match the brand name preference
        CASE WHEN m.is_brand_name = true THEN 
          CASE WHEN random() < curr_brand_preference THEN true ELSE false END
        ELSE
          CASE WHEN random() > curr_brand_preference THEN true ELSE false END
        END as keep_medication
      FROM temp_batch_medications m
    ),
    prescription_base AS (
      -- Generate all possible prescription combinations
      SELECT
        pp.patient_id,
        mc.id as medication_id,
        mc.name as medication_name,
        mc.category as medication_category,
        -- Limit rows using row_number to hit our target count
        ROW_NUMBER() OVER (ORDER BY random()) as rn
      FROM provider_patients pp
      CROSS JOIN medication_candidates mc
      WHERE mc.keep_medication = true
    )
    SELECT
      curr_provider_id as provider_id,
      patient_id,
      medication_id,
      medication_name,
      medication_category,
      -- Create a random prescription date
      (start_date + (random() * date_range)::INTEGER) AS prescription_date,
      -- Determine if prescription was filled (90% chance)
      CASE WHEN random() < 0.9 
        THEN (start_date + (random() * date_range)::INTEGER) + (random() * 7)::INTEGER
        ELSE NULL
      END AS fill_date,
      -- Determine quantity (depends on medication category)
      CASE WHEN medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
        THEN (ARRAY[30, 60, 90])[floor(random() * 3) + 1]  -- 30, 60, or 90 for chronic
        ELSE 10 + floor(random() * 20)::INTEGER            -- 10-30 for acute
      END AS quantity,
      -- Calculate days supply based on medication category
      CASE WHEN medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
        THEN (ARRAY[30, 60, 90])[floor(random() * 3) + 1]  -- One per day for chronic meds
        ELSE 5 + floor(random() * 10)::INTEGER  -- 5-15 days for acute meds
      END AS days_supply,
      -- Determine refills allowed (depends on medication category)
      CASE WHEN medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
        THEN 2 + floor(random() * 4)::INTEGER  -- 2-5 refills for chronic
        ELSE floor(random() * 3)::INTEGER      -- 0-2 refills for acute
      END AS refills,
      -- Calculate refill number (0 for new, 1-5 for refills)
      CASE WHEN random() < 0.7 
        THEN 0 
        ELSE 1 + floor(random() * 5)::INTEGER 
      END AS refill_number,
      -- Determine if this is a new prescription (70% chance)
      random() < 0.7 AS is_new,
      batch_id
    FROM prescription_base
    WHERE rn <= curr_target_count;
    
    -- Report progress for this provider
    RAISE NOTICE 'Processed provider % with % target prescriptions', 
      curr_provider_id, curr_target_count;
  END LOOP;
  
  -- Report final statistics
  RAISE NOTICE 'Completed batch % with % Internal Medicine providers and % synthetic patients each', 
    batch_id, provider_count, patients_per_provider;
  
  -- Clean up temporary tables
  DROP TABLE IF EXISTS temp_batch_providers;
  DROP TABLE IF EXISTS temp_batch_medications;
END $$;

-- Reset statement timeout to default
RESET statement_timeout;

COMMIT;
