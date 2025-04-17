-- Migration: Sample Provider and Medication Generation (Part 2)
-- Creates functions for generating sample providers and medications
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
-- PROVIDER GENERATION
-------------------------

-- Generate sample providers
CREATE OR REPLACE FUNCTION public.generate_sample_providers(count INTEGER DEFAULT 5000)
RETURNS VOID AS $$
DECLARE
  specialties TEXT[] := ARRAY['Primary Care', 'Family Medicine', 'Internal Medicine', 'Cardiology', 
                             'Endocrinology', 'Pulmonology', 'Neurology', 'Gastroenterology', 
                             'Oncology', 'Rheumatology', 'Nephrology', 'Psychiatry', 'Pediatrics'];
  
  regions TEXT[] := ARRAY['Northeast', 'Southeast', 'Midwest', 'West', 'Southwest'];
  
  states TEXT[] := ARRAY['NY', 'NJ', 'MA', 'CT', 'PA', 'FL', 'GA', 'AL', 'NC', 'SC', 
                         'IL', 'MI', 'OH', 'WI', 'MN', 'CA', 'WA', 'OR', 'AZ', 'NV', 
                         'TX', 'NM', 'CO', 'OK'];
  
  practice_sizes TEXT[] := ARRAY['Solo Practice', 'Small Group (2-5)', 'Medium Group (6-20)', 
                                'Large Group (21-50)', 'Hospital-Affiliated'];
  
  provider_id UUID;
  specialty TEXT;
  region TEXT;
  state TEXT;
  practice_size TEXT;
  npi VARCHAR(10);
  first_name TEXT;
  last_name TEXT;
  i INTEGER;
