
-- Catch-All Patient Prescriptions
-- This ensures:
-- 1. All providers in minimal specialties get exactly 100 prescriptions
-- 2. All other providers with fewer than 100 prescriptions also get exactly 100

-- Set a longer statement timeout for this operation (10 minutes)
SET statement_timeout = '600000';

-- Start transaction
BEGIN;

-- Clear any existing prescriptions for minimal specialties (we'll add exactly 10 per provider)
DELETE FROM patient_prescriptions
WHERE provider_id IN (
  SELECT provider_id FROM providers 
  WHERE specialty IN ('Cardiac Surgery', 'Rheumatology', 'Infectious Disease', 'Hematology', 'Nephrology', 'Obstetrics & Gynecology', 'Pediatrics', 'Geriatrics', 'Orthopedics', 'Emergency Medicine', 'Pain Management', 'Internal Medicine', 'Primary Care')
);

-- Find providers that need prescriptions: either minimal specialties or those with < 10
CREATE TEMP TABLE providers_needing_prescriptions AS
WITH prescription_counts AS (
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
  specialty IN ('Cardiac Surgery', 'Rheumatology', 'Infectious Disease', 'Hematology', 'Nephrology', 'Obstetrics & Gynecology', 'Pediatrics', 'Geriatrics', 'Orthopedics', 'Emergency Medicine', 'Pain Management', 'Internal Medicine', 'Primary Care')  -- All providers in minimal specialties
  OR prescription_count < 100;               -- Any other providers with < 100 prescriptions

-- Add prescriptions to ensure each provider has exactly 100
DO $$
DECLARE
  curr_provider RECORD;
  medication_id TEXT;
  medication_name TEXT;
  medication_category TEXT;
  patient_id UUID;
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
        gen_random_uuid(),
        medication_id,
        medication_name,
        medication_category,
        CURRENT_DATE - (RANDOM() * 365)::INTEGER,
        CASE WHEN RANDOM() < 0.9 THEN CURRENT_DATE - (RANDOM() * 30)::INTEGER ELSE NULL END,
        30, 30, FLOOR(RANDOM() * 3)::INTEGER, 0, TRUE, 99, NOW()
      );
    END LOOP;
  END LOOP;
END $$;

COMMIT;
