/*
  # Patient Prescriptions: Multiple Specialties with Synthetic Patients (Batch 1)
  
  This migration populates the patient_prescriptions table with data for five
  different provider specialties:
  1. Cardiology
  2. Cardiac Surgery
  3. Neurology
  4. Psychiatry
  5. Gastroenterology
  
  It uses synthetic patient IDs rather than querying the actual patients table,
  greatly reducing database load and avoiding timeouts.
*/

-- Set a longer statement timeout for this large operation (10 minutes)
SET statement_timeout = '600000';

-- Start transaction
BEGIN;

-- Main procedure to generate prescriptions
DO $$
DECLARE
  -- Variables for the processing
  curr_batch_id INTEGER;
  curr_specialty TEXT;
  provider_count INTEGER;
  patients_per_provider INTEGER := 150; -- Synthetic patients per provider
  total_providers INTEGER := 0;
  
  -- Date range for prescriptions
  start_date DATE := '2023-01-01'::DATE;
  end_date DATE := CURRENT_DATE;
  date_range INTEGER := end_date - start_date;
  
  -- Provider variables for patient generation
  curr_provider_id TEXT;
  curr_brand_preference NUMERIC;
  curr_target_count INTEGER;
  
  -- Specialty array structure for the five specialties to process
  specialties TEXT[] := ARRAY['Cardiology', 'Cardiac Surgery', 'Neurology', 'Psychiatry', 'Gastroenterology'];
  batch_ids INTEGER[] := ARRAY[4, 5, 6, 7, 8]; -- Corresponding batch IDs
BEGIN
  -- Process each specialty one by one
  FOR i IN 1..array_length(specialties, 1) LOOP
    curr_specialty := specialties[i];
    curr_batch_id := batch_ids[i];
    
    RAISE NOTICE 'Starting processing for specialty: % (batch_id: %)', curr_specialty, curr_batch_id;
    
    -- Create temporary table for this batch's providers
    DROP TABLE IF EXISTS temp_batch_providers;
    CREATE TEMP TABLE temp_batch_providers AS
    SELECT 
      provider_id,
      CASE
        WHEN prescribing_volume = 'high' THEN 750
        WHEN prescribing_volume = 'medium' THEN 500
        ELSE 250
      END as target_prescription_count,
      CASE
        -- Different brand name preferences per specialty
        WHEN curr_specialty = 'Cardiology' AND practice_size IN ('hospital', 'academic') THEN 0.75
        WHEN curr_specialty = 'Cardiology' AND practice_size = 'large' THEN 0.65
        WHEN curr_specialty = 'Cardiology' THEN 0.55
        
        WHEN curr_specialty = 'Cardiac Surgery' AND practice_size IN ('hospital', 'academic') THEN 0.8
        WHEN curr_specialty = 'Cardiac Surgery' AND practice_size = 'large' THEN 0.7
        WHEN curr_specialty = 'Cardiac Surgery' THEN 0.6
        
        WHEN curr_specialty = 'Neurology' AND practice_size IN ('hospital', 'academic') THEN 0.7
        WHEN curr_specialty = 'Neurology' AND practice_size = 'large' THEN 0.6
        WHEN curr_specialty = 'Neurology' THEN 0.5
        
        WHEN curr_specialty = 'Psychiatry' AND practice_size IN ('hospital', 'academic') THEN 0.65
        WHEN curr_specialty = 'Psychiatry' AND practice_size = 'large' THEN 0.6
        WHEN curr_specialty = 'Psychiatry' THEN 0.5
        
        WHEN curr_specialty = 'Gastroenterology' AND practice_size IN ('hospital', 'academic') THEN 0.7
        WHEN curr_specialty = 'Gastroenterology' AND practice_size = 'large' THEN 0.6
        WHEN curr_specialty = 'Gastroenterology' THEN 0.5
        
        ELSE 0.55 -- Default value
      END as brand_preference
    FROM providers
    WHERE specialty = curr_specialty
    ORDER BY provider_id;
    
    -- Get count of providers for reporting
    SELECT COUNT(*) INTO provider_count FROM temp_batch_providers;
    total_providers := total_providers + provider_count;
    
    -- Find appropriate medications for the current specialty
    DROP TABLE IF EXISTS temp_batch_medications;
    CREATE TEMP TABLE temp_batch_medications AS
    SELECT 
      id,
      name,
      category,
      is_brand_name
    FROM medications
    WHERE 
      CASE
        -- Cardiology medications
        WHEN curr_specialty = 'Cardiology' THEN (
          category = 'Cardiovascular' OR
          category = 'Diabetes' OR 
          name ILIKE '%Aspirin%' OR
          name ILIKE '%statin%' OR
          name ILIKE '%coagulant%' OR
          name ILIKE '%antiplatelet%'
        )
        
        -- Cardiac Surgery medications
        WHEN curr_specialty = 'Cardiac Surgery' THEN (
          category = 'Cardiovascular' OR
          name ILIKE '%Heparin%' OR
          name ILIKE '%coagulant%' OR
          name ILIKE '%antiplatelet%' OR
          name ILIKE '%statin%'
        )
        
        -- Neurology medications
        WHEN curr_specialty = 'Neurology' THEN (
          category = 'Neurological' OR
          category = 'Pain' OR
          name ILIKE '%anti-convulsant%' OR
          name ILIKE '%anti-epileptic%' OR
          name ILIKE '%migraine%'
        )
        
        -- Psychiatry medications
        WHEN curr_specialty = 'Psychiatry' THEN (
          category = 'Psychiatric' OR
          name ILIKE '%antidepressant%' OR
          name ILIKE '%anti-anxiety%' OR
          name ILIKE '%antipsychotic%' OR
          name ILIKE '%mood stabilizer%'
        )
        
        -- Gastroenterology medications
        WHEN curr_specialty = 'Gastroenterology' THEN (
          category = 'Gastrointestinal' OR
          name ILIKE '%antacid%' OR
          name ILIKE '%acid reducer%' OR
          name ILIKE '%PPI%' OR
          name ILIKE '%anti-emetic%' OR
          name ILIKE '%laxative%'
        )
        
        ELSE false -- Fallback if specialty not matched
      END;
    
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
        curr_batch_id -- Use the current batch ID for this specialty
      FROM prescription_base
      WHERE rn <= curr_target_count;
      
      -- Report progress for this provider
      RAISE NOTICE 'Processed % provider % with % target prescriptions', 
        curr_specialty, curr_provider_id, curr_target_count;
    END LOOP;
    
    -- Report completion for this specialty
    RAISE NOTICE 'Completed batch % for % with % providers', 
      curr_batch_id, curr_specialty, provider_count;
  END LOOP;
  
  -- Report final statistics
  RAISE NOTICE 'Processed a total of % providers across 5 specialties', total_providers;
  
  -- Clean up any remaining temporary tables
  DROP TABLE IF EXISTS temp_batch_providers;
  DROP TABLE IF EXISTS temp_batch_medications;
END $$;

-- Reset statement timeout to default
RESET statement_timeout;

COMMIT;
