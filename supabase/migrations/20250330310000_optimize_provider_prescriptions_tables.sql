-- Optimize provider and prescriptions tables
BEGIN;

-- Check if provider_id index exists on prescriptions table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'prescriptions' 
    AND indexname = 'idx_prescriptions_provider_id'
  ) THEN
    CREATE INDEX idx_prescriptions_provider_id ON prescriptions(provider_id);
  END IF;
END $$;

-- Check if medication_id index exists on prescriptions table
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'prescriptions' 
    AND indexname = 'idx_prescriptions_medication_id'
  ) THEN
    CREATE INDEX idx_prescriptions_medication_id ON prescriptions(medication_id);
  END IF;
END $$;

-- Check if composite index exists for both provider_id and medication_id
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'prescriptions' 
    AND indexname = 'idx_prescriptions_provider_medication'
  ) THEN
    CREATE INDEX idx_prescriptions_provider_medication ON prescriptions(provider_id, medication_id);
  END IF;
END $$;

-- Add indexes on commonly filtered provider fields
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'providers' 
    AND indexname = 'idx_providers_specialty'
  ) THEN
    CREATE INDEX idx_providers_specialty ON providers(specialty);
  END IF;

  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'providers' 
    AND indexname = 'idx_providers_geographic_area'
  ) THEN
    CREATE INDEX idx_providers_geographic_area ON providers(geographic_area);
  END IF;
END $$;

-- Verify table structures
SELECT 
  table_name, 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_name IN ('providers', 'prescriptions', 'medications')
ORDER BY table_name, ordinal_position;

-- Verify indexes
SELECT 
  tablename, 
  indexname, 
  indexdef
FROM pg_indexes
WHERE tablename IN ('providers', 'prescriptions', 'medications')
ORDER BY tablename, indexname;

-- Check for any null provider_ids in prescriptions
SELECT COUNT(*) as null_provider_ids
FROM prescriptions
WHERE provider_id IS NULL;

-- Check for any prescriptions with invalid provider_ids
SELECT COUNT(*) as invalid_provider_ids
FROM prescriptions p
LEFT JOIN providers pr ON p.provider_id = pr.provider_id
WHERE pr.provider_id IS NULL;

-- Check for any prescriptions with invalid medication_ids
SELECT COUNT(*) as invalid_medication_ids
FROM prescriptions p
LEFT JOIN medications m ON p.medication_id = m.id
WHERE m.id IS NULL;

-- Analyze tables for query optimization
ANALYZE providers;
ANALYZE prescriptions;
ANALYZE medications;

COMMIT;
