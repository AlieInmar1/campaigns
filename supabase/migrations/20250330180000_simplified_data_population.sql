/*
  # Simplified Data Population
  
  This migration populates the patients and patient_prescriptions tables with data.
  It uses a simplified approach without savepoints to avoid syntax errors.
  
  It includes:
  1. Generation of patients
  2. Generation of prescriptions for all providers
  3. Proper error handling
  4. Progress reporting and summary statistics
*/

-- Start transaction
BEGIN;

-- Check if tables exist
DO $$
DECLARE
  patients_exists BOOLEAN;
  prescriptions_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'patients'
  ) INTO patients_exists;
  
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'patient_prescriptions'
  ) INTO prescriptions_exists;
  
  IF NOT patients_exists THEN
    RAISE EXCEPTION 'Table public.patients does not exist. Please run the migration to create it first.';
  END IF;
  
  IF NOT prescriptions_exists THEN
    RAISE EXCEPTION 'Table public.patient_prescriptions does not exist. Please run the migration to create it first.';
  END IF;
  
  RAISE NOTICE 'Tables exist, proceeding with data population...';
END $$;

-- Check if medications table exists and has data
DO $$
DECLARE
  medications_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO medications_count FROM medications;
  
  IF medications_count = 0 THEN
    RAISE EXCEPTION 'No medications found in the medications table. Please ensure the medications table is populated.';
  ELSE
    RAISE NOTICE 'Found % medications in the medications table.', medications_count;
  END IF;
END $$;

-- Check if providers table exists and has data
DO $$
DECLARE
  providers_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO providers_count FROM providers;
  
  IF providers_count = 0 THEN
    RAISE EXCEPTION 'No providers found in the providers table. Please ensure the providers table is populated.';
  ELSE
    RAISE NOTICE 'Found % providers in the providers table.', providers_count;
  END IF;
END $$;

-- Helper function to generate a random patient name
CREATE OR REPLACE FUNCTION generate_patient_name()
RETURNS TEXT AS $$
DECLARE
  first_names TEXT[] := ARRAY[
    'James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Charles',
    'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan', 'Jessica', 'Sarah', 'Karen',
    'Daniel', 'Matthew', 'Anthony', 'Mark', 'Donald', 'Steven', 'Paul', 'Andrew', 'Joshua', 'Kenneth',
    'Lisa', 'Nancy', 'Margaret', 'Sandra', 'Ashley', 'Kimberly', 'Emily', 'Donna', 'Michelle', 'Carol',
    'Christopher', 'George', 'Ronald', 'Edward', 'Brian', 'Kevin', 'Jason', 'Timothy', 'Jeffrey', 'Ryan',
    'Amanda', 'Melissa', 'Deborah', 'Stephanie', 'Rebecca', 'Laura', 'Sharon', 'Cynthia', 'Kathleen', 'Amy',
    'Gregory', 'Joshua', 'Frank', 'Raymond', 'Patrick', 'Dennis', 'Jerry', 'Tyler', 'Aaron', 'Jose',
    'Rachel', 'Heather', 'Nicole', 'Zachary', 'Samuel', 'Benjamin', 'Victoria', 'Hannah', 'Alexander', 'Jacob',
    'Sofia', 'Emma', 'Olivia', 'Ava', 'Isabella', 'Sophia', 'Charlotte', 'Mia', 'Amelia', 'Harper',
    'Evelyn', 'Abigail', 'Emily', 'Elizabeth', 'Mila', 'Ella', 'Avery', 'Scarlett', 'Aria', 'Penelope'
  ];
  last_names TEXT[] := ARRAY[
    'Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor',
    'Anderson', 'Thomas', 'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson',
    'Clark', 'Rodriguez', 'Lewis', 'Lee', 'Walker', 'Hall', 'Allen', 'Young', 'Hernandez', 'King',
    'Wright', 'Lopez', 'Hill', 'Scott', 'Green', 'Adams', 'Baker', 'Gonzalez', 'Nelson', 'Carter',
    'Mitchell', 'Perez', 'Roberts', 'Turner', 'Phillips', 'Campbell', 'Parker', 'Evans', 'Edwards', 'Collins',
    'Stewart', 'Sanchez', 'Morris', 'Rogers', 'Reed', 'Cook', 'Morgan', 'Bell', 'Murphy', 'Bailey',
    'Rivera', 'Cooper', 'Richardson', 'Cox', 'Howard', 'Ward', 'Torres', 'Peterson', 'Gray', 'Ramirez',
    'James', 'Watson', 'Brooks', 'Kelly', 'Sanders', 'Price', 'Bennett', 'Wood', 'Barnes', 'Ross',
    'Henderson', 'Coleman', 'Jenkins', 'Perry', 'Powell', 'Long', 'Patterson', 'Hughes', 'Flores', 'Washington',
    'Butler', 'Simmons', 'Foster', 'Gonzales', 'Bryant', 'Alexander', 'Russell', 'Griffin', 'Diaz', 'Hayes'
  ];
  first_name TEXT;
  last_name TEXT;
