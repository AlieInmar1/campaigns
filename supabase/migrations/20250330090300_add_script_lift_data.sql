-- Migration: Add Script Lift Data for Sample Campaigns
-- Ensures script lift data is properly generated and linked to sample campaigns
-- This will make the script lift comparison component work correctly

BEGIN;

-- Create script_lift_data table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.script_lift_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE, 
  medication_id UUID NOT NULL,
  baseline NUMERIC(10,2), 
  projected NUMERIC(10,2),
  lift_percentage NUMERIC(6,2),
  confidence_score NUMERIC(5,2),
  time_period VARCHAR(50),
  comparison_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create index on campaign_id
CREATE INDEX IF NOT EXISTS idx_script_lift_data_campaign_id 
ON public.script_lift_data(campaign_id);

-- Create index on medication_id
CREATE INDEX IF NOT EXISTS idx_script_lift_data_medication_id 
ON public.script_lift_data(medication_id);

-- Function to generate script lift data for a campaign
CREATE OR REPLACE FUNCTION public.generate_script_lift_data(campaign_id UUID)
RETURNS VOID AS $$
DECLARE
  medication_rec RECORD;
  script_lift_rec RECORD;
  baseline NUMERIC(10,2);
  projected NUMERIC(10,2);
  lift_percentage NUMERIC(6,2);
  confidence_score NUMERIC(5,2);
  time_periods VARCHAR[] := ARRAY['3 months', '6 months', '12 months'];
  time_period VARCHAR;
  comparison_data JSONB;
  
  -- Campaign information
  campaign_rec RECORD;
  target_specialty VARCHAR;
  region VARCHAR;
  medication_category VARCHAR;
BEGIN
  -- Get campaign information
  SELECT * INTO campaign_rec 
  FROM public.campaigns 
  WHERE id = campaign_id;
  
  -- Skip if campaign doesn't exist
  IF NOT FOUND THEN
    RAISE NOTICE 'Campaign with ID % not found', campaign_id;
    RETURN;
  END IF;
  
  target_specialty := campaign_rec.target_specialty;
  region := campaign_rec.region;
  medication_category := campaign_rec.medication_category;
  
  -- Get average script lift percentage from campaign_metrics
  SELECT AVG(script_lift_percentage) INTO lift_percentage
  FROM public.campaign_metrics
  WHERE campaign_id = generate_script_lift_data.campaign_id;
  
  -- Use default if no metrics found
  IF lift_percentage IS NULL THEN
    lift_percentage := 18.3;
  END IF;
  
  -- Get medications with a preference for those matching the campaign's category
  FOR medication_rec IN
    SELECT m.id, m.name, m.category, m.is_target_medication
    FROM public.medications m
    WHERE m.is_sample_data = TRUE
    AND (m.category = medication_category OR medication_category IS NULL)
    ORDER BY 
      CASE WHEN m.category = medication_category THEN 0 ELSE 1 END,
      m.is_target_medication DESC,
      RANDOM()
    LIMIT 3
  LOOP
    -- Calculate baseline (average monthly prescriptions)
    baseline := 500 + (RANDOM() * 2500);
    
    -- Apply medication-specific adjustment
    IF medication_rec.is_target_medication THEN
      -- Target medications get higher lift
      lift_percentage := GREATEST(lift_percentage, 15.0) + (RANDOM() * 10.0);
    ELSE
      -- Non-target medications get lower lift
      lift_percentage := GREATEST(5.0, lift_percentage * 0.4) + (RANDOM() * 5.0);
    END IF;
    
    -- Calculate projected based on lift percentage
    projected := baseline * (1 + lift_percentage / 100);
    
    -- Calculate confidence score (75-95%)
    confidence_score := 75 + (RANDOM() * 20);
    
    -- Select time period
    time_period := time_periods[1 + FLOOR(RANDOM() * 3)::INTEGER];
    
    -- Generate comparison data (month-by-month values)
    comparison_data := jsonb_build_object(
      'months', jsonb_build_array('Month 1', 'Month 2', 'Month 3', 'Month 4', 'Month 5', 'Month 6'),
      'baseline', jsonb_build_array(
        ROUND((baseline * (0.9 + RANDOM() * 0.2))::numeric, 2),
        ROUND((baseline * (0.9 + RANDOM() * 0.2))::numeric, 2),
        ROUND((baseline * (0.9 + RANDOM() * 0.2))::numeric, 2),
        ROUND((baseline * (0.9 + RANDOM() * 0.2))::numeric, 2),
        ROUND((baseline * (0.9 + RANDOM() * 0.2))::numeric, 2),
        ROUND((baseline * (0.9 + RANDOM() * 0.2))::numeric, 2)
      ),
      'projected', jsonb_build_array(
        ROUND((baseline * (1 + lift_percentage * 0.6 / 100))::numeric, 2),
        ROUND((baseline * (1 + lift_percentage * 0.7 / 100))::numeric, 2),
        ROUND((baseline * (1 + lift_percentage * 0.8 / 100))::numeric, 2),
        ROUND((baseline * (1 + lift_percentage * 0.9 / 100))::numeric, 2),
        ROUND((baseline * (1 + lift_percentage * 0.95 / 100))::numeric, 2),
        ROUND((baseline * (1 + lift_percentage / 100))::numeric, 2)
      )
    );
    
    -- Check if script lift data already exists for this campaign and medication
    SELECT * INTO script_lift_rec 
    FROM public.script_lift_data
    WHERE campaign_id = generate_script_lift_data.campaign_id
    AND medication_id = medication_rec.id;
    
    IF FOUND THEN
      -- Update existing record
      UPDATE public.script_lift_data
      SET
        baseline = generate_script_lift_data.baseline,
        projected = generate_script_lift_data.projected,
        lift_percentage = generate_script_lift_data.lift_percentage,
        confidence_score = generate_script_lift_data.confidence_score,
        time_period = generate_script_lift_data.time_period,
        comparison_data = generate_script_lift_data.comparison_data
      WHERE id = script_lift_rec.id;
      
      RAISE NOTICE 'Updated script lift data for campaign % and medication %', 
        campaign_id, medication_rec.name;
    ELSE
      -- Insert new record
      INSERT INTO public.script_lift_data (
        campaign_id,
        medication_id,
        baseline,
        projected,
        lift_percentage,
        confidence_score,
        time_period,
        comparison_data
      ) VALUES (
        campaign_id,
        medication_rec.id,
        baseline,
        projected,
        lift_percentage,
        confidence_score,
        time_period,
        comparison_data
      );
      
      RAISE NOTICE 'Created script lift data for campaign % and medication %', 
        campaign_id, medication_rec.name;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Generate script lift data for all sample campaigns
DO $$
DECLARE
  campaign_rec RECORD;
  campaign_count INTEGER := 0;
BEGIN
  FOR campaign_rec IN 
    SELECT id FROM public.campaigns WHERE is_sample = TRUE
  LOOP
    PERFORM public.generate_script_lift_data(campaign_rec.id);
    campaign_count := campaign_count + 1;
  END LOOP;
  
  RAISE NOTICE 'Generated script lift data for % sample campaigns', campaign_count;
END $$;

-- Modify the copy_sample_data_for_user function to also generate script lift data
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
    
    -- Generate campaign_results from the metrics
    PERFORM public.transform_metrics_to_results(original_campaign_ids[i]);
    
    -- Generate script lift data
    PERFORM public.generate_script_lift_data(original_campaign_ids[i]);
  END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMIT;
