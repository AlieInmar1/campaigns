-- Migration: Create Provider Filtering Index Table and Functions
-- This migration adds a prescription index table and filtering functions to optimize provider queries

BEGIN;


-- 1. Create the medication_provider_time_index table for optimized filtering
CREATE TABLE IF NOT EXISTS medication_provider_time_index (
  medication_id UUID REFERENCES medications(id),
  provider_id UUID REFERENCES providers(id),
  prescription_month DATE NOT NULL, -- First day of month for aggregation
  is_brand BOOLEAN NOT NULL, -- Whether medication is brand or generic
  new_prescription_count INTEGER DEFAULT 0, -- Count of new prescriptions
  refill_count INTEGER DEFAULT 0, -- Count of refills
  total_count INTEGER DEFAULT 0, -- Total of new + refills

  PRIMARY KEY (medication_id, provider_id, prescription_month)
);

-- Create indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_mpti_med_id ON medication_provider_time_index(medication_id);
CREATE INDEX IF NOT EXISTS idx_mpti_provider_id ON medication_provider_time_index(provider_id);
CREATE INDEX IF NOT EXISTS idx_mpti_month ON medication_provider_time_index(prescription_month);
CREATE INDEX IF NOT EXISTS idx_mpti_brand ON medication_provider_time_index(is_brand);

-- Add table comment
COMMENT ON TABLE medication_provider_time_index IS 
  'Pre-aggregated index of provider prescriptions by medication, month, and brand status for optimized filtering';

-- 2. Create function to populate the index table
CREATE OR REPLACE FUNCTION populate_medication_provider_time_index() 
RETURNS INTEGER AS $$
DECLARE
  inserted_count INTEGER := 0;
BEGIN
  -- Clear existing data
  TRUNCATE TABLE medication_provider_time_index;
  
  -- Insert aggregated data
  INSERT INTO medication_provider_time_index
    (medication_id, provider_id, prescription_month, is_brand, 
     new_prescription_count, refill_count, total_count)
  SELECT 
    pp.medication_id,
    pp.provider_id,
    DATE_TRUNC('month', pp.prescription_date)::DATE AS prescription_month,
    COALESCE(m.brand_generic = 'brand', FALSE) AS is_brand,
    COUNT(*) FILTER (WHERE pp.is_new = true) AS new_prescription_count,
    COUNT(*) FILTER (WHERE pp.is_new = false) AS refill_count,
    COUNT(*) AS total_count
  FROM 
    patient_prescriptions pp
  JOIN 
    medications m ON pp.medication_id = m.id
  GROUP BY
    pp.medication_id, pp.provider_id, 
    DATE_TRUNC('month', pp.prescription_date)::DATE, 
    COALESCE(m.brand_generic = 'brand', FALSE);
  
  GET DIAGNOSTICS inserted_count = ROW_COUNT;
  
  RETURN inserted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION populate_medication_provider_time_index() IS
  'Populates the medication_provider_time_index table from raw prescription data';

-- 3. Create enhanced provider filtering function
CREATE OR REPLACE FUNCTION get_filtered_providers(
  specialties TEXT[] DEFAULT NULL,
  medication_category TEXT DEFAULT NULL,
  included_medication_ids UUID[] DEFAULT NULL,
  excluded_medication_ids UUID[] DEFAULT NULL,
  brand_preference TEXT DEFAULT 'both',
  regions TEXT[] DEFAULT NULL,
  timeframe TEXT DEFAULT 'year',
  reference_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
  provider_id UUID,
  prescription_count BIGINT
) AS $$
DECLARE
  start_date DATE;
