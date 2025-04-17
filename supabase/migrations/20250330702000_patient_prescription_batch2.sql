/*
  # Patient Prescriptions Batch 2: Cardiology Providers
  
  This migration is part 2 of 4 in the batched generation of patient prescriptions.
  It handles Cardiology and related cardiovascular specialties.
  
  The batched approach solves timeout issues by splitting the workload.
*/

-- Set a longer statement timeout for this large operation (10 minutes)
SET statement_timeout = '600000';

-- Start transaction
BEGIN;

-- Helper function to determine if a medication is appropriate for a specialty
CREATE OR REPLACE FUNCTION is_medication_appropriate_for_specialty(
  medication_category TEXT,
  medication_subcategory TEXT,
  provider_specialty TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  result BOOLEAN := FALSE;
BEGIN
  -- Match medication categories to provider specialties
  CASE 
    -- Cardiology specialties
    WHEN provider_specialty ILIKE '%cardio%' THEN
      result := medication_category = 'Cardiovascular';
      
    -- Neurology specialties  
    WHEN provider_specialty ILIKE '%neuro%' THEN
      result := medication_category = 'Neurology' OR 
                medication_category = 'Psychiatric' OR
                medication_subcategory ILIKE '%pain%';
                
    -- Psychiatric specialties
    WHEN provider_specialty ILIKE '%psych%' THEN
      result := medication_category = 'Psychiatric';
      
    -- Endocrinology specialties
    WHEN provider_specialty ILIKE '%endocrin%' OR provider_specialty ILIKE '%diabet%' THEN
      result := medication_category = 'Diabetes' OR 
                medication_category = 'Endocrine';
                
    -- Gastroenterology specialties
    WHEN provider_specialty ILIKE '%gastro%' OR provider_specialty ILIKE '%hepat%' THEN
      result := medication_category = 'Gastrointestinal';
      
    -- Rheumatology/Immunology
    WHEN provider_specialty ILIKE '%rheumat%' OR provider_specialty ILIKE '%immun%' THEN
      result := medication_category = 'Immunology' OR 
                medication_subcategory ILIKE '%anti-inflammatory%';
    
    -- Pulmonology
    WHEN provider_specialty ILIKE '%pulmo%' OR provider_specialty ILIKE '%respirat%' THEN
      result := medication_category = 'Respiratory';
      
    -- Infectious Disease
    WHEN provider_specialty ILIKE '%infect%' THEN
      result := medication_category = 'Infectious Disease' OR
                medication_subcategory ILIKE '%antibiotic%';
                
    -- Oncology
    WHEN provider_specialty ILIKE '%onco%' THEN
      result := medication_category = 'Oncology';
      
    -- Dermatology
    WHEN provider_specialty ILIKE '%dermat%' THEN
      result := medication_category = 'Dermatology';
      
    -- Primary care providers can prescribe most medications
    WHEN provider_specialty ILIKE '%primary%' OR 
         provider_specialty ILIKE '%family%' OR 
         provider_specialty ILIKE '%internal med%' THEN
      result := TRUE;
      
    -- Default case - allow some overlap
    ELSE
      -- 20% chance of prescribing any medication for other specialties
      result := random() < 0.2;
  END CASE;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Main procedure to generate prescriptions
DO $$
DECLARE
  -- Batch identifier
  batch_id CONSTANT INTEGER := 2;
  
  -- Variables for the processing
  provider_count INTEGER;
  total_prescriptions INTEGER := 0;
  target_patient_count INTEGER := 75;
  
  -- Date range for prescriptions
  start_date DATE := '2023-01-01'::DATE;
  end_date DATE := CURRENT_DATE;
  date_range INTEGER := end_date - start_date;
  
  -- Specialty target for this batch
  current_specialty TEXT;
  specialty_list TEXT[] := ARRAY['Cardiology', 'Interventional Cardiology', 'Electrophysiology', 'Vascular Surgery', 'Cardiac Surgery'];
  
  -- Create a temporary table for tracking processed providers
  drop_temp_tables BOOLEAN := FALSE;
BEGIN
  -- Create temporary tables for better performance
  DROP TABLE IF EXISTS temp_batch_providers;
  DROP TABLE IF EXISTS temp_batch_medications;
  DROP TABLE IF EXISTS temp_batch_patients;
  DROP TABLE IF EXISTS temp_batch_provider_patients;
  
  -- Record start time for performance tracking
  RAISE NOTICE 'Batch % started at %', batch_id, clock_timestamp();
  
  -- Check provider count for this batch
  SELECT COUNT(*) INTO provider_count 
  FROM providers 
  WHERE 
    specialty = ANY(specialty_list) OR
    specialty ILIKE '%cardio%';  -- Catch any other cardiology-related specialties
  
  RAISE NOTICE 'Batch % will process % providers in cardiology-related specialties', 
    batch_id, provider_count;
  
  -- Create temporary table for this batch's providers
  CREATE TEMP TABLE temp_batch_providers AS
  SELECT 
    provider_id,
    specialty,
    geographic_area,
    prescribing_volume,
    practice_size,
    CASE
      WHEN prescribing_volume = 'high' THEN 1500
      WHEN prescribing_volume = 'medium' THEN 1000
      ELSE 500
    END as target_prescription_count,
    CASE
      -- Cardiologists tend to prescribe more brand name drugs
      WHEN practice_size IN ('hospital', 'academic') THEN 0.8  -- Much more likely to prescribe brand names
      WHEN practice_size = 'large' THEN 0.7
      WHEN practice_size = 'solo' THEN 0.6  -- Still more likely than average
      ELSE 0.65
    END as brand_preference
  FROM providers
  WHERE 
    specialty = ANY(specialty_list) OR
    specialty ILIKE '%cardio%';
  
  -- Create index for better performance
  CREATE INDEX ON temp_batch_providers(provider_id);
  
  -- Find appropriate medications for cardiology specialties and store in temp table
  CREATE TEMP TABLE temp_batch_medications AS
  WITH all_meds AS (
    SELECT 
      id, 
      name, 
      category, 
      subcategory,
      is_brand_name,
      is_target_medication,
      specialty
    FROM medications
  )
  SELECT 
    id,
    name,
    category,
    is_brand_name,
    is_target_medication
  FROM all_meds
  WHERE 
    -- Primarily cardiovascular medications with some common meds
    category = 'Cardiovascular' OR
    -- Some cardiologists also prescribe diabetes medications
    category = 'Diabetes' OR 
    -- Common medications that might be prescribed by any specialist
    name ILIKE '%Aspirin%' OR
    subcategory ILIKE '%anti-coagulant%' OR
    subcategory ILIKE '%antiplatelet%' OR
    subcategory ILIKE '%statin%';
  
  CREATE INDEX ON temp_batch_medications(id);
  CREATE INDEX ON temp_batch_medications(category);
  CREATE INDEX ON temp_batch_medications(is_brand_name);
  
  -- Get list of patients who already have prescriptions from the first batch
  -- to avoid assigning the same patients to providers with similar specialties
  CREATE TEMP TABLE existing_assigned_patients AS
  SELECT DISTINCT patient_id
  FROM patient_prescriptions
  WHERE batch_id = 1;
  
  -- Pre-select patients for this batch and ensure geographic distribution
  -- We'll select a pool of patients that's larger than we need
  CREATE TEMP TABLE temp_batch_patients AS
  SELECT 
    id,
    geographic_area
  FROM patients
  WHERE NOT EXISTS (
    SELECT 1 FROM existing_assigned_patients eap
    WHERE patients.id = eap.patient_id
  )
  ORDER BY random()
  LIMIT (provider_count * target_patient_count * 3);  -- Get 3x what we need for flexibility
  
  CREATE INDEX ON temp_batch_patients(id);
  CREATE INDEX ON temp_batch_patients(geographic_area);
  
  -- Now assign patients to providers with geographic preference
  CREATE TEMP TABLE temp_batch_provider_patients AS
  WITH provider_assignments AS (
    SELECT 
      p.provider_id,
      p.geographic_area,
      LEAST(p.target_prescription_count / 10, target_patient_count) AS needed_patients
    FROM temp_batch_providers p
  ),
  -- First attempt to match within the same geographic area
  geo_matched AS (
    SELECT
      pa.provider_id,
      tp.id AS patient_id,
      ROW_NUMBER() OVER (PARTITION BY pa.provider_id ORDER BY random()) AS rn
    FROM provider_assignments pa
    JOIN temp_batch_patients tp ON tp.geographic_area = pa.geographic_area
  ),
  -- Then match remaining needs with any patients
  remaining_needed AS (
    SELECT
      pa.provider_id,
      pa.needed_patients - COUNT(gm.patient_id) AS remaining
    FROM provider_assignments pa
    LEFT JOIN geo_matched gm ON pa.provider_id = gm.provider_id AND gm.rn <= pa.needed_patients
    GROUP BY pa.provider_id, pa.needed_patients
  ),
  any_match AS (
    SELECT
      rn.provider_id,
      tp.id AS patient_id,
      ROW_NUMBER() OVER (PARTITION BY rn.provider_id ORDER BY random()) AS rn
    FROM remaining_needed rn
    CROSS JOIN temp_batch_patients tp
    WHERE rn.remaining > 0
  ),
  -- Combine both sets
  combined AS (
    SELECT provider_id, patient_id 
    FROM geo_matched 
    WHERE rn <= (
      SELECT needed_patients 
      FROM provider_assignments 
      WHERE provider_id = geo_matched.provider_id
    )
    UNION ALL
    SELECT provider_id, patient_id 
    FROM any_match
    WHERE rn <= (
      SELECT remaining 
      FROM remaining_needed 
      WHERE provider_id = any_match.provider_id
    )
  )
  SELECT 
    provider_id, 
    patient_id
  FROM combined;
  
  CREATE INDEX ON temp_batch_provider_patients(provider_id);
  CREATE INDEX ON temp_batch_provider_patients(patient_id);
  
  -- For each specialty in the batch, generate prescription data efficiently
  FOR current_specialty IN SELECT UNNEST(specialty_list) LOOP
    RAISE NOTICE 'Processing specialty: %', current_specialty;
    
    -- Process each provider in current specialty
    WITH provider_prescriptions AS (
      -- Generate prescribed medications for each provider 
      SELECT 
        tbp.provider_id,
        tbp.brand_preference,
        tbp.target_prescription_count,
        tbpp.patient_id,
        tbm.id AS medication_id,
        tbm.name AS medication_name,
        tbm.category AS medication_category,
        -- Create a random prescription date
        (start_date + (random() * date_range)::INTEGER) AS prescription_date,
        -- Determine if prescription was filled (90% chance)
        CASE WHEN random() < 0.9 
          THEN (start_date + (random() * date_range)::INTEGER) + (random() * 7)::INTEGER
          ELSE NULL
        END AS fill_date,
        -- Determine if this is a new prescription (70% chance)
        random() < 0.7 AS is_new,
        -- Calculate refill number (0 for new, 1-5 for refills)
        CASE WHEN random() < 0.7 
          THEN 0 
          ELSE 1 + floor(random() * 5)::INTEGER 
        END AS refill_number,
        -- Determine refills allowed (depends on medication category)
        CASE WHEN tbm.category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
          THEN 2 + floor(random() * 4)::INTEGER  -- 2-5 refills for chronic
          ELSE floor(random() * 3)::INTEGER      -- 0-2 refills for acute
        END AS refills,
        -- Determine quantity (depends on medication category)
        CASE WHEN tbm.category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
          THEN (ARRAY[30, 60, 90])[floor(random() * 3) + 1]  -- 30, 60, or 90 for chronic
          ELSE 10 + floor(random() * 20)::INTEGER            -- 10-30 for acute
        END AS quantity,
        -- Generate a row number to limit prescriptions per provider
        ROW_NUMBER() OVER (
          PARTITION BY tbp.provider_id 
          ORDER BY random()
        ) AS rn
      FROM temp_batch_providers tbp
      -- Join to assigned patients
      JOIN temp_batch_provider_patients tbpp ON tbp.provider_id = tbpp.provider_id
      -- Cross join to all medications but limit later with row_number
      CROSS JOIN temp_batch_medications tbm
      -- Only process current specialty
      WHERE tbp.specialty = current_specialty OR 
            (current_specialty = 'Cardiology' AND tbp.specialty ILIKE '%cardio%')
      -- Apply brand preference filter
      AND ((tbm.is_brand_name = true AND random() < tbp.brand_preference) OR
           (tbm.is_brand_name = false AND random() > tbp.brand_preference))
    )
    INSERT INTO patient_prescriptions (
      provider_id,
      patient_id,
      medication_id,
      medication_name,
      medication_category,
      prescription_date,
      fill_date,
      quantity,
      days_supply,  -- Set equal to quantity for chronic, or calculated for acute
      refills,
      refill_number,
      is_new,
      batch_id
    )
    SELECT 
      provider_id,
      patient_id,
      medication_id,
      medication_name,
      medication_category,
      prescription_date,
      fill_date,
      quantity,
      CASE WHEN medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine')
        THEN quantity  -- One per day for chronic meds
        ELSE 5 + floor(random() * 10)::INTEGER  -- 5-15 days for acute meds
      END AS days_supply,
      refills,
      refill_number,
      is_new,
      batch_id
    FROM provider_prescriptions
    WHERE rn <= target_prescription_count;
    
    -- Count specialty prescriptions and report progress
    WITH specialty_stats AS (
      SELECT COUNT(*) as prescription_count
      FROM patient_prescriptions
      WHERE batch_id = batch_id
      AND EXISTS (
        SELECT 1 FROM temp_batch_providers
        WHERE provider_id = patient_prescriptions.provider_id
        AND (specialty = current_specialty OR 
             (current_specialty = 'Cardiology' AND specialty ILIKE '%cardio%'))
      )
    )
    SELECT 
      prescription_count,
      total_prescriptions + prescription_count
    INTO 
      provider_count,
      total_prescriptions
    FROM specialty_stats;
    
    RAISE NOTICE 'Created % prescriptions for % specialty (total so far: %)',
      provider_count, current_specialty, total_prescriptions;
  END LOOP;
  
  -- Create summary statistics using simple aggregate queries
  RAISE NOTICE 'Batch % complete. Generated % total prescriptions', batch_id, total_prescriptions;
  
  -- Get some basic statistics
  WITH prescription_stats AS (
    SELECT 
      COUNT(*) as total_count,
      COUNT(DISTINCT provider_id) as provider_count,
      COUNT(DISTINCT patient_id) as patient_count,
      COUNT(*) FILTER (WHERE is_new) as new_count,
      COUNT(*) FILTER (WHERE NOT is_new) as refill_count
    FROM patient_prescriptions
    WHERE batch_id = batch_id
  )
  SELECT 
    'Generated ' || total_count || ' prescriptions across ' || 
    provider_count || ' providers and ' || patient_count || ' patients. ' ||
    'New prescriptions: ' || new_count || ', Refills: ' || refill_count
  INTO current_specialty
  FROM prescription_stats;
  
  RAISE NOTICE '%', current_specialty;
  
  -- Record end time
  RAISE NOTICE 'Batch % completed at %', batch_id, clock_timestamp();
  
  -- Clean up temporary tables
  DROP TABLE IF EXISTS temp_batch_providers;
  DROP TABLE IF EXISTS temp_batch_medications;
  DROP TABLE IF EXISTS temp_batch_patients;
  DROP TABLE IF EXISTS temp_batch_provider_patients;
  DROP TABLE IF EXISTS existing_assigned_patients;
END $$;

-- Clean up the helper function
DROP FUNCTION IF EXISTS is_medication_appropriate_for_specialty(TEXT, TEXT, TEXT);

-- Reset statement timeout to default
RESET statement_timeout;

COMMIT;
