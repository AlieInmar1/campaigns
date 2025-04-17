-- Provider Query Functions for Campaign Creation and Audience Explorer
-- This migration adds SQL functions to query providers based on patient_prescriptions data

-- Start transaction
BEGIN;

-- Function to find providers by medication
CREATE OR REPLACE FUNCTION find_providers_by_medication(
  medication_ids TEXT[],
  excluded_medication_ids TEXT[] DEFAULT '{}'::TEXT[]
) RETURNS TABLE (provider_id TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT pp.provider_id
  FROM patient_prescriptions pp
  WHERE 
    (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR pp.medication_id = ANY(medication_ids))
    AND (excluded_medication_ids IS NULL OR array_length(excluded_medication_ids, 1) IS NULL OR pp.medication_id <> ALL(excluded_medication_ids));
END;
$$ LANGUAGE plpgsql;

-- Function to count providers by criteria
CREATE OR REPLACE FUNCTION count_providers_by_criteria(
  medication_ids TEXT[] DEFAULT NULL,
  excluded_medication_ids TEXT[] DEFAULT NULL,
  specialties TEXT[] DEFAULT NULL,
  regions TEXT[] DEFAULT NULL,
  prescribing_volume TEXT DEFAULT NULL,
  use_and_logic BOOLEAN DEFAULT FALSE
) RETURNS INTEGER AS $$
DECLARE
  provider_count INTEGER;
BEGIN
  IF use_and_logic THEN
    -- AND logic (all criteria must match)
    SELECT COUNT(DISTINCT p.provider_id)
    INTO provider_count
    FROM providers p
    WHERE 
      (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR 
        p.provider_id IN (SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)))
      AND (specialties IS NULL OR array_length(specialties, 1) IS NULL OR p.specialty = ANY(specialties))
      AND (regions IS NULL OR array_length(regions, 1) IS NULL OR p.geographic_area = ANY(regions))
      AND (prescribing_volume IS NULL OR prescribing_volume = 'all' OR p.prescribing_volume = prescribing_volume);
  ELSE
    -- OR logic (any criteria can match)
    WITH medication_providers AS (
      SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)
      WHERE medication_ids IS NOT NULL AND array_length(medication_ids, 1) > 0
    ),
    specialty_providers AS (
      SELECT provider_id FROM providers 
      WHERE specialties IS NOT NULL AND array_length(specialties, 1) > 0 AND specialty = ANY(specialties)
    ),
    region_providers AS (
      SELECT provider_id FROM providers 
      WHERE regions IS NOT NULL AND array_length(regions, 1) > 0 AND geographic_area = ANY(regions)
    ),
    volume_providers AS (
      SELECT provider_id FROM providers 
      WHERE prescribing_volume IS NOT NULL AND prescribing_volume != 'all' AND prescribing_volume = prescribing_volume
    ),
    combined_providers AS (
      SELECT provider_id FROM medication_providers
      UNION
      SELECT provider_id FROM specialty_providers
      UNION
      SELECT provider_id FROM region_providers
      UNION
      SELECT provider_id FROM volume_providers
    )
    SELECT COUNT(DISTINCT provider_id)
    INTO provider_count
    FROM combined_providers;
    
    -- If no criteria were specified, return total count
    IF provider_count IS NULL OR provider_count = 0 THEN
      SELECT COUNT(DISTINCT provider_id)
      INTO provider_count
      FROM providers;
    END IF;
  END IF;
  
  RETURN COALESCE(provider_count, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to get provider distribution by region
CREATE OR REPLACE FUNCTION get_provider_distribution_by_region(
  medication_ids TEXT[] DEFAULT NULL,
  excluded_medication_ids TEXT[] DEFAULT NULL,
  specialties TEXT[] DEFAULT NULL,
  regions TEXT[] DEFAULT NULL,
  prescribing_volume TEXT DEFAULT NULL,
  use_and_logic BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
  id TEXT, 
  name TEXT, 
  provider_count INTEGER, 
  percentage INTEGER
) AS $$
DECLARE
  total_count INTEGER;
BEGIN
  -- Get total count for percentage calculation
  SELECT count_providers_by_criteria(
    medication_ids, 
    excluded_medication_ids, 
    specialties, 
    regions, 
    prescribing_volume, 
    use_and_logic
  ) INTO total_count;
  
  -- Return early if no providers match
  IF total_count = 0 THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH matching_providers AS (
    SELECT p.provider_id, p.geographic_area
    FROM providers p
    WHERE 
      (use_and_logic = FALSE OR (
        (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR 
          p.provider_id IN (SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)))
        AND (specialties IS NULL OR array_length(specialties, 1) IS NULL OR p.specialty = ANY(specialties))
        AND (regions IS NULL OR array_length(regions, 1) IS NULL OR p.geographic_area = ANY(regions))
        AND (prescribing_volume IS NULL OR prescribing_volume = 'all' OR p.prescribing_volume = prescribing_volume)
      ))
      AND (use_and_logic = TRUE OR (
        (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR 
          p.provider_id IN (SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)))
        OR (specialties IS NULL OR array_length(specialties, 1) IS NULL OR p.specialty = ANY(specialties))
        OR (regions IS NULL OR array_length(regions, 1) IS NULL OR p.geographic_area = ANY(regions))
        OR (prescribing_volume IS NULL OR prescribing_volume = 'all' OR p.prescribing_volume = prescribing_volume)
      ))
  ),
  region_counts AS (
    SELECT 
      geographic_area,
      COUNT(DISTINCT provider_id) AS count
    FROM matching_providers
    GROUP BY geographic_area
  )
  SELECT 
    geographic_area AS id,
    geographic_area AS name,
    count AS provider_count,
    ROUND((count::NUMERIC / total_count) * 100)::INTEGER AS percentage
  FROM region_counts
  ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get provider distribution by specialty
