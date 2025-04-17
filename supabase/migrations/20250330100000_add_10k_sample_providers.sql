-- Migration: Add 10,000 Sample Providers
-- This migration adds 10,000 additional providers with varying geography and specialties
-- to provide a more comprehensive dataset for testing and demos

BEGIN;

-- Helper function to generate a random provider name
CREATE OR REPLACE FUNCTION generate_provider_name()
RETURNS TEXT AS $$
DECLARE
  first_names TEXT[] := ARRAY[
    'James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Charles',
    'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan', 'Jessica', 'Sarah', 'Karen',
    'Daniel', 'Matthew', 'Anthony', 'Mark', 'Donald', 'Steven', 'Paul', 'Andrew', 'Joshua', 'Kenneth',
    'Lisa', 'Nancy', 'Margaret', 'Sandra', 'Ashley', 'Kimberly', 'Emily', 'Donna', 'Michelle', 'Carol',
    'Christopher', 'George', 'Ronald', 'Edward', 'Brian', 'Kevin', 'Jason', 'Timothy', 'Jeffrey', 'Ryan',
    'Amanda', 'Melissa', 'Deborah', 'Stephanie', 'Rebecca', 'Laura', 'Sharon', 'Cynthia', 'Kathleen', 'Amy',
    'Gregory', 'Joshua', 'Frank', 'Raymond', 'Patrick', 'Dennis', 'Jerry', 'Tyler', 'Aaron', 'Jose',
    'Rachel', 'Heather', 'Nicole', 'Zachary', 'Samuel', 'Benjamin', 'Victoria', 'Hannah', 'Alexander', 'Jacob',
    'Sofia', 'Emma', 'Olivia', 'Ava', 'Isabella', 'Sophia', 'Charlotte', 'Mia', 'Amelia', 'Harper',
    'Evelyn', 'Abigail', 'Emily', 'Elizabeth', 'Mila', 'Ella', 'Avery', 'Scarlett', 'Aria', 'Penelope'
  ];
  last_names TEXT[] := ARRAY[
    'Smith', 'Johnson', 'Williams', 'Jones', 'Brown', 'Davis', 'Miller', 'Wilson', 'Moore', 'Taylor',
    'Anderson', 'Thomas', 'Jackson', 'White', 'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson',
    'Clark', 'Rodriguez', 'Lewis', 'Lee', 'Walker', 'Hall', 'Allen', 'Young', 'Hernandez', 'King',
    'Wright', 'Lopez', 'Hill', 'Scott', 'Green', 'Adams', 'Baker', 'Gonzalez', 'Nelson', 'Carter',
    'Mitchell', 'Perez', 'Roberts', 'Turner', 'Phillips', 'Campbell', 'Parker', 'Evans', 'Edwards', 'Collins',
    'Stewart', 'Sanchez', 'Morris', 'Rogers', 'Reed', 'Cook', 'Morgan', 'Bell', 'Murphy', 'Bailey',
    'Rivera', 'Cooper', 'Richardson', 'Cox', 'Howard', 'Ward', 'Torres', 'Peterson', 'Gray', 'Ramirez',
    'James', 'Watson', 'Brooks', 'Kelly', 'Sanders', 'Price', 'Bennett', 'Wood', 'Barnes', 'Ross',
    'Henderson', 'Coleman', 'Jenkins', 'Perry', 'Powell', 'Long', 'Patterson', 'Hughes', 'Flores', 'Washington',
    'Butler', 'Simmons', 'Foster', 'Gonzales', 'Bryant', 'Alexander', 'Russell', 'Griffin', 'Diaz', 'Hayes'
  ];
  suffixes TEXT[] := ARRAY['MD', 'DO', 'NP', 'PA', 'MD, PhD', 'MBBS', 'MD, FACP', 'MD, FACS', 'DO, MPH', 'MD, MPH'];
  first_name TEXT;
  last_name TEXT;
  suffix TEXT;
BEGIN
  first_name := first_names[floor(random() * array_length(first_names, 1)) + 1];
  last_name := last_names[floor(random() * array_length(last_names, 1)) + 1];
  suffix := suffixes[floor(random() * array_length(suffixes, 1)) + 1];
  
  RETURN 'Dr. ' || first_name || ' ' || last_name || ', ' || suffix;
END;
$$ LANGUAGE plpgsql;

-- Helper function to generate a random NPI (National Provider Identifier)
CREATE OR REPLACE FUNCTION generate_npi()
RETURNS TEXT AS $$
BEGIN
  RETURN '1' || lpad(floor(random() * 999999999)::text, 9, '0');
END;
$$ LANGUAGE plpgsql;

