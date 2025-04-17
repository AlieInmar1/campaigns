-- Migration: Sample Campaign Metrics Functions (Part 3)
-- Creates functions for generating campaign targets, prescription data, and metrics
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
-- CAMPAIGN DATA GENERATION
-------------------------

-- Generate sample campaign targets
CREATE OR REPLACE FUNCTION public.generate_sample_campaign_targets(
  campaign_1_id UUID, 
  campaign_2_id UUID, 
  campaign_3_id UUID
)
RETURNS VOID AS $$
DECLARE
  provider_rec RECORD;
  campaign_id UUID;
  targeting_reason TEXT;
  prescribing_pattern TEXT;
  potential_lift NUMERIC(5,2);
BEGIN
  -- Clear existing targeted providers
  DELETE FROM public.sample_provider_targets;
  
  -- Get all providers
  FOR provider_rec IN 
    SELECT p.id, p.specialty, p.region, p.state, p.practice_size, p.prescribing_volume
    FROM public.providers p
    WHERE p.is_sample_data = TRUE
  LOOP
    -- Diabetes Campaign (campaign_1_id) - Target endocrinologists and PCPs with high volumes
    IF (provider_rec.specialty IN ('Endocrinology', 'Primary Care', 'Internal Medicine') AND 
        random() < 0.7) OR random() < 0.15 THEN
      
      -- Set campaign-specific targeting info
      targeting_reason := CASE 
        WHEN provider_rec.specialty = 'Endocrinology' THEN 'High-value specialty'
        WHEN provider_rec.prescribing_volume IN ('High', 'Very High') THEN 'High prescribing volume'
        ELSE 'Demographic match'
      END;
      
      prescribing_pattern := random_array_element(ARRAY[
        'High competitor usage', 
        'Low penetration of our products',
        'Potential for conversion',
        'Early adopter profile'
      ]);
      
      potential_lift := random_numeric(2.5, 12.5);
      
      INSERT INTO public.sample_provider_targets (
        provider_id, campaign_id, targeting_reason, specialty,
        geographic_area, practice_size, prescribing_volume,
        prescribing_pattern, potential_lift_score, targeting_notes
      ) VALUES (
        provider_rec.id,
        campaign_1_id,
        targeting_reason,
        provider_rec.specialty,
        provider_rec.region || ' - ' || provider_rec.state,
        provider_rec.practice_size,
        provider_rec.prescribing_volume,
        prescribing_pattern,
        potential_lift,
        'Part of Diabetes Care Outreach campaign'
      );
    END IF;
    
    -- Cardiovascular Campaign (campaign_2_id) - Target cardiologists and related specialties
    IF (provider_rec.specialty IN ('Cardiology', 'Internal Medicine', 'Primary Care') AND 
        provider_rec.region IN ('West', 'Northeast') AND
        random() < 0.7) OR random() < 0.15 THEN
      
      targeting_reason := CASE 
        WHEN provider_rec.specialty = 'Cardiology' THEN 'Specialty focus'
        WHEN provider_rec.region = 'West' THEN 'Regional initiative'
        ELSE 'Demographic match'
      END;
      
      prescribing_pattern := random_array_element(ARRAY[
        'Early adopter of new cardiovascular treatments', 
        'High volume of preventative medications',
        'Manages complex cardiovascular patients',
        'Affiliated with cardiac center of excellence'
      ]);
      
      potential_lift := random_numeric(3.0, 15.0);
      
      INSERT INTO public.sample_provider_targets (
        provider_id, campaign_id, targeting_reason, specialty,
        geographic_area, practice_size, prescribing_volume,
        prescribing_pattern, potential_lift_score, targeting_notes
      ) VALUES (
        provider_rec.id,
        campaign_2_id,
        targeting_reason,
        provider_rec.specialty,
        provider_rec.region || ' - ' || provider_rec.state,
        provider_rec.practice_size,
        provider_rec.prescribing_volume,
        prescribing_pattern,
        potential_lift,
        'Part of Cardiovascular Health Initiative'
      );
    END IF;
    
    -- Respiratory Campaign (campaign_3_id) - Target pulmonologists and PCPs in certain regions
    IF (provider_rec.specialty IN ('Pulmonology', 'Primary Care', 'Family Medicine') AND 
        provider_rec.region IN ('Midwest', 'Southeast') AND
        random() < 0.7) OR random() < 0.15 THEN
      
      targeting_reason := CASE 
        WHEN provider_rec.specialty = 'Pulmonology' THEN 'Specialty expertise'
        WHEN provider_rec.region = 'Midwest' THEN 'Region with high COPD/asthma prevalence'
        ELSE 'PCP with respiratory focus'
      END;
      
      prescribing_pattern := random_array_element(ARRAY[
        'Treats high volume of asthma patients', 
        'COPD management focus',
        'Recent switch to competitor products',
        'Community health center affiliation'
      ]);
      
      potential_lift := random_numeric(2.0, 10.0);
      
      INSERT INTO public.sample_provider_targets (
        provider_id, campaign_id, targeting_reason, specialty,
        geographic_area, practice_size, prescribing_volume,
        prescribing_pattern, potential_lift_score, targeting_notes
      ) VALUES (
        provider_rec.id,
        campaign_3_id,
        targeting_reason,
        provider_rec.specialty,
        provider_rec.region || ' - ' || provider_rec.state,
        provider_rec.practice_size,
        provider_rec.prescribing_volume,
        prescribing_pattern,
        potential_lift,
        'Part of Respiratory Care Awareness campaign'
      );
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Generate sample prescription data
CREATE OR REPLACE FUNCTION public.generate_sample_prescription_data()
RETURNS VOID AS $$
DECLARE
  provider_rec RECORD;
  medication_rec RECORD;
  prescription_count INTEGER;
  rx_date DATE;
  quantity INTEGER;
  days_supply INTEGER;
  is_new BOOLEAN;
  is_refill BOOLEAN;
  age_groups TEXT[] := ARRAY['0-17', '18-34', '35-49', '50-64', '65+'];
  genders TEXT[] := ARRAY['Male', 'Female'];
  specialty TEXT;
  medication_category TEXT;
  probability NUMERIC;
