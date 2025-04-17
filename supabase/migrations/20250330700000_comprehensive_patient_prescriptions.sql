/*
  # Comprehensive Patient Prescriptions Migration
  
  This migration creates a comprehensive set of patient prescriptions data with:
  - ~1000 prescriptions per provider
  - ~75 patients per provider
  - Realistic specialty-based medication distribution
  - Varying generic vs. brand name preferences
  - Realistic refill patterns
  - Patients not seeing multiple providers in same specialty
*/

-- Start transaction
BEGIN;

-- Clean up any existing data for a fresh start
TRUNCATE TABLE public.patient_prescriptions CASCADE;

-- Check existing patient and provider counts
DO $$
DECLARE
  provider_count INTEGER;
  patient_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO provider_count FROM providers;
  SELECT COUNT(*) INTO patient_count FROM patients;
  
  RAISE NOTICE 'Using existing patient database. Found % patients and % providers.', 
    patient_count, provider_count;
    
  -- Just verify we have enough patients (should be plenty with 100K)
  IF patient_count < (provider_count * 10) THEN
    RAISE WARNING 'Relatively low patient count compared to providers. Some patients may be assigned to multiple providers.';
  END IF;
END $$;

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

-- Helper function to determine a provider's likelihood to prescribe brand vs generic
CREATE OR REPLACE FUNCTION get_provider_brand_preference(
  provider_id TEXT,
  specialty TEXT,
  practice_size TEXT
) RETURNS NUMERIC AS $$
DECLARE
  base_preference NUMERIC;
BEGIN
  -- Base preference (higher means more likely to prescribe brand name)
  -- We'll use specialty and practice size to influence this
  
  -- Start with a random base preference
  base_preference := random();
  
  -- Adjust by specialty (some specialties tend to prescribe more brand name drugs)
  IF specialty ILIKE '%cardio%' OR specialty ILIKE '%onco%' THEN
    base_preference := base_preference + 0.2;
  ELSIF specialty ILIKE '%psych%' THEN
    base_preference := base_preference + 0.1;
  ELSIF specialty ILIKE '%primary%' OR specialty ILIKE '%family%' THEN
    base_preference := base_preference - 0.1;
  END IF;
  
  -- Adjust by practice size (larger practices/hospitals may have more brand name drugs)
  IF practice_size = 'hospital' OR practice_size = 'academic' THEN
    base_preference := base_preference + 0.1;
  ELSIF practice_size = 'large' THEN
    base_preference := base_preference + 0.05;
  ELSIF practice_size = 'solo' THEN
    base_preference := base_preference - 0.1;
  END IF;
  
  -- Ensure the preference is between 0 and 1
  RETURN GREATEST(0, LEAST(1, base_preference));
END;
$$ LANGUAGE plpgsql;

-- Now let's create the main procedure to generate prescriptions
DO $$
DECLARE
  -- Variables for the provider currently being processed
  provider record;
  provider_patient_count INTEGER;
  target_patient_count INTEGER := 75;
  brand_preference NUMERIC;
  
  -- Variables for patient assignment
  patient record;
  patient_id UUID;
  patient_specialty_map JSONB := '{}'::JSONB;
  patients_per_provider INTEGER[];
  assigned_patients UUID[];
  specialty_patients JSONB := '{}'::JSONB;
  
  -- Variables for medication selection
  medication record;
  medication_id TEXT;
  medication_name TEXT;
  medication_category TEXT;
  appropriate_medications TEXT[];
  selected_medications TEXT[];
  
  -- Variables for prescription parameters
  prescription_date DATE;
  fill_date DATE;
  quantity INTEGER;
  days_supply INTEGER;
  refills INTEGER;
  refill_number INTEGER;
  is_new BOOLEAN;
  prescription_count INTEGER;
  target_prescription_count INTEGER := 1000;
  
  -- Counters for reporting
  total_prescriptions INTEGER := 0;
  skipped_providers INTEGER := 0;
  
  -- Start and end dates for prescriptions
  start_date DATE := '2023-01-01'::DATE;
  end_date DATE := CURRENT_DATE;
  date_range INTEGER := end_date - start_date;
  
  -- Variables for batching and performance
  batch_size INTEGER := 100;
  current_batch INTEGER := 0;