-- Check if we already have a large number of providers
DO $$
DECLARE
  provider_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO provider_count FROM providers;
  
  -- Only continue if we have fewer than 10,000 providers
  IF provider_count >= 10000 THEN
    RAISE NOTICE 'Already have % providers, skipping additional generation', provider_count;
    RETURN;
  ELSE
    RAISE NOTICE 'Current provider count: %. Adding more providers...', provider_count;
  END IF;
END $$;

-- Create expanded arrays of specialties and regions
DO $$
DECLARE
  -- Expanded list of specialties
  specialties TEXT[] := ARRAY[
    'Primary Care', 'Family Medicine', 'Internal Medicine', 
    'Cardiology', 'Interventional Cardiology', 'Electrophysiology',
    'Neurology', 'Neurosurgery', 'Movement Disorders',
    'Oncology', 'Hematology-Oncology', 'Radiation Oncology', 'Surgical Oncology',
    'Endocrinology', 'Diabetes Specialist', 'Thyroid Specialist',
    'Gastroenterology', 'Hepatology', 'Colorectal Surgery',
    'Pulmonology', 'Critical Care', 'Sleep Medicine',
    'Rheumatology', 'Immunology', 'Allergy',
    'Psychiatry', 'Child Psychiatry', 'Addiction Medicine',
    'Pediatrics', 'Neonatology', 'Pediatric Cardiology', 'Pediatric Neurology',
    'Obstetrics/Gynecology', 'Maternal-Fetal Medicine', 'Reproductive Endocrinology',
    'Dermatology', 'Mohs Surgery', 'Pediatric Dermatology',
    'Orthopedics', 'Sports Medicine', 'Joint Replacement', 'Spine Surgery',
    'Urology', 'Urologic Oncology', 'Female Urology',
    'Nephrology', 'Transplant Nephrology', 'Dialysis',
    'Ophthalmology', 'Retina Specialist', 'Glaucoma Specialist',
    'Otolaryngology', 'Head and Neck Surgery', 'Laryngology',
    'Plastic Surgery', 'Reconstructive Surgery', 'Cosmetic Surgery',
    'Vascular Surgery', 'Endovascular Surgery', 'Vein Specialist',
    'Emergency Medicine', 'Trauma Surgery', 'Acute Care',
    'Geriatric Medicine', 'Palliative Care', 'Hospice'
  ];
  
  -- Expanded list of regions with more granularity
  regions TEXT[] := ARRAY[
    -- Northeast
    'Northeast - New York', 'Northeast - Massachusetts', 'Northeast - Connecticut', 
    'Northeast - Pennsylvania', 'Northeast - New Jersey', 'Northeast - Rhode Island',
    'Northeast - Vermont', 'Northeast - New Hampshire', 'Northeast - Maine',
    
    -- Southeast
    'Southeast - Florida', 'Southeast - Georgia', 'Southeast - North Carolina',
    'Southeast - South Carolina', 'Southeast - Virginia', 'Southeast - Tennessee',
    'Southeast - Alabama', 'Southeast - Mississippi', 'Southeast - Louisiana',
    
    -- Midwest
    'Midwest - Illinois', 'Midwest - Ohio', 'Midwest - Michigan',
    'Midwest - Indiana', 'Midwest - Wisconsin', 'Midwest - Minnesota',
    'Midwest - Iowa', 'Midwest - Missouri', 'Midwest - Kansas',
    
    -- Southwest
    'Southwest - Texas', 'Southwest - Arizona', 'Southwest - New Mexico',
    'Southwest - Oklahoma', 'Southwest - Nevada', 'Southwest - Utah',
    
    -- West
    'West - California', 'West - Washington', 'West - Oregon',
    'West - Colorado', 'West - Hawaii', 'West - Alaska',
    
    -- Other
    'Nationwide', 'Multiple Regions', 'Rural Areas', 'Urban Centers'
  ];
  
  volumes TEXT[] := ARRAY['high', 'medium', 'low'];
  practice_sizes TEXT[] := ARRAY['solo', 'small', 'medium', 'large', 'hospital', 'academic', 'group'];
  
  -- Variables for provider generation
  specialty TEXT;
  region TEXT;
  volume TEXT;
  practice_size TEXT;
  v_provider_id TEXT;
  npi TEXT;
  current_count INTEGER;
  target_count INTEGER := 10000;
  specialty_weight NUMERIC;
  region_weight NUMERIC;
  i INTEGER;
