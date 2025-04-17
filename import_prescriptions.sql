-- SQL script to ensure all providers have at least 100 prescriptions
-- This should be run in Supabase SQL Editor after manually importing the CSV files

-- Set a longer statement timeout for this operation (10 minutes)
SET statement_timeout = '600000';

-- Start transaction
BEGIN;

-- Find providers that need prescriptions: either minimal specialties or those with < 100
CREATE TEMP TABLE providers_needing_prescriptions AS
WITH minimal_specialties AS (
  SELECT 'Cardiology' AS specialty UNION ALL
  SELECT 'Endocrinology' UNION ALL
  SELECT 'Pulmonology' UNION ALL
  SELECT 'Neurology' UNION ALL
  SELECT 'Psychiatry' UNION ALL
  SELECT 'Dermatology' UNION ALL
  SELECT 'Gastroenterology' UNION ALL
  SELECT 'Cardiac Surgery' UNION ALL
  SELECT 'Hematology' UNION ALL
  SELECT 'Obstetrics & Gynecology' UNION ALL
  SELECT 'Pediatrics' UNION ALL
  SELECT 'Geriatrics' UNION ALL
  SELECT 'Orthopedics' UNION ALL
  SELECT 'Emergency Medicine' UNION ALL
  SELECT 'Pain Management'
),
prescription_counts AS (
  SELECT 
    p.provider_id,
    p.specialty,
    p.practice_size,
    COALESCE(COUNT(pp.id), 0) AS prescription_count
  FROM 
    providers p
    LEFT JOIN patient_prescriptions pp ON p.provider_id = pp.provider_id
  GROUP BY 
    p.provider_id, p.specialty, p.practice_size
)
SELECT 
  provider_id,
  specialty,
  practice_size,
  prescription_count
FROM 
  prescription_counts
WHERE 
  specialty IN (SELECT specialty FROM minimal_specialties)  -- All providers in minimal specialties
  OR prescription_count < 100;                             -- Any other providers with < 100 prescriptions

-- Add prescriptions to ensure each provider has exactly 100
DO $$
DECLARE
  curr_provider RECORD;
  medication_id TEXT;
  medication_name TEXT;
  medication_category TEXT;
  patient_id UUID;
  batch_id CONSTANT INTEGER := 99; -- Batch ID for catch-all records
BEGIN
  -- Process each provider
  FOR curr_provider IN SELECT * FROM providers_needing_prescriptions LOOP
    -- Add the missing prescriptions to reach 100 total
    FOR i IN 1..(100 - curr_provider.prescription_count) LOOP
      -- Generate a patient ID for this prescription
      patient_id := gen_random_uuid();
      
      -- Get a random medication
      SELECT id, name, category INTO medication_id, medication_name, medication_category 
      FROM medications
      ORDER BY RANDOM()
      LIMIT 1;
      
      -- Insert a prescription
      INSERT INTO patient_prescriptions (
        id, provider_id, patient_id, medication_id, medication_name, medication_category,
        prescription_date, fill_date, quantity, days_supply, refills, refill_number,
        is_new, batch_id, created_at
      ) VALUES (
        gen_random_uuid(),
        curr_provider.provider_id,
        patient_id,
        medication_id,
        medication_name,
        medication_category,
        CURRENT_DATE - (RANDOM() * 365)::INTEGER,
        CASE WHEN RANDOM() < 0.9 THEN CURRENT_DATE - (RANDOM() * 30)::INTEGER ELSE NULL END,
        30, 30, FLOOR(RANDOM() * 3)::INTEGER, 0, TRUE, batch_id, NOW()
      );
    END LOOP;
  END LOOP;
END $$;

-- Verify total prescription counts per specialty
SELECT 
  specialty, 
  COUNT(DISTINCT provider_id) AS provider_count,
  COUNT(*) AS prescription_count,
  COUNT(*) / COUNT(DISTINCT provider_id) AS avg_prescriptions_per_provider
FROM 
  patient_prescriptions pp
JOIN 
  providers p ON pp.provider_id = p.provider_id
GROUP BY 
  specialty
ORDER BY 
  specialty;

COMMIT;
