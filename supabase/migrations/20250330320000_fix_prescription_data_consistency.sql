-- Fix prescription data consistency
BEGIN;

-- Create a temporary table to store invalid prescriptions
CREATE TEMP TABLE invalid_prescriptions AS
SELECT p.*
FROM prescriptions p
LEFT JOIN providers pr ON p.provider_id = pr.provider_id
LEFT JOIN medications m ON p.medication_id = m.id
WHERE pr.provider_id IS NULL OR m.id IS NULL;

-- Log invalid prescriptions before deletion
SELECT 'Invalid prescriptions found:' as message;
SELECT 
  p.*,
  CASE 
    WHEN pr.provider_id IS NULL THEN 'Invalid provider_id'
    WHEN m.id IS NULL THEN 'Invalid medication_id'
    ELSE 'Unknown error'
  END as error_type
FROM invalid_prescriptions p
LEFT JOIN providers pr ON p.provider_id = pr.provider_id
LEFT JOIN medications m ON p.medication_id = m.id;

-- Delete invalid prescriptions
DELETE FROM prescriptions
WHERE id IN (SELECT id FROM invalid_prescriptions);

-- Check prescription counts per provider
SELECT 
  p.provider_id,
  pr.name as provider_name,
  COUNT(*) as prescription_count,
  COUNT(DISTINCT p.medication_id) as unique_medications
FROM prescriptions p
JOIN providers pr ON p.provider_id = pr.provider_id
GROUP BY p.provider_id, pr.name
ORDER BY prescription_count DESC
LIMIT 10;

-- Check medication prescription distribution
SELECT 
  m.id as medication_id,
  m.name as medication_name,
  m.category,
  COUNT(*) as prescription_count,
  COUNT(DISTINCT p.provider_id) as unique_providers
FROM prescriptions p
JOIN medications m ON p.medication_id = m.id
GROUP BY m.id, m.name, m.category
ORDER BY prescription_count DESC
LIMIT 10;

-- Add foreign key constraints if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'prescriptions_provider_id_fkey'
  ) THEN
    ALTER TABLE prescriptions
    ADD CONSTRAINT prescriptions_provider_id_fkey
    FOREIGN KEY (provider_id) REFERENCES providers(provider_id)
    ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.table_constraints 
    WHERE constraint_name = 'prescriptions_medication_id_fkey'
  ) THEN
    ALTER TABLE prescriptions
    ADD CONSTRAINT prescriptions_medication_id_fkey
    FOREIGN KEY (medication_id) REFERENCES medications(id)
    ON DELETE CASCADE;
  END IF;
END $$;

-- Verify constraints
SELECT 
  tc.constraint_name, 
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM 
  information_schema.table_constraints AS tc 
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'prescriptions'
AND tc.constraint_type = 'FOREIGN KEY';

-- Add NOT NULL constraints if they don't exist
DO $$ 
BEGIN
  -- Check provider_id
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'prescriptions' 
    AND column_name = 'provider_id' 
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE prescriptions
    ALTER COLUMN provider_id SET NOT NULL;
  END IF;

  -- Check medication_id
  IF EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'prescriptions' 
    AND column_name = 'medication_id' 
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE prescriptions
    ALTER COLUMN medication_id SET NOT NULL;
  END IF;
END $$;

-- Verify column constraints
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'prescriptions'
ORDER BY ordinal_position;

-- Add indexes if they don't exist (in addition to the ones added in previous migration)
DO $$ 
BEGIN
  -- Composite index for provider_id and medication_id if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'prescriptions' 
    AND indexname = 'idx_prescriptions_provider_medication_composite'
  ) THEN
    CREATE INDEX idx_prescriptions_provider_medication_composite 
    ON prescriptions(provider_id, medication_id);
  END IF;
END $$;

-- Analyze tables
ANALYZE providers;
ANALYZE medications;
ANALYZE prescriptions;

COMMIT;
