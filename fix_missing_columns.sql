-- Fix missing columns in medications and providers tables
-- This script adds the missing columns that are causing errors in the application

-- Check if the medications table exists
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'medications'
  ) THEN
    -- Check if the name column exists in medications table
    IF NOT EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'medications' 
      AND column_name = 'name'
    ) THEN
      -- Add name column to medications table
      ALTER TABLE medications ADD COLUMN name TEXT;
      
      -- Update name column with values from medication_name if it exists
      IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'medications' 
        AND column_name = 'medication_name'
      ) THEN
        UPDATE medications SET name = medication_name WHERE medication_name IS NOT NULL;
      END IF;
      
      RAISE NOTICE 'Added name column to medications table';
    ELSE
      RAISE NOTICE 'name column already exists in medications table';
    END IF;
  ELSE
    RAISE NOTICE 'medications table does not exist';
  END IF;
  
  -- Check if the providers table exists
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'providers'
  ) THEN
    -- Check if the geographic_area column exists in providers table
    IF NOT EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'providers' 
      AND column_name = 'geographic_area'
    ) THEN
      -- Add geographic_area column to providers table
      ALTER TABLE providers ADD COLUMN geographic_area TEXT;
      
      -- Update geographic_area column with values from region if it exists
      IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'providers' 
        AND column_name = 'region'
      ) THEN
        UPDATE providers SET geographic_area = region WHERE region IS NOT NULL;
      END IF;
      
      RAISE NOTICE 'Added geographic_area column to providers table';
    ELSE
      RAISE NOTICE 'geographic_area column already exists in providers table';
    END IF;
  ELSE
    RAISE NOTICE 'providers table does not exist';
  END IF;
END $$;

-- Create indexes on the new columns for better performance
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'medications'
  ) AND EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'medications' 
    AND column_name = 'name'
  ) THEN
    -- Create index on medications.name if it doesn't exist
    IF NOT EXISTS (
      SELECT FROM pg_indexes 
      WHERE tablename = 'medications' 
      AND indexname = 'idx_medications_name'
    ) THEN
      CREATE INDEX idx_medications_name ON medications (name);
      RAISE NOTICE 'Created index on medications.name';
    END IF;
  END IF;
  
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'providers'
  ) AND EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'providers' 
    AND column_name = 'geographic_area'
  ) THEN
    -- Create index on providers.geographic_area if it doesn't exist
    IF NOT EXISTS (
      SELECT FROM pg_indexes 
      WHERE tablename = 'providers' 
      AND indexname = 'idx_providers_geographic_area'
    ) THEN
      CREATE INDEX idx_providers_geographic_area ON providers (geographic_area);
      RAISE NOTICE 'Created index on providers.geographic_area';
    END IF;
  END IF;
END $$;

-- Check if script_lift_data table exists and handle it appropriately
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'script_lift_data'
  ) THEN
    -- Create script_lift_data table if it doesn't exist
    CREATE TABLE script_lift_data (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
      medication_id TEXT NOT NULL, -- Include medication_id as required in original schema
      baseline INTEGER NOT NULL,
      projected INTEGER NOT NULL,
      lift_percentage NUMERIC(5,2) NOT NULL,
      confidence_score INTEGER NOT NULL,
      time_period TEXT, -- Optional in our implementation
      comparison_data JSONB, -- Optional in our implementation
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );

    -- Add sample data to script_lift_data with medication_id
    INSERT INTO script_lift_data (campaign_id, medication_id, baseline, projected, lift_percentage, confidence_score, time_period)
    SELECT
      c.id as campaign_id,
      -- Get a random medication_id from medications table, or use a default if none exists
      COALESCE(
        (SELECT id FROM medications ORDER BY RANDOM() LIMIT 1),
        'med-default-' || c.id -- Fallback medication ID if no medications exist
      ) as medication_id,
      FLOOR(RANDOM() * 5000 + 1000)::INTEGER as baseline,
      FLOOR(RANDOM() * 8000 + 5000)::INTEGER as projected,
      (RANDOM() * 20 + 5)::NUMERIC(5,2) as lift_percentage,
      (RANDOM() * 30 + 65)::INTEGER as confidence_score,
      'annual' as time_period -- Default time period
    FROM campaigns c
    LIMIT 10;
    
    RAISE NOTICE 'Created script_lift_data table and added sample data';
  ELSE
    RAISE NOTICE 'script_lift_data table already exists, skipping creation';
  END IF;
END $$;

-- Ensure campaign_results table has the necessary structure
CREATE TABLE IF NOT EXISTS campaign_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
  engagement_metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
  demographic_metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
  roi_metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
  prescription_metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add sample data to campaign_results if the table is empty
