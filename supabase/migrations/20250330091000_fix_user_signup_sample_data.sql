-- Migration: Fix user signup sample data
-- This migration creates a dedicated table for campaign templates
-- and updates the copy_sample_data_for_new_user function
-- to correctly copy sample data for new users

BEGIN;

-- Create a dedicated table for sample campaign templates
CREATE TABLE IF NOT EXISTS public.sample_campaign_templates (
  id VARCHAR(20) PRIMARY KEY, -- Fixed ID for reliable reference
  name VARCHAR(255) NOT NULL,
  target_medication_id UUID,
  target_condition_id UUID,
  target_specialty VARCHAR(100),
  target_geographic_area VARCHAR(100),
  status VARCHAR(20) DEFAULT 'completed',
  targeting_logic VARCHAR(10) DEFAULT 'and',
  targeting_metadata JSONB,
  start_date DATE,
  end_date DATE,
  budget NUMERIC(12, 2),
  is_sample BOOLEAN DEFAULT TRUE
);

-- Check if sample_campaign_templates is empty
-- If so, populate it with our three sample campaigns
DO $$
DECLARE
  cardio_med_id UUID;
  neuro_med_id UUID;
  immuno_med_id UUID;
BEGIN
  -- Only populate if the table is empty
  IF NOT EXISTS (SELECT 1 FROM public.sample_campaign_templates LIMIT 1) THEN
    -- Get medication IDs (or create them if they don't exist)
    SELECT id INTO cardio_med_id FROM medications 
    WHERE code = 'med-cardioguard-001' OR name = 'CardioGuard Plus' 
    LIMIT 1;
    
    IF cardio_med_id IS NULL THEN
      INSERT INTO medications (name, category, description, code)
      VALUES ('CardioGuard Plus', 'Cardiovascular', 'Next-generation cardiovascular medication', 'med-cardioguard-001')
      RETURNING id INTO cardio_med_id;
    END IF;
    
    SELECT id INTO neuro_med_id FROM medications 
    WHERE code = 'med-neurobalance-001' OR name = 'NeuroBalance' 
    LIMIT 1;
    
    IF neuro_med_id IS NULL THEN
      INSERT INTO medications (name, category, description, code)
      VALUES ('NeuroBalance', 'Neurology', 'Advanced neurological treatment', 'med-neurobalance-001')
      RETURNING id INTO neuro_med_id;
    END IF;
    
    SELECT id INTO immuno_med_id FROM medications 
    WHERE code = 'med-immunotherapy-001' OR name = 'ImmunoTherapy 5' 
    LIMIT 1;
    
    IF immuno_med_id IS NULL THEN
      INSERT INTO medications (name, category, description, code)
      VALUES ('ImmunoTherapy 5', 'Immunology', 'Revolutionary immunotherapy treatment', 'med-immunotherapy-001')
      RETURNING id INTO immuno_med_id;
    END IF;
    
    -- Insert template campaigns with fixed IDs
    -- Template 1: CardioGuard Plus Launch
    INSERT INTO public.sample_campaign_templates (
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
      budget
    )
    VALUES (
      'template1',
      'CardioGuard Plus Launch',
      cardio_med_id,
      'Cardiology',
      'Northeast',
      'completed',
      'and',
      json_build_object(
        'medicationCategory', 'Cardiovascular',
        'prescribing_volume', 'all',
        'timeframe', 'last_quarter',
        'multi_specialty', json_build_object(
          'specialties', ARRAY['Cardiology', 'Endocrinology', 'Primary Care'],
          'primary_focus', 'Cardiology'
        ),
        'multi_region', ARRAY['Northeast', 'Midwest']
      ),
      (CURRENT_DATE - INTERVAL '90 days')::date,
      (CURRENT_DATE - INTERVAL '10 days')::date,
      75000
    );
    
    -- Template 2: NeuroBalance Multi-Specialty Initiative
    INSERT INTO public.sample_campaign_templates (
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
      budget
    )
    VALUES (
      'template2',
      'NeuroBalance Multi-Specialty Initiative',
      neuro_med_id,
      'Psychiatry',
      'West',
      'active',
      'and',
      json_build_object(
        'medicationCategory', 'Neurology',
        'prescribing_volume', 'high',
        'timeframe', 'last_month',
        'multi_specialty', json_build_object(
          'specialties', ARRAY['Psychiatry', 'Neurology', 'Primary Care', 'Geriatric Medicine'],
          'primary_focus', 'Psychiatry'
        ),
        'multi_region', ARRAY['West', 'Southwest']
      ),
      (CURRENT_DATE - INTERVAL '45 days')::date,
      (CURRENT_DATE + INTERVAL '15 days')::date,
      60000
    );
    
    -- Template 3: ImmunoTherapy Access Program
    INSERT INTO public.sample_campaign_templates (
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
      budget
    )
    VALUES (
      'template3',
      'ImmunoTherapy Access Program',
      immuno_med_id,
      'Oncology',
      'Nationwide',
      'completed',
      'and',
      json_build_object(
        'medicationCategory', 'Immunology',
        'prescribing_volume', 'medium',
        'timeframe', 'last_quarter',
        'multi_specialty', json_build_object(
          'specialties', ARRAY['Oncology', 'Rheumatology', 'Gastroenterology', 'Dermatology'],
          'primary_focus', 'Oncology'
        )
      ),
      (CURRENT_DATE - INTERVAL '60 days')::date,
      (CURRENT_DATE - INTERVAL '18 days')::date,
      85000
    );
  END IF;
END $$;

-- Drop the existing function first
DROP FUNCTION IF EXISTS public.copy_sample_data_for_new_user(UUID);

-- Create improved copy_sample_data_for_new_user function
-- that uses the sample_campaign_templates table
CREATE FUNCTION public.copy_sample_data_for_new_user(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  campaign_count INTEGER;
  new_campaign_id UUID;
  template RECORD;
  success BOOLEAN := TRUE;
BEGIN
  -- Exit early if user_id is null
  IF p_user_id IS NULL THEN
    RAISE NOTICE 'Cannot copy sample data: User ID is null';
    RETURN FALSE;
  END IF;

  -- First ensure this user has a profile
  BEGIN
    INSERT INTO public.profiles (id, role)
    VALUES (p_user_id, 'user')
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error creating user profile: %', SQLERRM;
    -- Continue anyway since this shouldn't prevent campaign creation
  END;
  
  -- Check if user already has campaigns
  SELECT COUNT(*) INTO campaign_count 
  FROM campaigns 
  WHERE created_by = p_user_id;
  
  -- Only add sample data if user has no campaigns
  IF campaign_count = 0 THEN
    -- Loop through each template and create a campaign for the user
    FOR template IN 
      SELECT * FROM public.sample_campaign_templates 
      ORDER BY id
    LOOP
      BEGIN
        -- Insert campaign from template
        INSERT INTO campaigns (
          name, 
          target_medication_id, 
          target_specialty, 
          target_geographic_area, 
          status, 
          targeting_logic,
          targeting_metadata,
          start_date, 
          end_date, 
          budget,
          created_by,
          is_sample
        )
        VALUES (
          template.name,
          template.target_medication_id,
          template.target_specialty,
          template.target_geographic_area,
          template.status,
          template.targeting_logic,
          template.targeting_metadata,
          template.start_date,
          template.end_date,
          template.budget,
          p_user_id,
          TRUE
        )
        RETURNING id INTO new_campaign_id;
        
        -- Generate campaign results for this new campaign
        -- Only if create_campaign_results_v2 function exists
        IF EXISTS (
          SELECT 1 FROM pg_proc 
          WHERE proname = 'create_campaign_results_v2'
        ) THEN
          BEGIN
            PERFORM public.create_campaign_results_v2(new_campaign_id);
          EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error generating campaign results: %', SQLERRM;
            -- Continue even if results generation fails
          END;
        END IF;
        
        -- Generate script lift data if the function exists
        IF EXISTS (
          SELECT 1 FROM pg_proc 
          WHERE proname = 'generate_script_lift_data'
        ) THEN
          BEGIN
            PERFORM public.generate_script_lift_data(new_campaign_id);
          EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error generating script lift data: %', SQLERRM;
            -- Continue even if script lift generation fails
          END;
        END IF;
        
        RAISE NOTICE 'Created sample campaign "%s" for user %s', template.name, p_user_id;
      EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Error creating sample campaign "%s": %', template.name, SQLERRM;
        success := FALSE;
        -- Continue with next template
      END;
    END LOOP;
    
    RETURN success;
  ELSE
    RAISE NOTICE 'User % already has % campaigns - not adding sample data', p_user_id, campaign_count;
    RETURN TRUE; -- It's not an error if the user already has campaigns
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- Catch any unexpected errors
    RAISE NOTICE 'Unexpected error in copy_sample_data_for_new_user: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the function by showing that it exists
DO $$
BEGIN
  RAISE NOTICE 'Successfully created sample_campaign_templates table and updated copy_sample_data_for_new_user function';
END $$;

COMMIT;
