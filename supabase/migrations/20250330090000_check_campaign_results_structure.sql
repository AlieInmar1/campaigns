-- Migration: Check Campaign Results Structure
-- This migration just verifies the campaign_results table structure
-- without making any changes

BEGIN;

-- Check if campaign_results table exists
DO $$
DECLARE
  table_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public'
    AND table_name = 'campaign_results'
  ) INTO table_exists;

  IF table_exists THEN
    RAISE NOTICE 'campaign_results table exists';
  ELSE
    RAISE NOTICE 'campaign_results table does not exist - we need to create it';
  END IF;
END $$;

-- Check the structure of campaign_results table if it exists
DO $$
DECLARE
  column_record RECORD;
BEGIN
  -- Check if table exists before looking at columns
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public'
    AND table_name = 'campaign_results'
  ) THEN
    -- List all columns in the table
    FOR column_record IN
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_schema = 'public'
      AND table_name = 'campaign_results'
      ORDER BY ordinal_position
    LOOP
      RAISE NOTICE 'Column: %, Type: %, Nullable: %', 
        column_record.column_name, 
        column_record.data_type,
        column_record.is_nullable;
    END LOOP;
  END IF;
END $$;

-- Create the campaign_results table if it doesn't exist
-- This is commented out for now as we're just checking the structure
/*
CREATE TABLE IF NOT EXISTS public.campaign_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  engagement_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  demographic_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  roi_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  prescription_metrics JSONB NOT NULL DEFAULT '{}'::jsonb,
  report_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
*/

-- Sample transformation function (commented out, just for reference)
/*
CREATE OR REPLACE FUNCTION transform_metrics_to_results()
RETURNS VOID AS $$
BEGIN
  -- This function will transform data from campaign_metrics to campaign_results
  -- For now, we're just documenting the expected structure
  
  -- Expected structure for metrics:
  -- {
  --   "impressions": 1234,
  --   "clicks": 56,
  --   "conversions": 7
  -- }
  
  -- Expected structure for engagement_metrics:
  -- {
  --   "avg_time_on_page": 65,
  --   "bounce_rate": 30,
  --   "return_visits": 80
  -- }
  
  -- Expected structure for prescription_metrics:
  -- {
  --   "new_prescriptions": 90,
  --   "prescription_renewals": 150,
  --   "market_share_change": 3.0,
  --   "total_prescription_change": 18.0
  -- }
END;
$$ LANGUAGE plpgsql;
*/

COMMIT;
