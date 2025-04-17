-- Create historical campaign data with completed campaigns
-- This migration adds three diverse completed campaigns with different targeting criteria

BEGIN;

-- Helper function to get a random user ID (for created_by field)
CREATE OR REPLACE FUNCTION get_random_user_id()
RETURNS UUID AS $$
DECLARE
  user_id UUID;
BEGIN
  SELECT id INTO user_id FROM auth.users LIMIT 1;
  
  -- If no users exist, return a placeholder UUID
  IF user_id IS NULL THEN
    user_id := '00000000-0000-0000-0000-000000000000'::UUID;
  END IF;
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;

-- Check if code column exists in medications table; if not, add it
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'code'
  ) THEN
    ALTER TABLE medications ADD COLUMN code TEXT UNIQUE;
  END IF;
END $$;

-- Create medication reference data and insert campaigns
DO $$
DECLARE
  cardio_med_id UUID;
  cardio_comp1_id UUID;
  cardio_comp2_id UUID;
  diabetes_med_id UUID;
  diabetes_comp1_id UUID;
  diabetes_comp2_id UUID;
  neuro_med_id UUID;
  neuro_comp1_id UUID;
  neuro_comp2_id UUID;
  random_user_id UUID;
BEGIN
  -- Get a random user ID for the created_by field
  SELECT get_random_user_id() INTO random_user_id;

  -- Insert or get medications
  INSERT INTO medications (code, name, category, description)
  VALUES 
    ('med-cardioxr-001', 'CardioGuard XR', 'Cardiovascular', 'Extended release cardiovascular medication'),
    ('med-cardio-comp1', 'CardioShield', 'Cardiovascular', 'Competitor cardiovascular medication'),
    ('med-cardio-comp2', 'HeartGuard', 'Cardiovascular', 'Competitor cardiovascular medication'),
    ('med-gluco-001', 'GlucoCare', 'Diabetes', 'Advanced diabetes management medication'),
    ('med-gluco-comp1', 'DiabetesShield', 'Diabetes', 'Competitor diabetes medication'),
    ('med-gluco-comp2', 'GlucoMax', 'Diabetes', 'Competitor diabetes medication'),
    ('med-neuro-001', 'NeuroCare', 'Neurology', 'Advanced neurological treatment'),
    ('med-neuro-comp1', 'NeuroShield', 'Neurology', 'Competitor neurological medication'),
    ('med-neuro-comp2', 'BrainGuard', 'Neurology', 'Competitor neurological medication')
  ON CONFLICT (code) DO UPDATE 
  SET name = EXCLUDED.name
  RETURNING id, code INTO cardio_med_id, 'med-cardioxr-001'::text;

  -- Get other medication IDs
  SELECT id INTO cardio_comp1_id FROM medications WHERE code = 'med-cardio-comp1';
  SELECT id INTO cardio_comp2_id FROM medications WHERE code = 'med-cardio-comp2';
  SELECT id INTO diabetes_med_id FROM medications WHERE code = 'med-gluco-001';
  SELECT id INTO diabetes_comp1_id FROM medications WHERE code = 'med-gluco-comp1';
  SELECT id INTO diabetes_comp2_id FROM medications WHERE code = 'med-gluco-comp2';
  SELECT id INTO neuro_med_id FROM medications WHERE code = 'med-neuro-001';
  SELECT id INTO neuro_comp1_id FROM medications WHERE code = 'med-neuro-comp1';
  SELECT id INTO neuro_comp2_id FROM medications WHERE code = 'med-neuro-comp2';

  -- Delete existing sample campaigns if they exist
  DELETE FROM campaigns WHERE name IN (
    'CardioGuard XR Market Expansion',
    'GlucoCare 360 Initiative',
    'NeuroCare Access Program'
  );

  -- Campaign 1: CardioGuard XR Market Expansion (Completed 3 months ago)
  INSERT INTO campaigns (
    id,
    name,
    target_medication_id,
    target_specialty,
    target_geographic_area,
    status,
    targeting_logic,
    targeting_metadata,
    start_date,
    end_date,
    created_by,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    'CardioGuard XR Market Expansion',
    cardio_med_id,
    'Cardiology',
    'Northeast',
    'completed',
    'and',
    json_build_object(
      'medicationCategory', 'Cardiovascular',
      'excluded_medications', ARRAY[cardio_comp1_id::text, cardio_comp2_id::text],
      'prescribing_volume', 'high',
      'timeframe', 'last_quarter',
      'multi_specialty', json_build_object(
        'specialties', ARRAY['Cardiology'],
        'primary_focus', 'Cardiology'
      ),
      'multi_region', ARRAY['Northeast', 'Southeast'],
      'campaign_phases', json_build_array(
        json_build_object(
          'phase', 'Initial Launch',
          'duration_days', 30,
          'target_lift', 15
        ),
        json_build_object(
          'phase', 'Market Expansion',
          'duration_days', 30,
          'target_lift', 25
        ),
        json_build_object(
          'phase', 'Optimization',
          'duration_days', 30,
          'target_lift', 30
        )
      )
    ),
    (CURRENT_DATE - INTERVAL '6 months')::date,
    (CURRENT_DATE - INTERVAL '3 months')::date,
    random_user_id,
    (CURRENT_DATE - INTERVAL '7 months')::timestamp with time zone
  );

  -- Campaign 2: GlucoCare 360 Initiative (Completed 2 months ago)
  INSERT INTO campaigns (
    id,
    name,
    target_medication_id,
    target_specialty,
    target_geographic_area,
    status,
    targeting_logic,
    targeting_metadata,
    start_date,
    end_date,
    created_by,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    'GlucoCare 360 Initiative',
    diabetes_med_id,
    'Endocrinology',
    'Nationwide',
    'completed',
    'and',
    json_build_object(
      'medicationCategory', 'Diabetes',
      'excluded_medications', ARRAY[diabetes_comp1_id::text, diabetes_comp2_id::text],
      'prescribing_volume', 'medium',
      'timeframe', 'last_quarter',
      'multi_specialty', json_build_object(
        'specialties', ARRAY['Endocrinology', 'Primary Care'],
        'primary_focus', 'Endocrinology',
        'specialty_phases', json_build_object(
          'Endocrinology', 1,
          'Primary Care', 2
        )
      ),
      'multi_region', ARRAY['Nationwide'],
      'campaign_phases', json_build_array(
        json_build_object(
          'phase', 'Specialist Focus',
          'duration_days', 30,
          'target_lift', 20
        ),
        json_build_object(
          'phase', 'Primary Care Expansion',
          'duration_days', 30,
          'target_lift', 15
        )
      )
    ),
    (CURRENT_DATE - INTERVAL '4 months')::date,
    (CURRENT_DATE - INTERVAL '2 months')::date,
    random_user_id,
    (CURRENT_DATE - INTERVAL '5 months')::timestamp with time zone
  );

  -- Campaign 3: NeuroCare Access Program (Completed 1 month ago)
  INSERT INTO campaigns (
    id,
    name,
    target_medication_id,
    target_specialty,
    target_geographic_area,
    status,
    targeting_logic,
    targeting_metadata,
    start_date,
    end_date,
    created_by,
    created_at
  )
  VALUES (
    gen_random_uuid(),
    'NeuroCare Access Program',
    neuro_med_id,
    'Neurology',
    'Midwest',
    'completed',
    'and',
    json_build_object(
      'medicationCategory', 'Neurology',
      'excluded_medications', ARRAY[neuro_comp1_id::text, neuro_comp2_id::text],
      'prescribing_volume', 'all',
      'timeframe', 'last_quarter',
      'multi_specialty', json_build_object(
        'specialties', ARRAY['Neurology'],
        'primary_focus', 'Neurology'
      ),
      'multi_region', ARRAY['Midwest', 'Southwest'],
      'campaign_phases', json_build_array(
        json_build_object(
          'phase', 'Regional Launch',
          'duration_days', 30,
          'target_lift', 12
        ),
        json_build_object(
          'phase', 'Market Penetration',
          'duration_days', 30,
          'target_lift', 18
        )
      )
    ),
    (CURRENT_DATE - INTERVAL '3 months')::date,
    (CURRENT_DATE - INTERVAL '1 month')::date,
    random_user_id,
    (CURRENT_DATE - INTERVAL '4 months')::timestamp with time zone
  );

END $$;

-- Clean up helper function
DROP FUNCTION IF EXISTS get_random_user_id();

-- Return campaign IDs for verification
SELECT id, name, status, start_date, end_date 
FROM campaigns 
WHERE name IN (
  'CardioGuard XR Market Expansion',
  'GlucoCare 360 Initiative',
  'NeuroCare Access Program'
)
ORDER BY start_date DESC;

COMMIT;
