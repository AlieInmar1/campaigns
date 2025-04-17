/*
  # Fix Patient Prescriptions Generation
  
  This migration fixes the issue with NULL provider_ids in the patient_prescriptions generation script.
  It adds proper error handling and ensures we only process providers with valid provider_ids.
*/

-- Start transaction
BEGIN;

-- Generate prescriptions for each provider with proper error handling
DO $$
DECLARE
  provider_rec RECORD;
  patient_rec RECORD;
  medication_rec RECORD;
  patient_id UUID;
  prescription_count INTEGER := 10000; -- 10k prescriptions per provider
  prescriptions_per_patient INTEGER;
  prescription_date DATE;
  fill_date DATE;
  is_refill BOOLEAN;
  refill_number INTEGER;
  i INTEGER;
  j INTEGER;
  provider_count INTEGER := 0;
  skipped_count INTEGER := 0;
  error_message TEXT;
BEGIN
  -- Create temporary tables for medications
  CREATE TEMP TABLE temp_specialty_medications (
    medication_id TEXT,
    medication_name TEXT,
    medication_category TEXT
  ) ON COMMIT DROP;
  
  CREATE TEMP TABLE temp_other_medications (
    medication_id TEXT,
    medication_name TEXT,
    medication_category TEXT
  ) ON COMMIT DROP;
  
  CREATE TEMP TABLE temp_patients (
    p_id UUID
  ) ON COMMIT DROP;
  
  -- Get all providers with valid provider_ids
  FOR provider_rec IN 
    SELECT provider_id, specialty, geographic_area 
    FROM providers 
    WHERE provider_id IS NOT NULL
    ORDER BY random()
    LIMIT 10 -- Limit to 10 providers for testing, remove this limit for production
  LOOP
    BEGIN -- Begin transaction for this provider
      provider_count := provider_count + 1;
      RAISE NOTICE 'Processing provider % of 10: %', provider_count, provider_rec.provider_id;
      
      -- Clear temporary tables
      TRUNCATE TABLE temp_specialty_medications;
      TRUNCATE TABLE temp_other_medications;
      TRUNCATE TABLE temp_patients;
      
      -- Get medications for this specialty
      BEGIN
        INSERT INTO temp_specialty_medications
        SELECT m.medication_id, m.medication_name, m.medication_category
        FROM get_medications_by_specialty(provider_rec.specialty) m;
        
        -- If no specialty medications found, get some generic ones
        IF (SELECT COUNT(*) FROM temp_specialty_medications) = 0 THEN
          INSERT INTO temp_specialty_medications
          SELECT m.id::TEXT, m.name, m.category
          FROM medications m
          ORDER BY random()
          LIMIT 20;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        -- If there's an error getting specialty medications, use generic ones
        RAISE NOTICE 'Error getting specialty medications for %: %. Using generic medications instead.', 
          provider_rec.provider_id, SQLERRM;
        
        INSERT INTO temp_specialty_medications
        SELECT m.id::TEXT, m.name, m.category
        FROM medications m
        ORDER BY random()
        LIMIT 20;
      END;
      
      -- Get some other medications (for variety)
      BEGIN
        INSERT INTO temp_other_medications
        SELECT m.id::TEXT, m.name, m.category
        FROM medications m
        WHERE m.category NOT IN (
          SELECT medication_category FROM temp_specialty_medications
        )
        ORDER BY random()
        LIMIT 10;
        
        -- If no other medications found, use some from specialty
        IF (SELECT COUNT(*) FROM temp_other_medications) = 0 THEN
          INSERT INTO temp_other_medications
          SELECT * FROM temp_specialty_medications
          LIMIT 5;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        -- If there's an error getting other medications, use some from specialty
        RAISE NOTICE 'Error getting other medications for %: %. Using specialty medications instead.', 
          provider_rec.provider_id, SQLERRM;
        
        INSERT INTO temp_other_medications
        SELECT * FROM temp_specialty_medications
        LIMIT 5;
      END;
      
      -- Get patients in the same geographic region (with some from other regions)
      BEGIN
        INSERT INTO temp_patients (p_id)
        SELECT p.id
        FROM patients p
        WHERE 
          (p.geographic_area = provider_rec.geographic_area OR random() < 0.3)
        ORDER BY random()
        LIMIT 2000; -- We'll select from this pool for the prescriptions
        
        -- If no patients found, get random patients
        IF (SELECT COUNT(*) FROM temp_patients) = 0 THEN
          INSERT INTO temp_patients (p_id)
          SELECT p.id
          FROM patients p
          ORDER BY random()
          LIMIT 2000;
        END IF;
      EXCEPTION WHEN OTHERS THEN
        -- If there's an error getting patients, get random patients
        RAISE NOTICE 'Error getting patients for %: %. Getting random patients instead.', 
          provider_rec.provider_id, SQLERRM;
        
        INSERT INTO temp_patients (p_id)
        SELECT p.id
        FROM patients p
        ORDER BY random()
        LIMIT 2000;
      END;
      
      -- Check if we have patients to work with
      IF (SELECT COUNT(*) FROM temp_patients) = 0 THEN
        RAISE NOTICE 'No patients available for provider %. Skipping.', provider_rec.provider_id;
        skipped_count := skipped_count + 1;
        CONTINUE; -- Skip to next provider
      END IF;
      
      -- Generate prescriptions
      FOR i IN 1..prescription_count LOOP
        -- Determine if this is for a patient with multiple prescriptions
        -- About 60% of patients will have multiple prescriptions
        IF random() < 0.6 THEN
          prescriptions_per_patient := 1 + (random() * 5)::integer; -- 1-6 prescriptions
        ELSE
          prescriptions_per_patient := 1; -- Single prescription
        END IF;
        
        -- Select a random patient
        SELECT p_id INTO patient_id FROM temp_patients ORDER BY random() LIMIT 1;
        
        -- Skip if patient_id is null
        IF patient_id IS NULL THEN
          CONTINUE; -- Skip to next iteration
        END IF;
        
        -- Generate prescriptions for this patient
        FOR j IN 1..prescriptions_per_patient LOOP
          -- Determine if this is a new prescription or refill
          is_refill := random() < 0.4; -- 40% chance of being a refill
          
          IF is_refill THEN
            refill_number := 1 + (random() * 5)::integer; -- Refill number 1-6
          ELSE
            refill_number := 0; -- New prescription
          END IF;
          
          -- Set prescription date (within the last year)
          prescription_date := current_date - (random() * 365)::integer * interval '1 day';
          
          -- Set fill date (usually a few days after prescription date)
          fill_date := prescription_date + (1 + (random() * 7))::integer * interval '1 day';
          
          -- Select medication (80% chance of specialty medication, 20% chance of other)
          BEGIN
            IF random() < 0.8 THEN
              SELECT medication_id, medication_name, medication_category INTO medication_rec
              FROM temp_specialty_medications
              ORDER BY random()
              LIMIT 1;
            ELSE
              SELECT medication_id, medication_name, medication_category INTO medication_rec
              FROM temp_other_medications
              ORDER BY random()
              LIMIT 1;
            END IF;
            
            -- Skip if medication_rec is null
            IF medication_rec.medication_id IS NULL THEN
              CONTINUE; -- Skip to next iteration
            END IF;
            
            -- Double-check that provider_id is not null before inserting
            IF provider_rec.provider_id IS NULL THEN
              RAISE NOTICE 'Provider ID is NULL. Skipping prescription.';
              CONTINUE; -- Skip to next iteration
            END IF;
            
            -- Insert prescription into patient_prescriptions table
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
              provider_rec.provider_id,
              patient_id,
              medication_rec.medication_id,
              medication_rec.medication_name,
              medication_rec.medication_category,
              prescription_date,
              fill_date,
              30 + (random() * 60)::integer, -- Quantity between 30-90
              30 + (random() * 60)::integer, -- Days supply between 30-90
              (random() * 5)::integer, -- 0-5 refills
              refill_number,
              NOT is_refill
            );
          EXCEPTION WHEN OTHERS THEN
            -- Log error and continue
            RAISE NOTICE 'Error inserting prescription for provider % and patient %: %', 
              provider_rec.provider_id, patient_id, SQLERRM;
            CONTINUE; -- Skip to next iteration
          END;
        END LOOP;
        
        -- Report progress every 1000 prescriptions
        IF i % 1000 = 0 THEN
          RAISE NOTICE 'Generated % prescriptions for provider % so far', i, provider_rec.provider_id;
        END IF;
      END LOOP;
      
      RAISE NOTICE 'Completed generating prescriptions for provider %', provider_rec.provider_id;
    EXCEPTION WHEN OTHERS THEN
      -- Log error and continue with next provider
      GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
      RAISE NOTICE 'Error processing provider %: %', provider_rec.provider_id, error_message;
      skipped_count := skipped_count + 1;
    END;
  END LOOP;
  
  -- Show summary of prescriptions generated
  RAISE NOTICE 'Prescription generation complete. Processed % providers, skipped %.', provider_count, skipped_count;
  RAISE NOTICE 'Total prescriptions: %', (SELECT COUNT(*) FROM patient_prescriptions);
END $$;

-- Show summary of prescriptions by provider specialty
SELECT 
  p.specialty, 
  COUNT(*) as prescription_count,
  COUNT(DISTINCT pr.patient_id) as patient_count,
  COUNT(*) FILTER (WHERE pr.is_new = TRUE) as new_prescriptions,
  COUNT(*) FILTER (WHERE pr.is_new = FALSE) as refill_prescriptions
FROM patient_prescriptions pr
JOIN providers p ON pr.provider_id = p.provider_id
GROUP BY p.specialty
ORDER BY prescription_count DESC;

-- Show summary of prescriptions by medication category
SELECT 
  pr.medication_category, 
  COUNT(*) as prescription_count,
  COUNT(DISTINCT pr.patient_id) as patient_count,
  COUNT(DISTINCT pr.provider_id) as provider_count
FROM patient_prescriptions pr
GROUP BY pr.medication_category
ORDER BY prescription_count DESC;

COMMIT;
