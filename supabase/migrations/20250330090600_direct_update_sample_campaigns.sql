-- Migration: Direct Update Sample Campaign Status and Dates
-- Combines and fixes the functionality from:
-- - 20250330090100_update_sample_campaign_status_dates.sql
-- - 20250330090500_fix_ambiguous_column_reference.sql
-- This properly updates sample campaigns without ambiguous column references

BEGIN;

-- 1. Update the create_sample_campaigns_for_user function to use completed status and past dates
CREATE OR REPLACE FUNCTION public.create_sample_campaigns_for_user(user_id UUID)
RETURNS VOID AS $$
DECLARE
  diabetes_campaign_id UUID;
  cardio_campaign_id UUID;
  respiratory_campaign_id UUID;
  campaign_start_date DATE := CURRENT_DATE - INTERVAL '6 months';  -- Using different variable names to avoid ambiguity
  campaign_end_date DATE := CURRENT_DATE - INTERVAL '1 month';    -- Using different variable names to avoid ambiguity
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
    'completed',
    campaign_start_date,
    campaign_end_date,
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
    'completed',
    campaign_start_date,
    campaign_end_date,
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
    'completed',
    campaign_start_date,
    campaign_end_date,
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

-- 2. Update existing sample campaigns using a WITH clause
-- This approach avoids ambiguous column references
WITH date_values AS (
  SELECT 
    'completed'::VARCHAR AS new_status,
    (CURRENT_DATE - INTERVAL '6 months')::DATE AS new_start_date,
    (CURRENT_DATE - INTERVAL '1 month')::DATE AS new_end_date
)
UPDATE public.campaigns c
SET
  status = d.new_status,
  start_date = d.new_start_date,
  end_date = d.new_end_date
FROM date_values d
WHERE
  c.is_sample = TRUE;

-- Report the number of updated campaigns
DO $$
DECLARE
  updated_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO updated_count
  FROM public.campaigns
  WHERE 
    is_sample = TRUE AND
    status = 'completed';
    
  RAISE NOTICE 'Updated % sample campaigns to completed status', updated_count;
END $$;

COMMIT;