CREATE OR REPLACE FUNCTION get_provider_distribution_by_specialty(
  medication_ids TEXT[] DEFAULT NULL,
  excluded_medication_ids TEXT[] DEFAULT NULL,
  specialties TEXT[] DEFAULT NULL,
  regions TEXT[] DEFAULT NULL,
  prescribing_volume TEXT DEFAULT NULL,
  use_and_logic BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
  id TEXT, 
  name TEXT, 
  value INTEGER, 
  percentage INTEGER
) AS $$
DECLARE
  total_count INTEGER;
BEGIN
  -- Get total count for percentage calculation
  SELECT count_providers_by_criteria(
    medication_ids, 
    excluded_medication_ids, 
    specialties, 
    regions, 
    prescribing_volume, 
    use_and_logic
  ) INTO total_count;
  
  -- Return early if no providers match
  IF total_count = 0 THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH matching_providers AS (
    SELECT p.provider_id, p.specialty
    FROM providers p
    WHERE 
      (use_and_logic = FALSE OR (
        (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR 
          p.provider_id IN (SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)))
        AND (specialties IS NULL OR array_length(specialties, 1) IS NULL OR p.specialty = ANY(specialties))
        AND (regions IS NULL OR array_length(regions, 1) IS NULL OR p.geographic_area = ANY(regions))
        AND (prescribing_volume IS NULL OR prescribing_volume = 'all' OR p.prescribing_volume = prescribing_volume)
      ))
      AND (use_and_logic = TRUE OR (
        (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR 
          p.provider_id IN (SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)))
        OR (specialties IS NULL OR array_length(specialties, 1) IS NULL OR p.specialty = ANY(specialties))
        OR (regions IS NULL OR array_length(regions, 1) IS NULL OR p.geographic_area = ANY(regions))
        OR (prescribing_volume IS NULL OR prescribing_volume = 'all' OR p.prescribing_volume = prescribing_volume)
      ))
  ),
  specialty_counts AS (
    SELECT 
      specialty,
      COUNT(DISTINCT provider_id) AS count
    FROM matching_providers
    GROUP BY specialty
  )
  SELECT 
    specialty AS id,
    specialty AS name,
    count AS value,
    ROUND((count::NUMERIC / total_count) * 100)::INTEGER AS percentage
  FROM specialty_counts
  ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get provider distribution by prescribing volume
CREATE OR REPLACE FUNCTION get_provider_distribution_by_volume(
  medication_ids TEXT[] DEFAULT NULL,
  excluded_medication_ids TEXT[] DEFAULT NULL,
  specialties TEXT[] DEFAULT NULL,
  regions TEXT[] DEFAULT NULL,
  prescribing_volume TEXT DEFAULT NULL,
  use_and_logic BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
  id TEXT, 
  name TEXT, 
  value INTEGER, 
  percentage INTEGER
) AS $$
DECLARE
  total_count INTEGER;