BEGIN
  -- Get current count
  SELECT COUNT(*) INTO current_count FROM providers;
  
  -- Calculate how many more providers we need to add
  target_count := GREATEST(10000 - current_count, 0);
  
  RAISE NOTICE 'Adding % more providers to reach target of 10,000', target_count;
  
  -- Generate providers
  FOR i IN 1..target_count
  LOOP
    -- Select specialty with weighted distribution
    IF random() < 0.4 THEN
      -- 40% chance of primary care related specialty
      specialty := (ARRAY['Primary Care', 'Family Medicine', 'Internal Medicine'])[floor(random() * 3) + 1];
    ELSIF random() < 0.3 THEN
      -- 30% chance of common specialty
      specialty := (ARRAY['Cardiology', 'Neurology', 'Oncology', 'Gastroenterology', 'Pulmonology', 'Orthopedics'])[floor(random() * 6) + 1];
    ELSE
      -- 30% chance of any other specialty
      specialty := specialties[floor(random() * array_length(specialties, 1)) + 1];
    END IF;
    
    -- Select region with weighted distribution
    IF random() < 0.6 THEN
      -- 60% chance of populous regions
      region := (ARRAY[
        'Northeast - New York', 'Northeast - Massachusetts', 'Northeast - Pennsylvania',
        'Southeast - Florida', 'Southeast - Georgia', 'Southeast - North Carolina',
        'Midwest - Illinois', 'Midwest - Ohio', 'Midwest - Michigan',
        'Southwest - Texas', 'Southwest - Arizona',
        'West - California', 'West - Washington'
      ])[floor(random() * 13) + 1];
    ELSE
      -- 40% chance of any other region
      region := regions[floor(random() * array_length(regions, 1)) + 1];
    END IF;
    
    -- Determine prescribing volume with specialty-specific patterns
    IF specialty IN ('Cardiology', 'Oncology', 'Neurology', 'Interventional Cardiology', 'Hematology-Oncology') AND random() < 0.7 THEN
      -- Higher likelihood of high volume for these specialties
      volume := 'high';
    ELSIF specialty IN ('Primary Care', 'Family Medicine', 'Internal Medicine') THEN
      -- Primary care has a more even distribution
      IF random() < 0.4 THEN
        volume := 'high';
      ELSIF random() < 0.8 THEN
        volume := 'medium';
      ELSE
        volume := 'low';
      END IF;
    ELSE
      -- Random volume with bias toward medium
      IF random() < 0.3 THEN
        volume := 'high';
      ELSIF random() < 0.8 THEN
        volume := 'medium';
      ELSE
        volume := 'low';
      END IF;
    END IF;
    
    -- Generate practice size with specialty-specific patterns
    IF specialty IN ('Primary Care', 'Family Medicine', 'Internal Medicine') AND random() < 0.6 THEN
      -- Primary care more likely to be in groups or large practices
      practice_size := (ARRAY['group', 'large', 'medium'])[floor(random() * 3) + 1];
    ELSIF specialty IN ('Cardiology', 'Oncology', 'Neurology', 'Orthopedics') AND random() < 0.5 THEN
      -- These specialties often in hospitals or academic settings
      practice_size := (ARRAY['hospital', 'academic', 'large'])[floor(random() * 3) + 1];
    ELSE
      -- Random practice size
      practice_size := practice_sizes[floor(random() * array_length(practice_sizes, 1)) + 1];
    END IF;
    
    -- Create provider ID with specialty prefix for easier identification
    v_provider_id := lower(regexp_replace(specialty, '[^a-zA-Z0-9]', '', 'g')) || '-' || 
                     lower(substring(region from 1 for 3)) || '-' ||
                     lower(volume) || '-' || 
                     floor(random() * 100000)::text;
    
    -- Generate NPI
    npi := generate_npi();
    
    -- Insert provider
    INSERT INTO providers (
      provider_id, 
      name, 
      specialty, 
      geographic_area,
      prescribing_volume, 
      practice_size,
      npi
    ) VALUES (
      v_provider_id,
      generate_provider_name(),
      specialty,
      region,
      volume,
      practice_size,
      npi
    )
    ON CONFLICT (provider_id) DO NOTHING; -- Skip if provider_id already exists
    
    -- Report progress every 1000 records
    IF i % 1000 = 0 THEN
      RAISE NOTICE 'Generated % providers so far', i;
    END IF;
  END LOOP;
  
  -- Show summary of providers generated
  RAISE NOTICE 'Provider generation complete. Total providers: %', (SELECT COUNT(*) FROM providers);
END $$;

-- Show summary of providers by specialty
SELECT 
  specialty, 
  COUNT(*) as provider_count, 
  COUNT(*) FILTER (WHERE prescribing_volume = 'high') as high_volume,
  COUNT(*) FILTER (WHERE prescribing_volume = 'medium') as medium_volume,
  COUNT(*) FILTER (WHERE prescribing_volume = 'low') as low_volume
FROM providers
GROUP BY specialty
ORDER BY provider_count DESC;

-- Show summary of providers by region
SELECT 
  geographic_area, 
  COUNT(*) as provider_count
FROM providers
GROUP BY geographic_area
ORDER BY provider_count DESC;

-- Drop the helper functions to clean up
DROP FUNCTION IF EXISTS generate_provider_name();
DROP FUNCTION IF EXISTS generate_npi();

COMMIT;
