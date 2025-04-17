-- Add descriptions to campaigns and create historical campaigns
BEGIN;

-- Add description column to campaigns table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'campaigns' AND column_name = 'description'
  ) THEN
    ALTER TABLE campaigns ADD COLUMN description TEXT;
  END IF;
END $$;

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

-- Create medication reference data and insert campaigns
DO $$
DECLARE
  random_user_id UUID;
  glp1_campaign_id UUID;
  ace_campaign_id UUID;
  resp_campaign_id UUID;
BEGIN
  -- Get a random user ID for the created_by field
  SELECT get_random_user_id() INTO random_user_id;

  -- Delete existing sample campaigns if they exist
  DELETE FROM campaigns WHERE name IN (
    'GLP-1 Innovation Initiative',
    'ACE to ARB Evolution',
    'Respiratory Care Advancement'
  );

  -- Campaign 1: GLP-1 Innovation Initiative
  INSERT INTO campaigns (
    id,
    name,
    description,
    target_specialty,
    target_geographic_area,
    status,
    targeting_logic,
    targeting_metadata,
    start_date,
    end_date,
    created_by,
    created_at
  ) VALUES (
    gen_random_uuid(),
    'GLP-1 Innovation Initiative',
    'Strategic campaign targeting traditional diabetes medication prescribers in the Southeast and Southwest regions, where diabetes prevalence is 12% higher than the national average. Focuses on providers with established Metformin and Sulfonylurea prescribing patterns but limited GLP-1 adoption. Excludes current high-volume GLP-1 prescribers to optimize resource allocation. Campaign leverages real-world evidence showing 32% better A1C control with GLP-1s vs traditional therapies. Unique dual-specialty approach targeting both Endocrinologists for their specialist influence and Primary Care physicians who manage 70% of diabetes patients.',
    'Endocrinology',
    'Southeast',
    'completed',
    'and',
    json_build_object(
      'medicationCategory', 'Diabetes',
      'target_medications', ARRAY['Biguanide', 'Sulfonylurea']::text[],
      'excluded_medications', ARRAY['GLP-1 Receptor Agonist']::text[],
      'prescribing_volume', 'high',
      'timeframe', 'last_quarter',
      'multi_specialty', json_build_object(
        'specialties', ARRAY['Endocrinology', 'Primary Care']::text[],
        'primary_focus', 'Endocrinology'
      ),
      'multi_region', ARRAY['Southeast', 'Southwest']::text[],
      'targeting_criteria', json_build_object(
        'min_traditional_prescriptions', 100,
        'max_glp1_prescriptions', 20,
        'patient_threshold', 50
      )
    ),
    (CURRENT_DATE - INTERVAL '6 months')::date,
    (CURRENT_DATE - INTERVAL '3 months')::date,
    random_user_id,
    (CURRENT_DATE - INTERVAL '7 months')::timestamp with time zone
  ) RETURNING id INTO glp1_campaign_id;

  -- Campaign 2: ACE to ARB Evolution
  INSERT INTO campaigns (
    id,
    name,
    description,
    target_specialty,
    target_geographic_area,
    status,
    targeting_logic,
    targeting_metadata,
    start_date,
    end_date,
    created_by,
    created_at
  ) VALUES (
    gen_random_uuid(),
    'ACE to ARB Evolution',
    'Precision-targeted initiative focusing on high-volume ACE inhibitor prescribers in the Northeast and Midwest markets. Campaign capitalizes on recent studies showing 23% fewer side effects with ARBs compared to ACE inhibitors, particularly in specific patient demographics. Sophisticated targeting excludes existing high-volume ARB prescribers to focus resources on providers most likely to modify prescribing patterns. Multi-phase approach includes initial data-driven provider identification, followed by personalized engagement based on individual prescribing patterns. Special emphasis on providers managing diverse patient populations where ARBs show superior tolerance profiles.',
    'Cardiology',
    'Northeast',
    'completed',
    'and',
    json_build_object(
      'medicationCategory', 'Cardiovascular',
      'target_medications', ARRAY['ACE Inhibitor']::text[],
      'excluded_medications', ARRAY['ARB']::text[],
      'prescribing_volume', 'high',
      'timeframe', 'last_quarter',
      'multi_specialty', json_build_object(
        'specialties', ARRAY['Cardiology', 'Primary Care']::text[],
        'primary_focus', 'Cardiology'
      ),
      'multi_region', ARRAY['Northeast', 'Midwest']::text[],
      'targeting_criteria', json_build_object(
        'min_ace_prescriptions', 200,
        'max_arb_prescriptions', 50,
        'patient_threshold', 100
      )
    ),
    (CURRENT_DATE - INTERVAL '4 months')::date,
    (CURRENT_DATE - INTERVAL '2 months')::date,
    random_user_id,
    (CURRENT_DATE - INTERVAL '5 months')::timestamp with time zone
  ) RETURNING id INTO ace_campaign_id;

  -- Campaign 3: Respiratory Care Advancement
  INSERT INTO campaigns (
    id,
    name,
    description,
    target_specialty,
    target_geographic_area,
    status,
    targeting_logic,
    targeting_metadata,
    start_date,
    end_date,
    created_by,
    created_at
  ) VALUES (
    gen_random_uuid(),
    'Respiratory Care Advancement',
    'Innovative market entry campaign in the West and Northwest regions, targeting providers actively prescribing traditional respiratory medications. Unlike conventional launches, this campaign takes a comprehensive approach by not excluding any prescriber segments, recognizing the complex nature of respiratory care where providers often need multiple treatment options. Data analysis shows these regions have 28% higher seasonal respiratory issues and growing patient demand for new treatment options. Campaign leverages insights from 10,000+ patient prescription patterns to identify optimal timing for provider engagement based on seasonal prescribing trends. Includes special focus on providers managing patients with multiple respiratory conditions who could benefit from simplified treatment regimens.',
    'Pulmonology',
    'West',
    'completed',
    'and',
    json_build_object(
      'medicationCategory', 'Respiratory',
      'target_medications', ARRAY['Short-acting Beta Agonist', 'Inhaled Corticosteroid']::text[],
      'excluded_medications', ARRAY[]::text[],
      'prescribing_volume', 'all',
      'timeframe', 'last_quarter',
      'multi_specialty', json_build_object(
        'specialties', ARRAY['Pulmonology', 'Primary Care']::text[],
        'primary_focus', 'Pulmonology'
      ),
      'multi_region', ARRAY['West', 'Northwest']::text[],
      'targeting_criteria', json_build_object(
        'min_respiratory_prescriptions', 50,
        'seasonal_focus', true,
        'patient_threshold', 30
      )
    ),
    (CURRENT_DATE - INTERVAL '3 months')::date,
    (CURRENT_DATE - INTERVAL '1 month')::date,
    random_user_id,
    (CURRENT_DATE - INTERVAL '4 months')::timestamp with time zone
  ) RETURNING id INTO resp_campaign_id;

END $$;

-- Clean up helper function
DROP FUNCTION IF EXISTS get_random_user_id();

-- Return campaign info for verification
SELECT 
  id,
  name,
  target_specialty,
  target_geographic_area,
  status,
  start_date,
  end_date,
  substring(description, 1, 50) || '...' as description_preview,
  targeting_metadata->>'medicationCategory' as medication_category
FROM campaigns 
WHERE name IN (
  'GLP-1 Innovation Initiative',
  'ACE to ARB Evolution',
  'Respiratory Care Advancement'
)
ORDER BY start_date DESC;

COMMIT;