BEGIN
  -- Get total count for percentage calculation
  SELECT count_providers_by_criteria(
    medication_ids, 
    excluded_medication_ids, 
    specialties, 
    regions, 
    prescribing_volume, 
    use_and_logic
  ) INTO total_count;
  
  -- Return early if no providers match
  IF total_count = 0 THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH matching_providers AS (
    SELECT p.provider_id, p.prescribing_volume
    FROM providers p
    WHERE 
      (use_and_logic = FALSE OR (
        (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR 
          p.provider_id IN (SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)))
        AND (specialties IS NULL OR array_length(specialties, 1) IS NULL OR p.specialty = ANY(specialties))
        AND (regions IS NULL OR array_length(regions, 1) IS NULL OR p.geographic_area = ANY(regions))
        AND (prescribing_volume IS NULL OR prescribing_volume = 'all' OR p.prescribing_volume = prescribing_volume)
      ))
      AND (use_and_logic = TRUE OR (
        (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR 
          p.provider_id IN (SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)))
        OR (specialties IS NULL OR array_length(specialties, 1) IS NULL OR p.specialty = ANY(specialties))
        OR (regions IS NULL OR array_length(regions, 1) IS NULL OR p.geographic_area = ANY(regions))
        OR (prescribing_volume IS NULL OR prescribing_volume = 'all' OR p.prescribing_volume = prescribing_volume)
      ))
  ),
  volume_counts AS (
    SELECT 
      prescribing_volume,
      COUNT(DISTINCT provider_id) AS count
    FROM matching_providers
    GROUP BY prescribing_volume
  )
  SELECT 
    prescribing_volume AS id,
    CASE 
      WHEN prescribing_volume = 'high' THEN 'High Volume'
      WHEN prescribing_volume = 'medium' THEN 'Medium Volume'
      WHEN prescribing_volume = 'low' THEN 'Low Volume'
      ELSE prescribing_volume || ' Volume'
    END AS name,
    count AS value,
    ROUND((count::NUMERIC / total_count) * 100)::INTEGER AS percentage
  FROM volume_counts
  ORDER BY 
    CASE 
      WHEN prescribing_volume = 'high' THEN 1
      WHEN prescribing_volume = 'medium' THEN 2
      WHEN prescribing_volume = 'low' THEN 3
      ELSE 4
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to get providers by filter criteria
CREATE OR REPLACE FUNCTION get_providers_by_criteria(
  medication_ids TEXT[] DEFAULT NULL,
  excluded_medication_ids TEXT[] DEFAULT NULL,
  specialties TEXT[] DEFAULT NULL,
  regions TEXT[] DEFAULT NULL,
  prescribing_volume TEXT DEFAULT NULL,
  use_and_logic BOOLEAN DEFAULT FALSE,
  limit_count INTEGER DEFAULT 1000
) RETURNS TABLE (provider_id TEXT) AS $$
BEGIN
  IF use_and_logic THEN
    -- AND logic (all criteria must match)
    RETURN QUERY
    SELECT DISTINCT p.provider_id
    FROM providers p
    WHERE 
      (medication_ids IS NULL OR array_length(medication_ids, 1) IS NULL OR 
        p.provider_id IN (SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)))
      AND (specialties IS NULL OR array_length(specialties, 1) IS NULL OR p.specialty = ANY(specialties))
      AND (regions IS NULL OR array_length(regions, 1) IS NULL OR p.geographic_area = ANY(regions))
      AND (prescribing_volume IS NULL OR prescribing_volume = 'all' OR p.prescribing_volume = prescribing_volume)
    LIMIT limit_count;
  ELSE
    -- OR logic (any criteria can match)
    RETURN QUERY
    WITH medication_providers AS (
      SELECT provider_id FROM find_providers_by_medication(medication_ids, excluded_medication_ids)
      WHERE medication_ids IS NOT NULL AND array_length(medication_ids, 1) > 0
    ),
    specialty_providers AS (
      SELECT provider_id FROM providers 
      WHERE specialties IS NOT NULL AND array_length(specialties, 1) > 0 AND specialty = ANY(specialties)
    ),
    region_providers AS (
      SELECT provider_id FROM providers 
      WHERE regions IS NOT NULL AND array_length(regions, 1) > 0 AND geographic_area = ANY(regions)
    ),
    volume_providers AS (
      SELECT provider_id FROM providers 
      WHERE prescribing_volume IS NOT NULL AND prescribing_volume != 'all' AND prescribing_volume = prescribing_volume
    )
    SELECT DISTINCT provider_id
    FROM (
      SELECT provider_id FROM medication_providers
      UNION
      SELECT provider_id FROM specialty_providers
      UNION
      SELECT provider_id FROM region_providers
      UNION
      SELECT provider_id FROM volume_providers
    ) combined
    LIMIT limit_count;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Add a feature flag table to control rollout
CREATE TABLE IF NOT EXISTS feature_flags (
  flag_name TEXT PRIMARY KEY,
  enabled BOOLEAN NOT NULL DEFAULT false,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Insert the feature flag for the new provider query functions
INSERT INTO feature_flags (flag_name, enabled, description)
VALUES (
  'use_patient_prescriptions_for_targeting', 
  false, 
  'When enabled, campaign targeting and audience explorer will use patient_prescriptions data'
)
ON CONFLICT (flag_name) 
DO UPDATE SET 
  description = EXCLUDED.description,
  updated_at = now();

-- Function to check if a feature flag is enabled
CREATE OR REPLACE FUNCTION is_feature_enabled(flag_name TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  is_enabled BOOLEAN;
BEGIN
  SELECT enabled INTO is_enabled
  FROM feature_flags
  WHERE feature_flags.flag_name = $1;
  
  RETURN COALESCE(is_enabled, false);
END;
$$ LANGUAGE plpgsql;

COMMIT;
