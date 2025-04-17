-- Add sample campaign results data with prescription impact and ad performance metrics
-- This migration adds detailed sample data for campaign results to demonstrate the UI functionality

-- First, let's make sure we have the campaign_results table
CREATE TABLE IF NOT EXISTS campaign_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  metrics JSONB NOT NULL DEFAULT '{}',
  engagement_metrics JSONB NOT NULL DEFAULT '{}',
  demographic_metrics JSONB NOT NULL DEFAULT '{}',
  roi_metrics JSONB NOT NULL DEFAULT '{}',
  prescription_metrics JSONB NOT NULL DEFAULT '{}',
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Function to get all campaign IDs
CREATE OR REPLACE FUNCTION get_campaign_ids()
RETURNS TABLE(id UUID) AS $$
BEGIN
  RETURN QUERY SELECT campaigns.id FROM campaigns;
END;
$$ LANGUAGE plpgsql;

-- Function to generate sample campaign results
CREATE OR REPLACE FUNCTION generate_sample_campaign_results()
RETURNS VOID AS $$
DECLARE
  campaign_id UUID;
  report_date DATE;
  metrics JSONB;
  engagement_metrics JSONB;
  demographic_metrics JSONB;
  roi_metrics JSONB;
  prescription_metrics JSONB;
BEGIN
  -- Delete existing campaign results to avoid duplicates
  DELETE FROM campaign_results;
  
  -- For each campaign, generate sample results
  FOR campaign_id IN SELECT * FROM get_campaign_ids() LOOP
    -- Generate 3 reports for each campaign with different dates
    FOR i IN 1..3 LOOP
      report_date := CURRENT_DATE - (i * 30);
      
      -- Basic metrics
      metrics := jsonb_build_object(
        'impressions', floor(random() * 1000000) + 100000,
        'clicks', floor(random() * 50000) + 5000,
        'conversions', floor(random() * 2000) + 200,
        'ad_performance', jsonb_build_object(
          'ctr', (random() * 3 + 1)::numeric(10,2),
          'view_through_rate', (random() * 20 + 60)::numeric(10,2),
          'completion_rate', (random() * 15 + 75)::numeric(10,2),
          'ad_recall_lift', (random() * 10 + 5)::numeric(10,2),
          'brand_awareness_lift', (random() * 15 + 10)::numeric(10,2),
          'channel_performance', jsonb_build_object(
            'display', jsonb_build_object(
              'impressions', floor(random() * 500000) + 50000,
              'clicks', floor(random() * 25000) + 2500,
              'ctr', (random() * 2 + 0.5)::numeric(10,2),
              'cost', floor(random() * 20000) + 5000
            ),
            'social', jsonb_build_object(
              'impressions', floor(random() * 300000) + 30000,
              'clicks', floor(random() * 15000) + 1500,
              'ctr', (random() * 3 + 1)::numeric(10,2),
              'cost', floor(random() * 15000) + 3000
            ),
            'search', jsonb_build_object(
              'impressions', floor(random() * 200000) + 20000,
              'clicks', floor(random() * 10000) + 1000,
              'ctr', (random() * 5 + 2)::numeric(10,2),
              'cost', floor(random() * 10000) + 2000
            )
          ),
          'top_performing_creatives', jsonb_build_array(
            jsonb_build_object(
              'name', 'Brand Awareness Video',
              'format', 'Video',
              'impressions', floor(random() * 200000) + 20000,
              'clicks', floor(random() * 10000) + 1000,
              'ctr', (random() * 3 + 2)::numeric(10,2)
            ),
            jsonb_build_object(
              'name', 'Product Benefits Infographic',
              'format', 'Image',
              'impressions', floor(random() * 150000) + 15000,
              'clicks', floor(random() * 7500) + 750,
              'ctr', (random() * 2.5 + 1.5)::numeric(10,2)
            ),
            jsonb_build_object(
              'name', 'Patient Testimonial',
              'format', 'Carousel',
              'impressions', floor(random() * 100000) + 10000,
              'clicks', floor(random() * 5000) + 500,
              'ctr', (random() * 2 + 1)::numeric(10,2)
            )
          )
        )
      );
      
      -- Engagement metrics
      engagement_metrics := jsonb_build_object(
        'avg_time_on_page', floor(random() * 120) + 30,
        'bounce_rate', (random() * 30 + 20)::numeric(10,2),
        'return_visits', floor(random() * 5000) + 500,
        'resource_downloads', floor(random() * 2000) + 200
      );
      
      -- Demographic metrics
      demographic_metrics := jsonb_build_object(
        'age_groups', jsonb_build_object(
          '25-34', (random() * 20 + 10)::numeric(10,2),
          '35-44', (random() * 25 + 20)::numeric(10,2),
          '45-54', (random() * 20 + 15)::numeric(10,2),
          '55-64', (random() * 15 + 10)::numeric(10,2),
          '65+', (random() * 10 + 5)::numeric(10,2)
        ),
        'gender', jsonb_build_object(
          'male', (random() * 20 + 40)::numeric(10,2),
          'female', (random() * 20 + 40)::numeric(10,2)
        ),
        'specialties', jsonb_build_object(
          'cardiology', (random() * 15 + 10)::numeric(10,2),
          'internal_medicine', (random() * 20 + 15)::numeric(10,2),
          'family_medicine', (random() * 25 + 20)::numeric(10,2),
          'endocrinology', (random() * 10 + 5)::numeric(10,2),
          'other', (random() * 10 + 5)::numeric(10,2)
        )
      );
      
      -- ROI metrics
      roi_metrics := jsonb_build_object(
        'total_campaign_cost', floor(random() * 100000) + 50000,
        'cost_per_click', (random() * 5 + 1)::numeric(10,2),
        'cost_per_conversion', (random() * 50 + 20)::numeric(10,2),
        'cost_per_impression', (random() * 0.05 + 0.01)::numeric(10,4),
        'roi_percentage', (random() * 200 + 100)::numeric(10,2),
        'estimated_revenue_impact', floor(random() * 500000) + 100000,
        'lifetime_value_impact', floor(random() * 1000000) + 500000
      );
      
      -- Prescription metrics with prescription impact
      prescription_metrics := jsonb_build_object(
        'new_prescriptions', floor(random() * 5000) + 1000,
        'prescription_renewals', floor(random() * 10000) + 5000,
        'market_share_change', (random() * 5 + 1)::numeric(10,2),
        'patient_adherence_rate', (random() * 15 + 75)::numeric(10,2),
        'total_prescription_change', (random() * 10 + 5)::numeric(10,2),
        'prescription_by_region', jsonb_build_object(
          'northeast', floor(random() * 2000) + 500,
          'midwest', floor(random() * 1500) + 400,
          'south', floor(random() * 2500) + 600,
          'west', floor(random() * 1800) + 450
        ),
        'prescription_by_specialty', jsonb_build_object(
          'cardiology', floor(random() * 1200) + 300,
          'internal_medicine', floor(random() * 1500) + 400,
          'family_medicine', floor(random() * 1800) + 500,
          'endocrinology', floor(random() * 800) + 200
        ),
        'prescription_impact', jsonb_build_object(
          'script_lift_percentage', (random() * 15 + 5)::numeric(10,2),
          'baseline_monthly_scripts', floor(random() * 10000) + 5000,
          'current_monthly_scripts', floor(random() * 15000) + 7000,
          'projected_annual_scripts', floor(random() * 200000) + 100000,
          'provider_impact', jsonb_build_object(
            'total_providers_reached', floor(random() * 5000) + 1000,
            'high_prescribers_reached', floor(random() * 1000) + 200,
            'new_prescribers', floor(random() * 500) + 100,
            'prescriber_retention_rate', (random() * 15 + 75)::numeric(10,2)
          ),
          'medication_performance', jsonb_build_array(
            jsonb_build_object(
              'medication_name', 'Lipitor',
              'baseline_scripts', floor(random() * 5000) + 2000,
              'current_scripts', floor(random() * 7000) + 3000,
              'script_lift', (random() * 20 + 10)::numeric(10,2),
              'market_share', (random() * 15 + 5)::numeric(10,2)
            ),
            jsonb_build_object(
              'medication_name', 'Crestor',
              'baseline_scripts', floor(random() * 4000) + 1500,
              'current_scripts', floor(random() * 5500) + 2000,
              'script_lift', (random() * 15 + 8)::numeric(10,2),
              'market_share', (random() * 12 + 4)::numeric(10,2)
            ),
            jsonb_build_object(
              'medication_name', 'Zocor',
              'baseline_scripts', floor(random() * 3000) + 1000,
              'current_scripts', floor(random() * 4000) + 1500,
              'script_lift', (random() * 12 + 5)::numeric(10,2),
              'market_share', (random() * 10 + 3)::numeric(10,2)
            )
          )
        )
      );
      
      -- Insert the campaign result
      INSERT INTO campaign_results (
        campaign_id,
        metrics,
        engagement_metrics,
        demographic_metrics,
        roi_metrics,
        prescription_metrics,
        report_date
      ) VALUES (
        campaign_id,
        metrics,
        engagement_metrics,
        demographic_metrics,
        roi_metrics,
        prescription_metrics,
        report_date
      );
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Execute the function to generate sample data
SELECT generate_sample_campaign_results();

-- Clean up the temporary functions
DROP FUNCTION IF EXISTS generate_sample_campaign_results();
DROP FUNCTION IF EXISTS get_campaign_ids();
