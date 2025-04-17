-- Add database functions for debugging
BEGIN;

-- Function to get top prescribed medications
CREATE OR REPLACE FUNCTION get_top_prescribed_medications(limit_count integer)
RETURNS TABLE (
  medication_id text,
  medication_name text,
  medication_category text,
  prescription_count bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id as medication_id,
    m.name as medication_name,
    m.category as medication_category,
    COUNT(p.id) as prescription_count
  FROM medications m
  LEFT JOIN prescriptions p ON p.medication_id = m.id
  GROUP BY m.id, m.name, m.category
  ORDER BY prescription_count DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get provider statistics by specialty
CREATE OR REPLACE FUNCTION get_provider_specialty_stats()
RETURNS TABLE (
  specialty text,
  provider_count bigint,
  total_prescriptions bigint,
  avg_prescriptions_per_provider numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.specialty,
    COUNT(DISTINCT p.provider_id) as provider_count,
    COUNT(pr.id) as total_prescriptions,
    ROUND(COUNT(pr.id)::numeric / COUNT(DISTINCT p.provider_id)::numeric, 2) as avg_prescriptions_per_provider
  FROM providers p
  LEFT JOIN prescriptions pr ON pr.provider_id = p.provider_id
  WHERE p.specialty IS NOT NULL
  GROUP BY p.specialty
  ORDER BY provider_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get provider geographic distribution
CREATE OR REPLACE FUNCTION get_provider_geographic_stats()
RETURNS TABLE (
  geographic_area text,
  provider_count bigint,
  total_prescriptions bigint,
  avg_prescriptions_per_provider numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.geographic_area,
    COUNT(DISTINCT p.provider_id) as provider_count,
    COUNT(pr.id) as total_prescriptions,
    ROUND(COUNT(pr.id)::numeric / COUNT(DISTINCT p.provider_id)::numeric, 2) as avg_prescriptions_per_provider
  FROM providers p
  LEFT JOIN prescriptions pr ON pr.provider_id = p.provider_id
  WHERE p.geographic_area IS NOT NULL
  GROUP BY p.geographic_area
  ORDER BY provider_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get prescription statistics for a specific provider
CREATE OR REPLACE FUNCTION get_provider_prescription_stats(provider_id text)
RETURNS TABLE (
  category text,
  medication_count bigint,
  prescription_count bigint,
  percentage numeric
) AS $$
DECLARE
  total_prescriptions bigint;
BEGIN
  -- Get total prescriptions for this provider
  SELECT COUNT(*) INTO total_prescriptions
  FROM prescriptions
  WHERE provider_id = $1;

  -- Return category statistics
  RETURN QUERY
  SELECT 
    m.category,
    COUNT(DISTINCT m.id) as medication_count,
    COUNT(p.id) as prescription_count,
    ROUND((COUNT(p.id)::numeric / total_prescriptions::numeric * 100), 2) as percentage
  FROM medications m
  JOIN prescriptions p ON p.medication_id = m.id
  WHERE p.provider_id = $1
  GROUP BY m.category
  ORDER BY prescription_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Add indexes to support the debug functions
DO $$ 
BEGIN
  -- Index for medication categories
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'medications' 
    AND indexname = 'idx_medications_category'
  ) THEN
    CREATE INDEX idx_medications_category ON medications(category);
  END IF;

  -- Index for provider specialties
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'providers' 
    AND indexname = 'idx_providers_specialty'
  ) THEN
    CREATE INDEX idx_providers_specialty ON providers(specialty);
  END IF;

  -- Index for provider geographic areas
  IF NOT EXISTS (
    SELECT 1 
    FROM pg_indexes 
    WHERE tablename = 'providers' 
    AND indexname = 'idx_providers_geographic_area'
  ) THEN
    CREATE INDEX idx_providers_geographic_area ON providers(geographic_area);
  END IF;
END $$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION get_top_prescribed_medications(integer) TO authenticated;
GRANT EXECUTE ON FUNCTION get_provider_specialty_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_provider_geographic_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_provider_prescription_stats(text) TO authenticated;

COMMIT;
