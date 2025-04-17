/*
  # Patient Prescriptions: Cardiology Providers with Synthetic Patients
  
  This migration populates the patient_prescriptions table with data for
  Cardiology providers. It uses synthetic patient IDs instead of
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
  batch_id CONSTANT INTEGER := 4;
  specialty_name CONSTANT TEXT := 'Cardiology';
  
  -- Variables for the processing
  provider_count INTEGER;
  medication_count INTEGER;
  patients_per_provider INTEGER := 150; -- Synthetic patients per provider
  total_prescriptions INTEGER := 0;
  
  -- Date range for prescriptions
  start_date DATE := '2023-01-01'::DATE;
  end_date DATE := CURRENT_DATE;
  date_range INTEGER := end_date - start_date;
  
  -- Provider variables
  curr_provider RECORD;
  batch_size INTEGER;
BEGIN
  -- Create temporary table for cardiology medications
  CREATE TEMP TABLE cardio_medications AS
  SELECT 
    id,
    name,
    category,
    is_brand_name
  FROM medications
  WHERE 
    -- Primarily cardiovascular medications
    category = 'Cardiovascular' OR
    -- Some cardiologists also prescribe diabetes medications
    category = 'Diabetes' OR 
    -- Common medications that might be prescribed by any specialist
    name ILIKE '%Aspirin%' OR
    name ILIKE '%statin%' OR
    name ILIKE '%coagulant%' OR
    name ILIKE '%antiplatelet%';
    
  -- Get count of medications for reporting
  SELECT COUNT(*) INTO medication_count FROM cardio_medications;
  RAISE NOTICE 'Found % cardiology-related medications', medication_count;
  
  -- Process each provider individually
  FOR curr_provider IN
    SELECT 
      provider_id,
      CASE
        WHEN prescribing_volume = 'high' THEN 750
        WHEN prescribing_volume = 'medium' THEN 500
        ELSE 250
      END as target_count,
      CASE
        -- Cardiologists tend to prescribe more brand-name medications
        WHEN practice_size IN ('hospital', 'academic') THEN 0.75  -- Much more likely to prescribe brand names
        WHEN practice_size = 'large' THEN 0.65
        WHEN practice_size = 'solo' THEN 0.55  -- Still more likely than average
        ELSE 0.6
      END as brand_preference
    FROM providers
    WHERE specialty = specialty_name
    ORDER BY provider_id
  LOOP
    -- Generate a single batch of prescriptions for this provider
    -- Simpler approach with a single INSERT
    
    -- Create synthetic patients table
    DROP TABLE IF EXISTS temp_patients;
    CREATE TEMP TABLE temp_patients AS
    SELECT 
      gen_random_uuid() as patient_id
    FROM generate_series(1, patients_per_provider);
    
    -- Create filtered medications for this provider's brand preference
    DROP TABLE IF EXISTS provider_medications;
    CREATE TEMP TABLE provider_medications AS
    SELECT 
      id,
      name,
      category
    FROM cardio_medications
    WHERE 
      (is_brand_name = true AND random() < curr_provider.brand_preference) OR
      (is_brand_name = false AND random() > curr_provider.brand_preference);
    
    -- Calculate how many prescriptions to generate
    batch_size := curr_provider.target_count;
    
    -- Single INSERT for all prescriptions
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
    WITH prescription_data AS (
      SELECT 
        curr_provider.provider_id,
        p.patient_id,
        m.id AS medication_id,
        m.name AS medication_name,
        m.category AS medication_category,
        -- Create a random prescription date
        (start_date + (random() * date_range)::INTEGER) AS prescription_date,
        -- Random values for calculations
        random() AS rand_fill,
        random() AS rand_refill,
        random() AS rand_is_new,
        -- Assign row numbers to limit to target count
        ROW_NUMBER() OVER (ORDER BY random()) as row_num
      FROM temp_patients p
      CROSS JOIN provider_medications m
      ORDER BY random()
    )
    SELECT
      provider_id,
      patient_id,
      medication_id,
      medication_name,
      medication_category,
      prescription_date,
      -- Determine if prescription was filled (90% chance)
      CASE WHEN rand_fill < 0.9 
        THEN prescription_date + (random() * 7)::INTEGER
        ELSE NULL
      END AS fill_date,
      -- Determine quantity (depends on medication category)
      CASE WHEN medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
        THEN (ARRAY[30, 60, 90])[1 + floor(random() * 3)::INTEGER]  -- 30, 60, or 90 for chronic
        ELSE 10 + floor(random() * 20)::INTEGER            -- 10-30 for acute
      END AS quantity,
      -- Calculate days supply based on medication category
      CASE WHEN medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
        THEN (ARRAY[30, 60, 90])[1 + floor(random() * 3)::INTEGER]  -- One per day for chronic meds
        ELSE 5 + floor(random() * 10)::INTEGER  -- 5-15 days for acute meds
      END AS days_supply,
      -- Determine refills allowed (depends on medication category)
      CASE WHEN medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
        THEN 2 + floor(random() * 4)::INTEGER  -- 2-5 refills for chronic
        ELSE floor(random() * 3)::INTEGER      -- 0-2 refills for acute
      END AS refills,
      -- Calculate refill number (0 for new, 1-5 for refills)
      CASE WHEN rand_refill < 0.7 
        THEN 0 
        ELSE 1 + floor(random() * 5)::INTEGER 
      END AS refill_number,
      -- Determine if this is a new prescription (70% chance)
      rand_is_new < 0.7 AS is_new,
      batch_id
    FROM prescription_data 
    WHERE row_num <= batch_size;
    
    -- Get number of prescriptions inserted
    GET DIAGNOSTICS batch_size = ROW_COUNT;
    total_prescriptions := total_prescriptions + batch_size;
    
    -- Report progress
    RAISE NOTICE 'Processed Cardiology provider % with % prescriptions', 
      curr_provider.provider_id, batch_size;
  END LOOP;
  
  -- Get total provider count
  GET DIAGNOSTICS provider_count = ROW_COUNT;
  
  -- Report final statistics
  RAISE NOTICE 'Completed batch % with % Cardiology providers and % total prescriptions', 
    batch_id, provider_count, total_prescriptions;
  
  -- Clean up temporary tables
  DROP TABLE IF EXISTS cardio_medications;
  DROP TABLE IF EXISTS temp_patients;
  DROP TABLE IF EXISTS provider_medications;
END $$;

-- Reset statement timeout to default
RESET statement_timeout;

COMMIT;