BEGIN
  -- More efficiently pre-assign patients to specialties to ensure no patient sees multiple providers in same specialty
  RAISE NOTICE 'Pre-assigning patients to specialties...';
  
  -- Get all distinct specialties and the count of providers per specialty
  FOR provider IN (
    SELECT 
      specialty, 
      COUNT(*) as provider_count 
    FROM providers 
    GROUP BY specialty
  ) LOOP
    -- Calculate how many patients we need for this specialty
    -- We need (provider_count * target_patient_count) patients per specialty
    -- But we'll select a few more to allow for geographic matching later
    
    -- For each specialty, allocate a pool of patients from those not yet assigned
    WITH available_patients AS (
      SELECT id 
      FROM patients
      WHERE id NOT IN (
        SELECT jsonb_object_keys(patient_specialty_map)::UUID
      )
      ORDER BY random()
      LIMIT (provider.provider_count * target_patient_count * 1.2)::INTEGER -- Get 20% extra for flexibility
    )
    SELECT array_agg(id) INTO assigned_patients 
    FROM available_patients;
    
    -- If we don't have enough unassigned patients, we may need to reuse some
    IF array_length(assigned_patients, 1) < (provider.provider_count * target_patient_count) THEN
      RAISE NOTICE 'Not enough unassigned patients for specialty %. Using random patients.', provider.specialty;
      
      -- Get random patients regardless of previous assignments
      SELECT array_agg(id) INTO assigned_patients
      FROM patients
      ORDER BY random()
      LIMIT (provider.provider_count * target_patient_count)::INTEGER;
    END IF;
    
    -- Store these patients as assigned to this specialty
    FOREACH patient_id IN ARRAY assigned_patients LOOP
      patient_specialty_map := jsonb_set(
        patient_specialty_map, 
        ARRAY[patient_id::TEXT], 
        to_jsonb(provider.specialty)
      );
    END LOOP;
    
    -- Store array of patients for this specialty for quick lookup
    specialty_patients := jsonb_set(
      specialty_patients,
      ARRAY[provider.specialty],
      to_jsonb(assigned_patients)
    );
    
    RAISE NOTICE 'Assigned % patients to specialty %', 
      array_length(assigned_patients, 1), provider.specialty;
  END LOOP;
  
  RAISE NOTICE 'Starting prescription generation for each provider...';
  
  -- Process each provider
  FOR provider IN (
    SELECT 
      p.provider_id, 
      p.specialty, 
      p.geographic_area, 
      p.prescribing_volume,
      p.practice_size
    FROM providers p
    ORDER BY p.specialty, p.provider_id
  ) LOOP
    -- Reset counters for this provider
    prescription_count := 0;
    
    -- Determine brand vs generic preference for this provider
    brand_preference := get_provider_brand_preference(
      provider.provider_id, 
      provider.specialty, 
      provider.practice_size
    );
    
    -- Get patients for this provider's specialty from our pre-assigned pool more efficiently
    SELECT 
      jsonb_array_elements_text(specialty_patients -> provider.specialty)::UUID
    INTO assigned_patients;
    
    -- Optimize geographic matching
    -- First try to get patients from the same region
    WITH geo_matched_patients AS (
      SELECT p.id 
      FROM patients p
      WHERE p.id = ANY(assigned_patients)
      AND p.geographic_area = provider.geographic_area
      ORDER BY random()
      LIMIT (target_patient_count * 0.8)::INTEGER -- Try to get 80% from same region
    ),
    -- Then add some from other regions for diversity
    other_region_patients AS (
      SELECT p.id
      FROM patients p
      WHERE p.id = ANY(assigned_patients)
      AND p.id NOT IN (SELECT id FROM geo_matched_patients)
      ORDER BY random()
      LIMIT (target_patient_count * 0.2)::INTEGER -- 20% from other regions
    ),
    -- Combine both sets
    combined_patients AS (
      SELECT id FROM geo_matched_patients
      UNION ALL
      SELECT id FROM other_region_patients
    )
    SELECT array_agg(id) INTO assigned_patients 
    FROM combined_patients
    LIMIT target_patient_count;
    
    -- If we still don't have enough, just get any patients from the specialty pool
    IF array_length(assigned_patients, 1) < target_patient_count * 0.5 THEN
      -- Get any patients from the specialty pool
      SELECT 
        array_agg(jsonb_array_elements_text(specialty_patients -> provider.specialty)::UUID)
      INTO assigned_patients
      FROM (
        SELECT jsonb_array_elements_text(specialty_patients -> provider.specialty)::UUID
        ORDER BY random()
        LIMIT target_patient_count
      ) as random_patients;
    END IF;
    
    -- Skip if we still couldn't assign enough patients
    IF array_length(assigned_patients, 1) < 10 THEN
      RAISE WARNING 'Insufficient patients for provider % (specialty: %). Skipping.', 
        provider.provider_id, provider.specialty;
      skipped_providers := skipped_providers + 1;
      CONTINUE;
    END IF;
    
    provider_patient_count := array_length(assigned_patients, 1);
    
    -- Adjust target prescription count based on volume
    IF provider.prescribing_volume = 'high' THEN
      target_prescription_count := 1500;
    ELSIF provider.prescribing_volume = 'medium' THEN
      target_prescription_count := 1000;
    ELSIF provider.prescribing_volume = 'low' THEN
      target_prescription_count := 500;
    END IF;
    
    RAISE NOTICE 'Generating % prescriptions for provider % (specialty: %) with % patients',
      target_prescription_count, provider.provider_id, provider.specialty, provider_patient_count;
    
    -- Find appropriate medications for this provider's specialty
    appropriate_medications := ARRAY[]::TEXT[];
    
    FOR medication IN (
      SELECT id, name, category, subcategory, is_brand_name
      FROM medications
    ) LOOP
      -- Check if medication is appropriate for this specialty
      IF is_medication_appropriate_for_specialty(
        medication.category,
        medication.subcategory,
        provider.specialty
      ) THEN
        -- Apply brand vs generic preference
        IF (medication.is_brand_name AND random() < brand_preference) OR
           (NOT medication.is_brand_name AND random() > brand_preference) THEN
          appropriate_medications := appropriate_medications || medication.id;
        END IF;
      END IF;
    END LOOP;
    
    -- Make sure we have some medications to work with
    IF array_length(appropriate_medications, 1) < 5 THEN
      -- If not enough specialty-specific meds, add some common medications
      FOR medication IN (
        SELECT id FROM medications 
        WHERE category IN ('Cardiovascular', 'Psychiatric', 'Diabetes')
        LIMIT 10
      ) LOOP
        appropriate_medications := appropriate_medications || medication.id;
      END LOOP;
    END IF;
    
    -- Generate prescriptions for this provider
    WHILE prescription_count < target_prescription_count LOOP
      -- Get a random patient for this prescription
      patient_id := assigned_patients[floor(random() * array_length(assigned_patients, 1)) + 1];
      
      -- Select a random medication appropriate for this provider
      medication_id := appropriate_medications[floor(random() * array_length(appropriate_medications, 1)) + 1];
      
      -- Get medication details
      SELECT name, category INTO medication_name, medication_category 
      FROM medications 
      WHERE id = medication_id;
      
      -- Generate prescription parameters
      
      -- Prescription date - random date within our range
      prescription_date := start_date + (random() * date_range)::INTEGER;
      
      -- 90% chance the medication was filled
      IF random() < 0.9 THEN
        -- Fill date - usually 0-7 days after prescription date
        fill_date := prescription_date + (random() * 7)::INTEGER;
      ELSE
        -- Not filled
        fill_date := NULL;
      END IF;
      
      -- Determine if this is a new prescription or refill
      -- 70% chance of being a new prescription
      is_new := random() < 0.7;
      
      -- If it's not a new prescription, it's likely a refill
      IF is_new THEN
        refill_number := 0;
      ELSE
        -- Refill number between 1-5
        refill_number := 1 + floor(random() * 5)::INTEGER;
      END IF;
      
      -- Determine refills allowed - depends on medication and provider style
      -- Chronic medications typically get more refills
      IF medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine') THEN
        -- Chronic medications - more refills
        refills := floor(random() * 4)::INTEGER + 2; -- 2-5 refills
      ELSE
        -- Acute medications - fewer refills
        refills := floor(random() * 3)::INTEGER; -- 0-2 refills
      END IF;
      
      -- Quantity - varies by medication type
      -- Chronic medications often have 30-90 day supplies
      IF medication_category IN ('Cardiovascular', 'Diabetes', 'Psychiatric', 'Endocrine') THEN
        -- Pick a common quantity - 30, 60, or 90
        quantity := (ARRAY[30, 60, 90])[floor(random() * 3) + 1];
        days_supply := quantity; -- One per day
      ELSE
        -- Acute medications - varies widely
        quantity := 10 + floor(random() * 20)::INTEGER; -- 10-30
        days_supply := 5 + floor(random() * 10)::INTEGER; -- 5-15
      END IF;
      
      -- Insert the prescription
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
        is_new
      ) VALUES (
        provider.provider_id,
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
        is_new
      );
      
      -- Increment counters
      prescription_count := prescription_count + 1;
      total_prescriptions := total_prescriptions + 1;
      current_batch := current_batch + 1;
      
      -- Report progress batch-wise to avoid excessive log messages
      IF current_batch >= batch_size THEN
        RAISE NOTICE 'Generated % prescriptions total (current provider: % with % so far)',
          total_prescriptions, provider.provider_id, prescription_count;
        current_batch := 0;
      END IF;
    END LOOP;
  END LOOP;
  
  -- Final summary
  RAISE NOTICE 'Prescription generation complete.';
  RAISE NOTICE 'Total prescriptions generated: %', total_prescriptions;
  RAISE NOTICE 'Providers skipped: %', skipped_providers;
  
  -- Create summary statistics
  RAISE NOTICE 'Generating summary statistics...';
  
  -- Prescriptions per provider
  RAISE NOTICE 'Prescriptions per provider:';
  FOR provider IN (
    SELECT 
      provider_id, 
      COUNT(*) as prescription_count
    FROM patient_prescriptions
    GROUP BY provider_id
    ORDER BY prescription_count DESC
    LIMIT 10
  ) LOOP
    RAISE NOTICE '  Provider %: % prescriptions', provider.provider_id, provider.prescription_count;
  END LOOP;
  
  -- Patients per provider
  RAISE NOTICE 'Patients per provider:';
  FOR provider IN (
    SELECT 
      provider_id, 
      COUNT(DISTINCT patient_id) as patient_count
    FROM patient_prescriptions
    GROUP BY provider_id
    ORDER BY patient_count DESC
    LIMIT 10
  ) LOOP
    RAISE NOTICE '  Provider %: % patients', provider.provider_id, provider.patient_count;
  END LOOP;
  
  -- Prescriptions by medication category
  RAISE NOTICE 'Prescriptions by medication category:';
  FOR medication IN (
    SELECT 
      medication_category, 
      COUNT(*) as prescription_count
    FROM patient_prescriptions
    GROUP BY medication_category
    ORDER BY prescription_count DESC
    LIMIT 10
  ) LOOP
    RAISE NOTICE '  %: % prescriptions', medication.medication_category, medication.prescription_count;
  END LOOP;
  
  -- New vs. refill statistics
  RAISE NOTICE 'New vs. refill statistics:';
  SELECT 
    COUNT(*) FILTER (WHERE is_new) as new_count,
    COUNT(*) FILTER (WHERE NOT is_new) as refill_count
  INTO patient
  FROM patient_prescriptions;
  
  RAISE NOTICE '  New prescriptions: % (%.2f%%)', 
    patient.new_count, 
    (patient.new_count::NUMERIC / NULLIF(patient.new_count + patient.refill_count, 0)) * 100;
  
  RAISE NOTICE '  Refill prescriptions: % (%.2f%%)', 
    patient.refill_count,
    (patient.refill_count::NUMERIC / NULLIF(patient.new_count + patient.refill_count, 0)) * 100;
END $$;

-- Clean up the helper functions
DROP FUNCTION IF EXISTS is_medication_appropriate_for_specialty(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS get_provider_brand_preference(TEXT, TEXT, TEXT);

-- Add an index to speed up common queries
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_medication_provider 
ON patient_prescriptions(medication_id, provider_id);

CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_date_range
ON patient_prescriptions(prescription_date, fill_date);

COMMIT;
