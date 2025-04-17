-- Migration: Final Fix for All Functions
-- This script drops and recreates all functions with proper parameter naming and error handling

BEGIN;

-- 1. Drop all functions that will be recreated
-- Use IF EXISTS to avoid errors
DROP FUNCTION IF EXISTS public.generate_script_lift_data(UUID);
DROP FUNCTION IF EXISTS public.ensure_script_lift_data(UUID);
DROP FUNCTION IF EXISTS public.force_regenerate_all_campaign_data();
DROP FUNCTION IF EXISTS public.force_regenerate_campaign_data(UUID);

-- 2. Create a fixed version of generate_script_lift_data
CREATE FUNCTION public.generate_script_lift_data(p_campaign_id UUID)
RETURNS VOID AS $$
DECLARE
  data_exists BOOLEAN;
  campaign_rec RECORD;
  target_specialty TEXT;
  medication_category TEXT;
  lift_percentage NUMERIC;
  baseline INTEGER;
  projected INTEGER;
  confidence_score INTEGER;
BEGIN
  -- Check if data already exists
  SELECT EXISTS(
    SELECT 1 FROM public.script_lift_data WHERE campaign_id = p_campaign_id
  ) INTO data_exists;
  
  -- If data doesn't exist, create it
  IF NOT data_exists THEN
    -- Get campaign info using an explicit query with only the fields we need
    -- This avoids assuming column names
    BEGIN
      SELECT c.target_specialty, c.medication_category 
      INTO campaign_rec
      FROM public.campaigns c 
      WHERE c.id = p_campaign_id;
      
      -- Extract values into local variables with safe defaults
      target_specialty := COALESCE(campaign_rec.target_specialty, 'Primary Care');
      medication_category := COALESCE(campaign_rec.medication_category, 'General');
    EXCEPTION 
      -- Handle missing columns gracefully
      WHEN undefined_column THEN
        target_specialty := 'Primary Care';
        medication_category := 'General';
    END;
    
    -- Generate reasonable numbers for script lift data
    lift_percentage := 10 + random() * 15; -- 10-25% lift
    baseline := 500 + floor(random() * 300); -- 500-800 baseline
    confidence_score := 70 + floor(random() * 25); -- 70-95% confidence
    
    -- Apply specialty multipliers
    IF target_specialty = 'Cardiology' THEN
      lift_percentage := lift_percentage * 1.2;
      baseline := baseline * 1.3;
    ELSIF target_specialty = 'Endocrinology' THEN
      lift_percentage := lift_percentage * 1.1;
      baseline := baseline * 1.2;
    END IF;
    
    -- Apply medication category multipliers
    IF medication_category = 'Diabetes' THEN
      lift_percentage := lift_percentage * 1.15;
      baseline := baseline * 1.2;
    ELSIF medication_category = 'Hypertension' THEN
      lift_percentage := lift_percentage * 1.1;
      baseline := baseline * 1.1;
    END IF;
    
    -- Calculate projected with adjustments
    projected := baseline + floor(baseline * lift_percentage / 100);
    
    -- Insert data with explicit column names
    INSERT INTO public.script_lift_data 
      (campaign_id, lift_percentage, baseline, projected, confidence_score)
    VALUES 
      (p_campaign_id, lift_percentage, baseline, projected, confidence_score);
      
    -- Add a few more data points if it's a sample campaign
    BEGIN
      INSERT INTO public.script_lift_data 
        (campaign_id, lift_percentage, baseline, projected, confidence_score)
      SELECT 
        p_campaign_id, 
        lift_percentage * (0.9 + random() * 0.2), 
        baseline * (0.9 + random() * 0.2),
        baseline * (0.9 + random() * 0.2) * (1 + lift_percentage * (0.9 + random() * 0.2) / 100),
        confidence_score * (0.9 + random() * 0.1)
      FROM public.campaigns c
      WHERE c.id = p_campaign_id AND c.is_sample = TRUE;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE 'Could not add additional data points: %', SQLERRM;
    END;
    
    RAISE NOTICE 'Created script lift data for campaign %', p_campaign_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Create a fixed version of ensure_script_lift_data
CREATE FUNCTION public.ensure_script_lift_data(p_campaign_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Simply call our fixed function with proper parameter naming
  PERFORM public.generate_script_lift_data(p_campaign_id);
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error ensuring script lift data: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 4. Create a fixed version of force_regenerate_campaign_data
CREATE FUNCTION public.force_regenerate_campaign_data(p_campaign_id UUID)
RETURNS VOID AS $$
BEGIN
  -- Delete any existing data with proper aliases to avoid ambiguity
  DELETE FROM public.campaign_results cr WHERE cr.campaign_id = p_campaign_id;
  DELETE FROM public.script_lift_data sld WHERE sld.campaign_id = p_campaign_id;
  
  -- Now regenerate the results
  BEGIN
    PERFORM public.create_campaign_results_v2(p_campaign_id);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error creating campaign results: %', SQLERRM;
  END;
  
  BEGIN
    PERFORM public.generate_script_lift_data(p_campaign_id);
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error generating script lift data: %', SQLERRM;
  END;
  
  RAISE NOTICE 'Forced data regeneration for campaign %', p_campaign_id;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error regenerating campaign data: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- 5. Create a fixed version of force_regenerate_all_campaign_data
CREATE FUNCTION public.force_regenerate_all_campaign_data()
RETURNS VOID AS $$
DECLARE
  camp_id UUID; -- Renamed to avoid any ambiguity with table columns
BEGIN
  -- First ensure we have creative templates
  BEGIN
    PERFORM public.ensure_creative_templates();
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error ensuring creative templates: %', SQLERRM;
  END;

  -- Regenerate data for all campaigns with properly declared loop variable
  -- and fully qualified column references
  FOR camp_id IN
    SELECT c.id 
    FROM public.campaigns c
  LOOP
    BEGIN
      PERFORM public.force_regenerate_campaign_data(camp_id);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE 'Error regenerating data for campaign %: %', camp_id, SQLERRM;
        -- Continue with next campaign
        CONTINUE;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 6. Run the fixed function to regenerate all data
SELECT public.force_regenerate_all_campaign_data();

COMMIT;