INSERT INTO campaign_results (
  campaign_id, 
  metrics, 
  engagement_metrics, 
  demographic_metrics, 
  roi_metrics, 
  prescription_metrics
)
SELECT 
  id as campaign_id,
  jsonb_build_object(
    'impressions', FLOOR(RANDOM() * 100000 + 50000),
    'clicks', FLOOR(RANDOM() * 5000 + 2500),
    'conversions', FLOOR(RANDOM() * 1000 + 500),
    'ad_performance', jsonb_build_object(
      'ctr', (RANDOM() * 5 + 1)::NUMERIC(5,2),
      'view_through_rate', (RANDOM() * 15 + 5)::NUMERIC(5,2),
      'completion_rate', (RANDOM() * 25 + 65)::NUMERIC(5,2),
      'ad_recall_lift', (RANDOM() * 15 + 5)::NUMERIC(5,2),
      'brand_awareness_lift', (RANDOM() * 20 + 10)::NUMERIC(5,2),
      'top_performing_creatives', jsonb_build_array(
        jsonb_build_object(
          'creative_id', 'cr-' || FLOOR(RANDOM() * 1000)::TEXT,
          'name', 'Video Ad - Patient Testimonial',
          'format', 'video',
          'impressions', FLOOR(RANDOM() * 30000 + 10000),
          'clicks', FLOOR(RANDOM() * 1500 + 500),
          'ctr', (RANDOM() * 8 + 2)::NUMERIC(5,2)
        ),
        jsonb_build_object(
          'creative_id', 'cr-' || FLOOR(RANDOM() * 1000)::TEXT,
          'name', 'Banner Ad - Medication Benefits',
          'format', 'banner',
          'impressions', FLOOR(RANDOM() * 40000 + 20000),
          'clicks', FLOOR(RANDOM() * 1200 + 300),
          'ctr', (RANDOM() * 5 + 1)::NUMERIC(5,2)
        ),
        jsonb_build_object(
          'creative_id', 'cr-' || FLOOR(RANDOM() * 1000)::TEXT,
          'name', 'Native Ad - Clinical Results',
          'format', 'native',
          'impressions', FLOOR(RANDOM() * 25000 + 15000),
          'clicks', FLOOR(RANDOM() * 1000 + 400),
          'ctr', (RANDOM() * 6 + 1.5)::NUMERIC(5,2)
        )
      ),
      'channel_performance', jsonb_build_object(
        'social_media', jsonb_build_object(
          'impressions', FLOOR(RANDOM() * 50000 + 20000),
          'clicks', FLOOR(RANDOM() * 2500 + 1000),
          'ctr', (RANDOM() * 6 + 2)::NUMERIC(5,2),
          'cost', FLOOR(RANDOM() * 5000 + 2000)
        ),
        'display', jsonb_build_object(
          'impressions', FLOOR(RANDOM() * 40000 + 15000),
          'clicks', FLOOR(RANDOM() * 1500 + 500),
          'ctr', (RANDOM() * 4 + 1)::NUMERIC(5,2),
          'cost', FLOOR(RANDOM() * 4000 + 1500)
        ),
        'search', jsonb_build_object(
          'impressions', FLOOR(RANDOM() * 20000 + 5000),
          'clicks', FLOOR(RANDOM() * 1000 + 300),
          'ctr', (RANDOM() * 8 + 3)::NUMERIC(5,2),
          'cost', FLOOR(RANDOM() * 3000 + 1000)
        ),
        'email', jsonb_build_object(
          'sent', FLOOR(RANDOM() * 10000 + 5000),
          'opened', FLOOR(RANDOM() * 3000 + 1000),
          'clicked', FLOOR(RANDOM() * 1000 + 300),
          'open_rate', (RANDOM() * 30 + 20)::NUMERIC(5,2),
          'click_rate', (RANDOM() * 15 + 5)::NUMERIC(5,2),
          'cost', FLOOR(RANDOM() * 2000 + 500)
        )
      )
    )
  ) as metrics,
  jsonb_build_object(
    'avg_time_on_page', FLOOR(RANDOM() * 60 + 30),
    'bounce_rate', FLOOR(RANDOM() * 40 + 20),
    'return_visits', FLOOR(RANDOM() * 100 + 50),
    'resource_downloads', FLOOR(RANDOM() * 50 + 20)
  ) as engagement_metrics,
  jsonb_build_object(
    'age_groups', jsonb_build_object(
      '25-34', FLOOR(RANDOM() * 20 + 10),
      '35-44', FLOOR(RANDOM() * 30 + 20),
      '45-54', FLOOR(RANDOM() * 30 + 20),
      '55-64', FLOOR(RANDOM() * 20 + 10),
      '65+', FLOOR(RANDOM() * 10 + 5)
    ),
    'genders', jsonb_build_object(
      'Male', FLOOR(RANDOM() * 60 + 40),
      'Female', FLOOR(RANDOM() * 60 + 40)
    )
  ) as demographic_metrics,
  jsonb_build_object(
    'total_campaign_cost', FLOOR(RANDOM() * 20000 + 10000),
    'roi_percentage', FLOOR(RANDOM() * 100 + 100),
    'estimated_revenue_impact', FLOOR(RANDOM() * 50000 + 20000),
    'cost_per_click', (RANDOM() * 30 + 10)::NUMERIC(10,2),
    'cost_per_conversion', (RANDOM() * 300 + 100)::NUMERIC(10,2),
    'cost_per_impression', (RANDOM() * 2 + 0.5)::NUMERIC(10,2),
    'lifetime_value_impact', FLOOR(RANDOM() * 100000 + 50000)
  ) as roi_metrics,
  jsonb_build_object(
    'new_prescriptions', FLOOR(RANDOM() * 100 + 50),
    'prescription_renewals', FLOOR(RANDOM() * 200 + 100),
    'market_share_change', (RANDOM() * 5 + 1)::NUMERIC(10,2),
    'patient_adherence_rate', FLOOR(RANDOM() * 30 + 50),
    'total_prescription_change', (RANDOM() * 20 + 5)::NUMERIC(10,2),
    'prescription_by_region', jsonb_build_object(
      'Northeast', FLOOR(RANDOM() * 40 + 20),
      'Southeast', FLOOR(RANDOM() * 30 + 15),
      'Midwest', FLOOR(RANDOM() * 25 + 10),
      'Southwest', FLOOR(RANDOM() * 20 + 10),
      'West', FLOOR(RANDOM() * 20 + 10)
    ),
    'prescription_by_specialty', jsonb_build_object(
      'Primary Care', FLOOR(RANDOM() * 50 + 30),
      'Cardiology', FLOOR(RANDOM() * 30 + 10),
      'Neurology', FLOOR(RANDOM() * 20 + 10),
      'Endocrinology', FLOOR(RANDOM() * 25 + 15),
      'Other', FLOOR(RANDOM() * 15 + 5)
    ),
    'prescription_impact', jsonb_build_object(
      'baseline_monthly_scripts', FLOOR(RANDOM() * 1000 + 500),
      'current_monthly_scripts', FLOOR(RANDOM() * 1500 + 800),
      'script_lift_percentage', (RANDOM() * 30 + 10)::NUMERIC(5,2),
      'projected_annual_scripts', FLOOR(RANDOM() * 20000 + 10000),
      'confidence_interval', jsonb_build_object(
        'lower', (RANDOM() * 10 + 5)::NUMERIC(5,2),
        'upper', (RANDOM() * 20 + 15)::NUMERIC(5,2)
      ),
      'medication_performance', jsonb_build_array(
        jsonb_build_object(
          'medication_id', 'med-' || FLOOR(RANDOM() * 1000)::TEXT,
          'medication_name', 'Cardiofix',
          'baseline_scripts', FLOOR(RANDOM() * 500 + 200),
          'current_scripts', FLOOR(RANDOM() * 700 + 300),
          'script_lift', (RANDOM() * 40 + 20)::NUMERIC(5,2),
          'market_share', (RANDOM() * 15 + 5)::NUMERIC(5,2)
        ),
        jsonb_build_object(
          'medication_id', 'med-' || FLOOR(RANDOM() * 1000)::TEXT,
          'medication_name', 'Neurobalance',
          'baseline_scripts', FLOOR(RANDOM() * 300 + 100),
          'current_scripts', FLOOR(RANDOM() * 450 + 150),
          'script_lift', (RANDOM() * 35 + 15)::NUMERIC(5,2),
          'market_share', (RANDOM() * 10 + 3)::NUMERIC(5,2)
        ),
        jsonb_build_object(
          'medication_id', 'med-' || FLOOR(RANDOM() * 1000)::TEXT,
          'medication_name', 'Glucoregulate',
          'baseline_scripts', FLOOR(RANDOM() * 400 + 150),
          'current_scripts', FLOOR(RANDOM() * 550 + 200),
          'script_lift', (RANDOM() * 30 + 10)::NUMERIC(5,2),
          'market_share', (RANDOM() * 12 + 4)::NUMERIC(5,2)
        )
      ),
      'provider_impact', jsonb_build_object(
        'total_providers_reached', FLOOR(RANDOM() * 500 + 200),
        'high_prescribers_reached', FLOOR(RANDOM() * 100 + 50),
        'new_prescribers', FLOOR(RANDOM() * 50 + 20),
        'prescriber_retention_rate', (RANDOM() * 20 + 70)::NUMERIC(5,2),
        'avg_scripts_per_provider', (RANDOM() * 10 + 5)::NUMERIC(5,2)
      ),
      'patient_impact', jsonb_build_object(
        'new_patients', FLOOR(RANDOM() * 200 + 100),
        'continuing_patients', FLOOR(RANDOM() * 500 + 300),
        'adherence_improvement', (RANDOM() * 15 + 5)::NUMERIC(5,2),
        'avg_treatment_duration', (RANDOM() * 6 + 6)::NUMERIC(5,2),
        'patient_satisfaction', (RANDOM() * 20 + 70)::NUMERIC(5,2)
      )
    )
  ) as prescription_metrics
FROM campaigns
WHERE NOT EXISTS (SELECT 1 FROM campaign_results LIMIT 1)
LIMIT 10;
