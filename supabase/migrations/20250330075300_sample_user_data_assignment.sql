-- Migration: Sample User Data Assignment (Part 4)
-- Creates functions for assigning sample data to users
-- This is a self-contained migration with proper BEGIN/COMMIT

BEGIN;

-- Reference the SQL function defined in the first migration
-- This ensures all files use the same implementation of random_array_element
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'random_array_element'
  ) THEN
    EXECUTE $func$
      CREATE OR REPLACE FUNCTION public.random_array_element(arr ANYARRAY)
      RETURNS ANYELEMENT AS $body$
        SELECT arr[1 + floor(random() * array_length(arr, 1))::INTEGER];
      $body$ LANGUAGE sql;
    $func$;
  END IF;
END $$;

-------------------------
-- USER DATA ASSIGNMENT
-------------------------

-- Create campaign_provider_targets table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.campaign_provider_targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL,
  targeting_reason TEXT,
  potential_lift_score NUMERIC(5,2),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_campaign_provider_targets_campaign_id 
ON public.campaign_provider_targets(campaign_id);

CREATE INDEX IF NOT EXISTS idx_campaign_provider_targets_provider_id 
ON public.campaign_provider_targets(provider_id);

-- Create campaign_metrics table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.campaign_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  engagement_score NUMERIC(5,2),
  script_lift_percentage NUMERIC(6,2),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_campaign_metrics_campaign_id 
ON public.campaign_metrics(campaign_id);

CREATE INDEX IF NOT EXISTS idx_campaign_metrics_provider_id 
ON public.campaign_metrics(provider_id);

-- Function to create sample campaigns for a user
CREATE OR REPLACE FUNCTION public.create_sample_campaigns_for_user(user_id UUID)
RETURNS VOID AS $$
DECLARE
  diabetes_campaign_id UUID;
  cardio_campaign_id UUID;
  respiratory_campaign_id UUID;
  now_date DATE := CURRENT_DATE;
  end_date DATE := now_date + INTERVAL '3 months';
BEGIN
  -- 1. Create Diabetes Campaign
  INSERT INTO public.campaigns (
    name,
    description,
    status,
    start_date,
    end_date,
    target_specialty,
    region,
    medication_category,
    budget,
    created_by,
    is_sample
  ) VALUES (
    'Diabetes Care Outreach',
    'Campaign targeting endocrinologists and PCPs to promote our diabetes medication portfolio.',
    'Active',
    now_date,
    end_date,
    'Endocrinology',
    'Northeast',
    'Diabetes',
    75000,
    user_id,
    TRUE
  ) RETURNING id INTO diabetes_campaign_id;
  
  -- 2. Create Cardiovascular Campaign
  INSERT INTO public.campaigns (
    name,
    description,
    status,
    start_date,
    end_date,
    target_specialty,
    region,
    medication_category,
    budget,
    created_by,
    is_sample
  ) VALUES (
    'Cardiovascular Health Initiative',
    'Focused campaign for cardiologists in the West region to promote our cardiovascular medications.',
    'Active',
    now_date,
    end_date,
    'Cardiology',
    'West',
    'Hypertension',
    60000,
    user_id,
    TRUE
  ) RETURNING id INTO cardio_campaign_id;
  
  -- 3. Create Respiratory Campaign
  INSERT INTO public.campaigns (
    name,
    description,
    status,
    start_date,
    end_date,
    target_specialty,
    region,
    medication_category,
    budget,
    created_by,
    is_sample
  ) VALUES (
    'Respiratory Care Awareness',
    'Campaign targeting pulmonologists and PCPs in the Midwest to increase awareness of our respiratory medication line.',
    'Active',
    now_date,
    end_date,
    'Pulmonology',
    'Midwest',
    'Respiratory',
    50000,
    user_id,
    TRUE
  ) RETURNING id INTO respiratory_campaign_id;
  
  -- Generate sample data for these campaigns
  PERFORM public.generate_all_sample_data(
    diabetes_campaign_id,
    cardio_campaign_id,
    respiratory_campaign_id
  );
  
  -- Copy the sample data to associate with the user's campaigns
  PERFORM public.copy_sample_data_for_user(
    user_id,
    diabetes_campaign_id,
    cardio_campaign_id,
    respiratory_campaign_id
  );
END;
$$ LANGUAGE plpgsql;

-- Function to copy sample data for a specific user
CREATE OR REPLACE FUNCTION public.copy_sample_data_for_user(
  user_id UUID,
  campaign_1_id UUID, 
  campaign_2_id UUID, 
  campaign_3_id UUID
)
RETURNS VOID AS $$
DECLARE
  original_campaign_ids UUID[] := ARRAY[
    campaign_1_id, 
    campaign_2_id, 
    campaign_3_id
  ];
  copied_targets INTEGER;
  copied_metrics INTEGER;
BEGIN
  -- For each campaign, link it to the appropriate subset of provider targets
  FOR i IN 1..3 LOOP
    -- Copy the targeted providers for this campaign
    WITH inserted_targets AS (
      INSERT INTO public.campaign_provider_targets (
        campaign_id,
        provider_id,
        targeting_reason,
        potential_lift_score,
        created_by,
        created_at
      )
      SELECT 
        original_campaign_ids[i],
        spt.provider_id,
        spt.targeting_reason,
        spt.potential_lift_score,
        user_id,
        NOW()
      FROM public.sample_provider_targets spt
      WHERE spt.campaign_id = original_campaign_ids[i]
      RETURNING 1
    )
    SELECT COUNT(*) INTO copied_targets FROM inserted_targets;
    
    -- Copy the campaign metrics
    WITH inserted_metrics AS (
      INSERT INTO public.campaign_metrics (
        campaign_id,
        provider_id,
        impressions,
        clicks,
        engagement_score,
        script_lift_percentage,
        created_by,
        created_at
      )
      SELECT
        original_campaign_ids[i],
        scm.provider_id,
        scm.impressions,
        scm.clicks,
        scm.engagement_score,
        scm.script_lift_percentage,
        user_id,
        NOW()
      FROM public.sample_campaign_metrics scm
      WHERE scm.campaign_id = original_campaign_ids[i]
      RETURNING 1
    )
    SELECT COUNT(*) INTO copied_metrics FROM inserted_metrics;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Trigger to create sample campaigns for new users
CREATE OR REPLACE FUNCTION public.create_sample_campaigns_after_signup()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create sample campaigns for new users (not admins or existing users)
  IF NEW.role = 'user' AND TG_OP = 'INSERT' THEN
    PERFORM public.create_sample_campaigns_for_user(NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on profiles table (if it doesn't exist)
DROP TRIGGER IF EXISTS create_sample_campaigns_after_signup ON public.profiles;
CREATE TRIGGER create_sample_campaigns_after_signup
AFTER INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.create_sample_campaigns_after_signup();

-- Update the MIGRATION_FIXES.md document to include the correct sequence for running migrations
DO $$
BEGIN
  RAISE NOTICE 'Migration Complete: Sample Data Architecture has been split into logical components.';
  RAISE NOTICE 'Run migrations in the following order:';
  RAISE NOTICE '1. 20250330073500_fix_creative_templates_table.sql';
  RAISE NOTICE '2. 20250330075000_sample_data_tables_and_functions.sql';
  RAISE NOTICE '3. 20250330075100_sample_provider_medication_generation.sql';
  RAISE NOTICE '4. 20250330075200_sample_campaign_metrics_functions.sql';
  RAISE NOTICE '5. 20250330075300_sample_user_data_assignment.sql';
END $$;

COMMIT;