BEGIN
  -- Calculate timeframe
  IF timeframe = 'month' THEN
    start_date := date_trunc('month', reference_date - interval '1 month')::DATE;
  ELSIF timeframe = 'quarter' THEN
    start_date := date_trunc('quarter', reference_date - interval '3 month')::DATE;
  ELSIF timeframe = 'year' THEN
    start_date := date_trunc('year', reference_date - interval '1 year')::DATE;
  ELSE
    start_date := '1900-01-01'::DATE;
  END IF;

  -- Ensure at least one primary filter is applied
  IF (specialties IS NULL OR array_length(specialties, 1) IS NULL) AND 
     medication_category IS NULL AND
     (included_medication_ids IS NULL OR array_length(included_medication_ids, 1) IS NULL) THEN
    RAISE EXCEPTION 'At least one primary filter (specialty, medication category, or specific medications) must be applied';
  END IF;

  RETURN QUERY
  WITH filtered_providers AS (
    SELECT DISTINCT p.id AS provider_id, SUM(COALESCE(mpti.total_count, 0)) AS prescription_count
    FROM providers p
    LEFT JOIN medication_provider_time_index mpti ON p.id = mpti.provider_id
    LEFT JOIN medications m ON mpti.medication_id = m.id
    WHERE
      -- Primary filters
      (
        (specialties IS NOT NULL AND array_length(specialties, 1) > 0 AND p.specialty = ANY(specialties))
        OR
        (medication_category IS NOT NULL AND m.category = medication_category)
        OR
        (included_medication_ids IS NOT NULL AND array_length(included_medication_ids, 1) > 0 AND mpti.medication_id = ANY(included_medication_ids))
      )
      -- Brand preference filter (only if brand_preference is specified)
      AND (
        brand_preference = 'both'
        OR (brand_preference = 'brand' AND mpti.is_brand = TRUE)
        OR (brand_preference = 'generic' AND mpti.is_brand = FALSE)
      )
      -- Region filter (only if regions is specified)
      AND (
        regions IS NULL
        OR array_length(regions, 1) IS NULL
        OR p.geographic_area = ANY(regions)
      )
      -- Timeframe filter
      AND (mpti.prescription_month IS NULL OR mpti.prescription_month >= start_date)
    GROUP BY p.id
  )
  SELECT fp.provider_id, fp.prescription_count
  FROM filtered_providers fp
  WHERE NOT EXISTS (
    -- Exclude providers who prescribed excluded medications
    SELECT 1
    FROM medication_provider_time_index mpti_excl
    WHERE mpti_excl.provider_id = fp.provider_id
    AND excluded_medication_ids IS NOT NULL
    AND array_length(excluded_medication_ids, 1) > 0
    AND mpti_excl.medication_id = ANY(excluded_medication_ids)
    AND mpti_excl.prescription_month >= start_date
  )
  ORDER BY fp.prescription_count DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_filtered_providers IS
  'Get providers filtered by specialty, medication category, specific medications, brand preference, region, and timeframe';

-- 4. Create a function to estimate the provider count without fetching all records
CREATE OR REPLACE FUNCTION estimate_filtered_provider_count(
  specialties TEXT[] DEFAULT NULL,
  medication_category TEXT DEFAULT NULL,
  included_medication_ids UUID[] DEFAULT NULL,
  excluded_medication_ids UUID[] DEFAULT NULL,
  brand_preference TEXT DEFAULT 'both',
  regions TEXT[] DEFAULT NULL,
  timeframe TEXT DEFAULT 'year',
  reference_date DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER AS $$
DECLARE
  estimated_count INTEGER;
BEGIN
  SELECT COUNT(DISTINCT provider_id)
  INTO estimated_count
  FROM get_filtered_providers(
    specialties,
    medication_category,
    included_medication_ids,
    excluded_medication_ids,
    brand_preference,
    regions,
    timeframe,
    reference_date
  );
  
  RETURN estimated_count;
EXCEPTION
  WHEN OTHERS THEN
    RETURN 0;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION estimate_filtered_provider_count IS
  'Estimate the number of providers matching the specified filters';

-- 5. Create an initial population job
DO $$
BEGIN
  RAISE NOTICE 'Populating medication_provider_time_index...';
  PERFORM populate_medication_provider_time_index();
  RAISE NOTICE 'Finished populating index';
END;
$$;

COMMIT;