BEGIN
  -- Clear existing prescription data
  DELETE FROM public.sample_prescriptions;
  
  -- For each provider
  FOR provider_rec IN 
    SELECT p.id, p.specialty, p.prescribing_volume
    FROM public.providers p
    WHERE p.is_sample_data = TRUE
  LOOP
    specialty := provider_rec.specialty;
    
    -- Number of prescriptions varies by prescribing volume
    CASE provider_rec.prescribing_volume
      WHEN 'Low' THEN prescription_count := random_int(5, 10);
      WHEN 'Medium' THEN prescription_count := random_int(10, 20);
      WHEN 'High' THEN prescription_count := random_int(20, 35);
      WHEN 'Very High' THEN prescription_count := random_int(35, 50);
      ELSE prescription_count := random_int(10, 25);
    END CASE;
    
    -- Generate prescriptions for this provider
    FOR i IN 1..prescription_count LOOP
      -- Select a medication with weighted probability based on provider specialty
      SELECT m.id, m.name, m.category, m.is_target_medication
      INTO medication_rec
      FROM public.medications m
      WHERE m.is_sample_data = TRUE
      AND (
        -- Weight selection based on specialty and medication category
        (specialty = 'Endocrinology' AND m.category = 'Diabetes' AND random() < 0.5) OR
        (specialty = 'Cardiology' AND m.category IN ('Hypertension', 'Cholesterol', 'Anticoagulant') AND random() < 0.5) OR
        (specialty = 'Pulmonology' AND m.category = 'Respiratory' AND random() < 0.5) OR
        (specialty IN ('Primary Care', 'Family Medicine', 'Internal Medicine') AND random() < 0.15) OR
        (true) -- Fallback to ensure we always get a medication
      )
      ORDER BY random()
      LIMIT 1;
      
      -- Generate prescription details
      rx_date := random_date(CURRENT_DATE - INTERVAL '3 months', CURRENT_DATE);
      quantity := random_int(10, 90);
      days_supply := CASE 
        WHEN quantity < 30 THEN quantity
        WHEN quantity < 60 THEN 30
        ELSE 90
      END;
      is_new := random() < 0.3; -- 30% are new prescriptions
      is_refill := NOT is_new;
      
      -- Insert prescription
      INSERT INTO public.sample_prescriptions (
        provider_id, medication_id, medication_name, medication_category, 
        prescription_date, quantity, days_supply, 
        is_new_prescription, is_refill, 
        patient_age_group, patient_gender,
        is_competitor, is_target_medication
      ) VALUES (
        provider_rec.id,
        medication_rec.id,
        medication_rec.name,
        medication_rec.category,
        rx_date,
        quantity,
        days_supply,
        is_new,
        is_refill,
        random_array_element(age_groups),
        random_array_element(genders),
        NOT medication_rec.is_target_medication,
        medication_rec.is_target_medication
      );
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Generate sample campaign metrics
CREATE OR REPLACE FUNCTION public.generate_sample_campaign_metrics()
RETURNS VOID AS $$
DECLARE
  target_rec RECORD;
  impressions INTEGER;
  clicks INTEGER;
  time_spent INTEGER;
  downloads INTEGER;
  conversions INTEGER;
  engagement NUMERIC(5,2);
  script_lift NUMERIC(6,2);
  estimated_impact NUMERIC(10,2);
  last_date TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Clear existing metrics
  DELETE FROM public.sample_campaign_metrics;
  
  -- Generate metrics for each targeted provider
  FOR target_rec IN 
    SELECT pt.provider_id, pt.campaign_id, pt.potential_lift_score, 
           p.prescribing_volume
    FROM public.sample_provider_targets pt
    JOIN public.providers p ON pt.provider_id = p.id
  LOOP
    -- Generate engagement metrics
    -- More impressions for high volume prescribers
    CASE target_rec.prescribing_volume
      WHEN 'Low' THEN impressions := random_int(1, 8);
      WHEN 'Medium' THEN impressions := random_int(3, 15);
      WHEN 'High' THEN impressions := random_int(8, 25);
      WHEN 'Very High' THEN impressions := random_int(15, 40);
      ELSE impressions := random_int(5, 20);
    END CASE;
    
    -- Click rate is about 5-15% of impressions
    clicks := GREATEST(0, random_int(CEIL(impressions * 0.05), CEIL(impressions * 0.15)));
    
    -- Time spent depends on clicks
    IF clicks > 0 THEN
      time_spent := random_int(15, 300) * clicks;
    ELSE
      time_spent := 0;
    END IF;
    
    -- Resource downloads happen after clicks
    downloads := GREATEST(0, random_int(0, CEIL(clicks * 0.3)));
    
    -- Conversions (actual actions taken)
    conversions := GREATEST(0, random_int(0, CEIL(downloads * 0.5)));
    
    -- Calculate engagement score (0-10 scale)
    engagement := LEAST(10, (
      (impressions * 0.1) + 
      (clicks * 0.5) + 
      (time_spent * 0.005) + 
      (downloads * 2.0) + 
      (conversions * 3.0)
    ) / 10);
    
    -- Script lift correlates with engagement and potential
    script_lift := CASE
      WHEN engagement = 0 THEN random_numeric(0, 1)
      WHEN engagement < 3 THEN random_numeric(0, 5)
      WHEN engagement < 6 THEN random_numeric(3, 15)
      WHEN engagement < 8 THEN random_numeric(10, 25)
      ELSE random_numeric(15, 40)
    END;
    
    -- Adjust by potential lift score
    script_lift := script_lift * (target_rec.potential_lift_score / 5.0);
    
    -- Estimated financial impact
    estimated_impact := script_lift * random_numeric(500, 2000);
    
    -- Last interaction date
    last_date := (CURRENT_DATE - (random_int(1, 90) * INTERVAL '1 day'))::TIMESTAMP WITH TIME ZONE;
    
    -- Insert metrics
    INSERT INTO public.sample_campaign_metrics (
      provider_id, campaign_id, impressions, clicks, 
      time_spent_seconds, resource_downloads, conversions,
      last_interaction_date, engagement_score,
      script_lift_percentage, estimated_impact
    ) VALUES (
      target_rec.provider_id,
      target_rec.campaign_id,
      impressions,
      clicks,
      time_spent,
      downloads,
      conversions,
      last_date,
      engagement,
      script_lift,
      estimated_impact
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Master function to generate all sample data
CREATE OR REPLACE FUNCTION public.generate_all_sample_data(
  campaign_1_id UUID,
  campaign_2_id UUID,
  campaign_3_id UUID
)
RETURNS VOID AS $$
BEGIN
  -- Generate sample providers (5000)
  PERFORM public.generate_sample_providers(5000);
  
  -- Generate sample medications
  PERFORM public.generate_sample_medications();
  
  -- Generate campaign targets using the provided campaign IDs
  PERFORM public.generate_sample_campaign_targets(
    campaign_1_id, 
    campaign_2_id, 
    campaign_3_id
  );
  
  -- Generate prescription data
  PERFORM public.generate_sample_prescription_data();
  
  -- Generate campaign metrics
  PERFORM public.generate_sample_campaign_metrics();
END;
$$ LANGUAGE plpgsql;

COMMIT;