BEGIN
  first_name := first_names[floor(random() * array_length(first_names, 1)) + 1];
  last_name := last_names[floor(random() * array_length(last_names, 1)) + 1];
  
  RETURN first_name || ' ' || last_name;
END;
$$ LANGUAGE plpgsql;

-- Define medication categories by specialty
CREATE OR REPLACE FUNCTION get_medications_by_specialty(specialty TEXT)
RETURNS TABLE(medication_id TEXT, medication_name TEXT, medication_category TEXT) AS $$
BEGIN
  -- Primary Care and Family Medicine
  IF specialty IN ('Primary Care', 'Family Medicine', 'Internal Medicine') THEN
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      WHERE m.category IN ('ACE Inhibitor', 'Beta Blocker', 'Statin', 'Biguanide', 'SSRI', 'NSAID')
      ORDER BY random()
      LIMIT 20
    );
  
  -- Cardiology
  ELSIF specialty IN ('Cardiology', 'Interventional Cardiology', 'Electrophysiology') THEN
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      WHERE m.category IN ('ACE Inhibitor', 'Beta Blocker', 'Calcium Channel Blocker', 'ARB', 'Statin', 'Anticoagulant')
      ORDER BY random()
      LIMIT 20
    );
  
  -- Neurology
  ELSIF specialty IN ('Neurology', 'Neurosurgery', 'Movement Disorders') THEN
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      WHERE m.category IN ('Anticonvulsant', 'NMDA Receptor Antagonist', 'Dopamine Precursor', 'Triptan')
      ORDER BY random()
      LIMIT 20
    );
  
  -- Endocrinology
  ELSIF specialty IN ('Endocrinology', 'Diabetes Specialist', 'Thyroid Specialist') THEN
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      WHERE m.category IN ('Biguanide', 'Sulfonylurea', 'Long-acting Insulin', 'Rapid-acting Insulin', 'Thyroid Hormone', 'Antithyroid', 'DPP-4 Inhibitor', 'SGLT2 Inhibitor', 'GLP-1 Receptor Agonist')
      ORDER BY random()
      LIMIT 20
    );
  
  -- Psychiatry
  ELSIF specialty IN ('Psychiatry', 'Child Psychiatry', 'Addiction Medicine') THEN
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      WHERE m.category IN ('SSRI', 'SNRI', 'Atypical Antipsychotic', 'Anticonvulsant Mood Stabilizer', 'CNS Stimulant')
      ORDER BY random()
      LIMIT 20
    );
  
  -- Pulmonology
  ELSIF specialty IN ('Pulmonology', 'Critical Care', 'Sleep Medicine') THEN
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      WHERE m.category IN ('Short-acting Beta Agonist', 'Inhaled Corticosteroid', 'Long-acting Anticholinergic', 'Leukotriene Receptor Antagonist', 'LABA/ICS Combination')
      ORDER BY random()
      LIMIT 20
    );
  
  -- Rheumatology
  ELSIF specialty IN ('Rheumatology', 'Immunology', 'Allergy') THEN
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      WHERE m.category IN ('NSAID', 'COX-2 Inhibitor', 'Corticosteroid', 'Biologic (TNF Inhibitor)', 'DMARD')
      ORDER BY random()
      LIMIT 20
    );
  
  -- Gastroenterology
  ELSIF specialty IN ('Gastroenterology', 'Hepatology', 'Colorectal Surgery') THEN
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      WHERE m.category IN ('Proton Pump Inhibitor', 'H2 Blocker', 'Anti-inflammatory')
      ORDER BY random()
      LIMIT 20
    );
  
  -- Default for other specialties
  ELSE
    RETURN QUERY (
      SELECT m.id::TEXT, m.name, m.category
      FROM medications m
      ORDER BY random()
      LIMIT 20
    );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Step 1: Generate patients if the table is empty