BEGIN
  -- Clear existing providers if any
  DELETE FROM public.providers WHERE id IN (SELECT id FROM public.providers LIMIT count);
  
  -- Generate new providers
  FOR i IN 1..count LOOP
    provider_id := gen_random_uuid();
    
    -- Assign specialty with weighted distribution
    IF random() < 0.4 THEN -- 40% Primary Care
      specialty := random_array_element(ARRAY['Primary Care', 'Family Medicine', 'Internal Medicine']);
    ELSE
      specialty := random_array_element(specialties);
    END IF;
    
    region := random_array_element(regions);
    state := random_array_element(states);
    practice_size := random_array_element(practice_sizes);
    npi := lpad(i::TEXT, 10, '0'); -- Simplified NPI for sample data
    
    -- Insert provider
    INSERT INTO public.providers (
      id, npi, first_name, last_name, specialty, state, region, 
      practice_size, prescribing_volume, is_sample_data
    ) VALUES (
      provider_id,
      npi,
      'Provider', -- Simplified first name
      'Sample' || i::TEXT, -- Simplified last name with number
      specialty,
      state,
      region,
      practice_size,
      random_array_element(ARRAY['Low', 'Medium', 'High', 'Very High']),
      TRUE -- Mark as sample data
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-------------------------
-- MEDICATION GENERATION
-------------------------

-- Generate sample medications
CREATE OR REPLACE FUNCTION public.generate_sample_medications()
RETURNS VOID AS $$
DECLARE
  categories TEXT[] := ARRAY[
    'Diabetes', 'Hypertension', 'Cholesterol', 'Respiratory', 'Pain', 
    'Psychiatric', 'Antibiotics', 'Gastrointestinal', 'Anticoagulant'
  ];
  
  diabetes_meds TEXT[] := ARRAY[
    'Metformin', 'Glipizide', 'Glyburide', 'Glimepiride', 'Sitagliptin', 
    'Linagliptin', 'Empagliflozin', 'Dapagliflozin', 'Semaglutide', 
    'Dulaglutide', 'Liraglutide', 'Insulin Glargine', 'Insulin Lispro'
  ];
  
  hypertension_meds TEXT[] := ARRAY[
    'Lisinopril', 'Enalapril', 'Ramipril', 'Losartan', 'Valsartan', 
    'Olmesartan', 'Amlodipine', 'Diltiazem', 'Metoprolol', 'Atenolol', 
    'Carvedilol', 'Hydrochlorothiazide', 'Chlorthalidone'
  ];
  
  cholesterol_meds TEXT[] := ARRAY[
    'Atorvastatin', 'Simvastatin', 'Rosuvastatin', 'Pravastatin', 
    'Lovastatin', 'Ezetimibe', 'Fenofibrate', 'Gemfibrozil'
  ];
  
  respiratory_meds TEXT[] := ARRAY[
    'Albuterol', 'Fluticasone', 'Budesonide', 'Montelukast', 'Tiotropium', 
    'Umeclidinium', 'Formoterol', 'Salmeterol', 'Ipratropium'
  ];
  
  pain_meds TEXT[] := ARRAY[
    'Acetaminophen', 'Ibuprofen', 'Naproxen', 'Celecoxib', 'Meloxicam', 
    'Tramadol', 'Gabapentin', 'Pregabalin', 'Duloxetine'
  ];
  
  psychiatric_meds TEXT[] := ARRAY[
    'Sertraline', 'Escitalopram', 'Fluoxetine', 'Bupropion', 'Venlafaxine', 
    'Duloxetine', 'Quetiapine', 'Aripiprazole', 'Risperidone', 'Alprazolam'
  ];
  
  antibiotics_meds TEXT[] := ARRAY[
    'Amoxicillin', 'Azithromycin', 'Ciprofloxacin', 'Doxycycline', 
    'Cephalexin', 'Trimethoprim-Sulfamethoxazole', 'Metronidazole'
  ];
  
  gi_meds TEXT[] := ARRAY[
    'Omeprazole', 'Pantoprazole', 'Esomeprazole', 'Famotidine', 
    'Ondansetron', 'Loperamide', 'Polyethylene Glycol'
  ];
  
  anticoagulant_meds TEXT[] := ARRAY[
    'Warfarin', 'Apixaban', 'Rivaroxaban', 'Dabigatran', 'Enoxaparin', 
    'Clopidogrel', 'Aspirin'
  ];
  
  category TEXT;
  medication TEXT;
  medication_list TEXT[];
  i INTEGER;
BEGIN
  -- Clear existing medications if they're marked as sample
  DELETE FROM public.medications WHERE is_sample_data = TRUE;
  
  -- For each category, generate medications
  FOREACH category IN ARRAY categories LOOP
    CASE category
      WHEN 'Diabetes' THEN medication_list := diabetes_meds;
      WHEN 'Hypertension' THEN medication_list := hypertension_meds;
      WHEN 'Cholesterol' THEN medication_list := cholesterol_meds;
      WHEN 'Respiratory' THEN medication_list := respiratory_meds;
      WHEN 'Pain' THEN medication_list := pain_meds;
      WHEN 'Psychiatric' THEN medication_list := psychiatric_meds;
      WHEN 'Antibiotics' THEN medication_list := antibiotics_meds;
      WHEN 'Gastrointestinal' THEN medication_list := gi_meds;
      WHEN 'Anticoagulant' THEN medication_list := anticoagulant_meds;
      ELSE medication_list := ARRAY['Generic Medication'];
    END CASE;
    
    FOREACH medication IN ARRAY medication_list LOOP
      INSERT INTO public.medications (
        id, name, category, is_brand_name, is_target_medication, is_sample_data
      ) VALUES (
        gen_random_uuid(),
        medication,
        category,
        random() > 0.7, -- 30% are brand name
        random() > 0.7, -- 30% are target medications
        TRUE -- Mark as sample data
      );
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Test function to execute both data generation functions
CREATE OR REPLACE FUNCTION public.generate_providers_and_medications(provider_count INTEGER DEFAULT 5000)
RETURNS VOID AS $$
BEGIN
  PERFORM public.generate_sample_providers(provider_count);
  PERFORM public.generate_sample_medications();
END;
$$ LANGUAGE plpgsql;

COMMIT;
