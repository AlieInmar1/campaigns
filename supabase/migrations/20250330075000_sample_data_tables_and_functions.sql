-- Migration: Sample Data Tables and Basic Functions (Part 1)
-- Creates sample data tables and utility functions
-- This is a self-contained migration with proper BEGIN/COMMIT

BEGIN;

-------------------------
-- HELPER FUNCTIONS
-------------------------

-- Function to generate a random integer within a range
CREATE OR REPLACE FUNCTION public.random_int(min_val INT, max_val INT) 
RETURNS INT AS $$
BEGIN
  RETURN floor(random() * (max_val - min_val + 1) + min_val)::INT;
END;
$$ LANGUAGE plpgsql;

-- Function to generate a random numeric value within a range
CREATE OR REPLACE FUNCTION public.random_numeric(min_val NUMERIC, max_val NUMERIC, decimal_places INT DEFAULT 2) 
RETURNS NUMERIC AS $$
BEGIN
  RETURN round((random() * (max_val - min_val) + min_val)::NUMERIC, decimal_places);
END;
$$ LANGUAGE plpgsql;

-- Function to randomly select an item from an array
CREATE OR REPLACE FUNCTION public.random_array_element(arr ANYARRAY)
RETURNS ANYELEMENT AS $$
  SELECT arr[1 + floor(random() * array_length(arr, 1))::INTEGER];
$$ LANGUAGE sql;

-- Function to generate a random date within a range
CREATE OR REPLACE FUNCTION public.random_date(start_date DATE, end_date DATE) 
RETURNS DATE AS $$
BEGIN
  RETURN (start_date + (random() * (end_date - start_date))::INT);
END;
$$ LANGUAGE plpgsql;

-------------------------
-- SAMPLE DATA TABLES
-------------------------

-- 1. Sample Provider Targets
CREATE TABLE IF NOT EXISTS public.sample_provider_targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL,
  campaign_id UUID NOT NULL,
  targeting_reason TEXT,
  specialty VARCHAR(100),
  geographic_area VARCHAR(100),
  practice_size VARCHAR(50),
  prescribing_volume VARCHAR(20),
  prescribing_pattern TEXT, -- e.g. "high competitor usage"
  potential_lift_score NUMERIC(5,2),
  is_targeted BOOLEAN DEFAULT true,
  targeting_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sample_provider_targets_provider_id 
ON public.sample_provider_targets(provider_id);

CREATE INDEX IF NOT EXISTS idx_sample_provider_targets_campaign_id 
ON public.sample_provider_targets(campaign_id);

-- 2. Sample Prescriptions
CREATE TABLE IF NOT EXISTS public.sample_prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL,
  medication_id UUID NOT NULL,
  medication_name VARCHAR(200),
  medication_category VARCHAR(100),
  prescription_date DATE NOT NULL,
  quantity INTEGER NOT NULL,
  days_supply INTEGER NOT NULL,
  is_new_prescription BOOLEAN DEFAULT false,
  is_refill BOOLEAN DEFAULT false,
  patient_age_group VARCHAR(20),
  patient_gender VARCHAR(10),
  is_competitor BOOLEAN DEFAULT false,
  is_target_medication BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sample_prescriptions_provider_id 
ON public.sample_prescriptions(provider_id);

CREATE INDEX IF NOT EXISTS idx_sample_prescriptions_medication_id 
ON public.sample_prescriptions(medication_id);

CREATE INDEX IF NOT EXISTS idx_sample_prescriptions_medication_category 
ON public.sample_prescriptions(medication_category);

-- 3. Sample Campaign Metrics
CREATE TABLE IF NOT EXISTS public.sample_campaign_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL,
  campaign_id UUID NOT NULL,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  time_spent_seconds INTEGER DEFAULT 0,
  resource_downloads INTEGER DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  last_interaction_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
  engagement_score NUMERIC(5,2),
  script_lift_percentage NUMERIC(6,2),
  estimated_impact NUMERIC(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sample_campaign_metrics_provider_id 
ON public.sample_campaign_metrics(provider_id);

CREATE INDEX IF NOT EXISTS idx_sample_campaign_metrics_campaign_id 
ON public.sample_campaign_metrics(campaign_id);

-- Add necessary is_sample columns to existing tables

-- Add is_sample_data column to providers table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'providers' 
      AND column_name = 'is_sample_data'
  ) THEN
    ALTER TABLE public.providers ADD COLUMN is_sample_data BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add is_sample_data column to medications table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'medications' 
      AND column_name = 'is_sample_data'
  ) THEN
    ALTER TABLE public.medications ADD COLUMN is_sample_data BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add is_sample column to campaigns table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'campaigns' 
      AND column_name = 'is_sample'
  ) THEN
    ALTER TABLE public.campaigns ADD COLUMN is_sample BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Call the creative templates fixer function if it exists
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_proc WHERE proname = 'fix_creative_templates') THEN
    PERFORM fix_creative_templates();
  END IF;
END $$;

COMMIT;