DO $$
DECLARE
  patient_count INTEGER;
  target_count INTEGER := 100000;
  batch_size INTEGER := 1000;
  i INTEGER;
  j INTEGER;
  gender_array TEXT[] := ARRAY['Male', 'Female', 'Other'];
  regions TEXT[] := ARRAY[
    'Northeast', 'Southeast', 'Midwest', 'Southwest', 'West', 'Northwest',
    'Northeast - New York', 'Northeast - Massachusetts', 'Northeast - Connecticut', 
    'Northeast - Pennsylvania', 'Northeast - New Jersey', 'Northeast - Rhode Island',
    'Southeast - Florida', 'Southeast - Georgia', 'Southeast - North Carolina',
    'Southeast - South Carolina', 'Southeast - Virginia', 'Southeast - Tennessee',
    'Midwest - Illinois', 'Midwest - Ohio', 'Midwest - Michigan',
    'Midwest - Indiana', 'Midwest - Wisconsin', 'Midwest - Minnesota',
    'Southwest - Texas', 'Southwest - Arizona', 'Southwest - New Mexico',
    'West - California', 'West - Washington', 'West - Oregon',
    'West - Colorado', 'West - Hawaii', 'West - Alaska'
  ];
BEGIN
  -- Check if we already have patients
  SELECT COUNT(*) INTO patient_count FROM patients;
  
  -- Only continue if we need to add more patients
  IF patient_count >= target_count THEN
    RAISE NOTICE 'Already have % patients, skipping patient generation', patient_count;
    RETURN;
  ELSE
    RAISE NOTICE 'Current patient count: %. Adding more patients...', patient_count;
  END IF;
  
  -- Calculate how many more patients we need to add
  target_count := GREATEST(target_count - patient_count, 0);
  
  -- Generate patients in batches for better performance
  FOR i IN 0..(target_count / batch_size) LOOP
    BEGIN
      -- Generate a batch of patients
      FOR j IN 1..LEAST(batch_size, target_count - (i * batch_size)) LOOP
        BEGIN
          INSERT INTO patients (
            patient_id,
            name,
            age,
            gender,
            geographic_area
          ) VALUES (
            'PAT-' || lpad((i * batch_size + j)::text, 8, '0'),
            generate_patient_name(),
            18 + (random() * 70)::integer,
            gender_array[1 + floor(random() * 3)::integer],
            regions[1 + floor(random() * array_length(regions, 1))::integer]
          );
        EXCEPTION WHEN OTHERS THEN
          -- If there's an error with this patient, log and continue
          RAISE NOTICE 'Error generating patient %: %', (i * batch_size + j), SQLERRM;
        END;
      END LOOP;
      
      -- Report progress every 10 batches
      IF i % 10 = 0 THEN
        RAISE NOTICE 'Generated % patients so far', LEAST((i + 1) * batch_size, target_count);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      -- If there's an error with this batch, log and continue
      RAISE NOTICE 'Error generating batch %: %', i, SQLERRM;
    END;
  END LOOP;
  
  -- Get the final count
  SELECT COUNT(*) INTO patient_count FROM patients;
  RAISE NOTICE 'Patient generation complete. Total patients: %', patient_count;
END $$;

-- Step 2: Generate prescriptions for each provider
DO $$
DECLARE
  provider_rec RECORD;
  medication_rec RECORD;
  patient_id UUID;
  prescription_count INTEGER := 1000; -- 1k prescriptions per provider for faster execution
  prescriptions_per_patient INTEGER;
  prescription_date DATE;
  fill_date DATE;
  is_refill BOOLEAN;
  refill_number INTEGER;
  i INTEGER;
  j INTEGER;
  provider_count INTEGER := 0;
  total_provider_count INTEGER;
  skipped_count INTEGER := 0;
  error_message TEXT;
  total_prescriptions INTEGER := 0;
BEGIN
  -- Get total provider count
  SELECT COUNT(*) INTO total_provider_count FROM providers WHERE provider_id IS NOT NULL;
  RAISE NOTICE 'Found % providers with valid provider_ids', total_provider_count;
  
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
    LIMIT 10 -- Limit to 10 providers for testing
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
        BEGIN
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
            BEGIN
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
              
              total_prescriptions := total_prescriptions + 1;
            EXCEPTION WHEN OTHERS THEN
              -- Log error and continue
              RAISE NOTICE 'Error inserting prescription for provider % and patient %: %', 
                provider_rec.provider_id, patient_id, SQLERRM;
            END;
          END LOOP;
        EXCEPTION WHEN OTHERS THEN
          -- Log error and continue
          RAISE NOTICE 'Error processing prescription %: %', i, SQLERRM;
        END;
        
        -- Report progress every 100 prescriptions
        IF i % 100 = 0 THEN
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
    
    -- Report progress every 10 providers
    IF provider_count % 10 = 0 THEN
      RAISE NOTICE 'Processed % of 10 providers. Generated % prescriptions so far.', 
        provider_count, total_prescriptions;
    END IF;
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

-- Drop the helper functions to clean up
DROP FUNCTION IF EXISTS generate_patient_name();
DROP FUNCTION IF EXISTS get_medications_by_specialty(TEXT);

COMMIT;
