-- SQL script to create patient_prescriptions table and import data in Supabase
-- For use with ID-only prescription data

-- 1. First create the patient_prescriptions table with ID-only fields
CREATE TABLE IF NOT EXISTS public.patient_prescriptions (
    id UUID PRIMARY KEY,
    provider_id UUID NOT NULL,
    patient_id UUID NOT NULL,
    medication_id UUID NOT NULL,
    prescription_date DATE NOT NULL,
    fill_date DATE,
    quantity INTEGER NOT NULL,
    days_supply INTEGER NOT NULL,
    refills INTEGER NOT NULL,
    refill_number INTEGER NOT NULL,
    is_new BOOLEAN NOT NULL,
    batch_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT fk_provider FOREIGN KEY (provider_id)
        REFERENCES public.providers (id) ON DELETE CASCADE,
    CONSTRAINT fk_patient FOREIGN KEY (patient_id)
        REFERENCES public.patients (id) ON DELETE CASCADE,
    CONSTRAINT fk_medication FOREIGN KEY (medication_id)
        REFERENCES public.medications (id) ON DELETE CASCADE
);

-- 2. Add indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_provider_id 
    ON public.patient_prescriptions (provider_id);
    
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_patient_id 
    ON public.patient_prescriptions (patient_id);
    
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_medication_id 
    ON public.patient_prescriptions (medication_id);
    
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_prescription_date 
    ON public.patient_prescriptions (prescription_date);

-- 3. Add comment to the table
COMMENT ON TABLE public.patient_prescriptions IS 
    'Stores patient prescription data with ID-only references (no name fields)';

-- 4. Set up Row Level Security (RLS)
ALTER TABLE public.patient_prescriptions ENABLE ROW LEVEL SECURITY;

-- Create a policy that allows authenticated users to view prescriptions
CREATE POLICY "Allow authenticated users to view prescriptions" 
    ON public.patient_prescriptions
    FOR SELECT 
    TO authenticated
    USING (true);

-- Create a policy that restricts insert/update/delete to service role only
CREATE POLICY "Restrict modifications to service role" 
    ON public.patient_prescriptions
    FOR ALL 
    TO service_role
    USING (true);

-- 5. Create functions for importing from cloud storage

-- Import prescriptions from a CSV file in Supabase Storage
-- This requires the file to be uploaded to Supabase Storage first
CREATE OR REPLACE FUNCTION import_prescriptions_from_storage(
    bucket_name TEXT,
    file_name TEXT
) RETURNS INTEGER AS $$
DECLARE
    imported_count INTEGER := 0;
    storage_object RECORD;
    file_content TEXT;
BEGIN
    -- Get the file content from storage
    SELECT * INTO storage_object 
    FROM storage.objects
    WHERE bucket_id = bucket_name AND name = file_name;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'File not found in storage: %/%', bucket_name, file_name;
    END IF;
    
    -- Create a temporary table to load the CSV data
    CREATE TEMP TABLE temp_prescriptions (
        id UUID,
        provider_id UUID,
        patient_id UUID,
        medication_id UUID,
        prescription_date DATE,
        fill_date DATE,
        quantity INTEGER,
        days_supply INTEGER,
        refills INTEGER,
        refill_number INTEGER,
        is_new BOOLEAN,
        batch_id INTEGER,
        created_at TIMESTAMPTZ
    ) ON COMMIT DROP;
    
    -- Import data from storage to the temporary table
    EXECUTE format('
        COPY temp_prescriptions FROM %L
        WITH (FORMAT CSV, HEADER true)',
        storage_object.content
    );
    
    -- Insert from temporary table to the actual table
    INSERT INTO public.patient_prescriptions
    SELECT * FROM temp_prescriptions;
    
    -- Get the count of imported rows
    GET DIAGNOSTICS imported_count = ROW_COUNT;
    
    RETURN imported_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create a function to import directly from a CSV string
-- This is useful for smaller files that can be uploaded through the API
CREATE OR REPLACE FUNCTION import_prescriptions_from_csv_string(
    csv_content TEXT
) RETURNS INTEGER AS $$
DECLARE
    imported_count INTEGER := 0;
BEGIN
    -- Create a temporary table to load the CSV data
    CREATE TEMP TABLE temp_prescriptions (
        id UUID,
        provider_id UUID,
        patient_id UUID,
        medication_id UUID,
        prescription_date DATE,
        fill_date DATE,
        quantity INTEGER,
        days_supply INTEGER,
        refills INTEGER,
        refill_number INTEGER,
        is_new BOOLEAN,
        batch_id INTEGER,
        created_at TIMESTAMPTZ
    ) ON COMMIT DROP;
    
    -- Import data from the CSV string to the temporary table
    COPY temp_prescriptions FROM STDIN WITH (FORMAT CSV, HEADER true);
    -- The CSV content would be inserted here
    
    -- Insert from temporary table to the actual table
    INSERT INTO public.patient_prescriptions
    SELECT * FROM temp_prescriptions;
    
    -- Get the count of imported rows
    GET DIAGNOSTICS imported_count = ROW_COUNT;
    
    RETURN imported_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create a view to join patient_prescriptions with related tables
CREATE OR REPLACE VIEW prescription_details AS
SELECT 
    pp.id,
    pp.provider_id,
    pp.patient_id,
    pp.medication_id,
    pp.prescription_date,
    pp.fill_date,
    pp.quantity,
    pp.days_supply,
    pp.refills,
    pp.refill_number,
    pp.is_new,
    pp.batch_id,
    pp.created_at,
    p.first_name AS provider_first_name,
    p.last_name AS provider_last_name,
    p.specialty AS provider_specialty,
    p.npi AS provider_npi,
    pat.first_name AS patient_first_name,
    pat.last_name AS patient_last_name,
    pat.date_of_birth AS patient_dob,
    m.medication_name,
    m.medication_ndc,
    m.brand_generic,
    m.category AS medication_category,
    m.specialty AS medication_specialty
FROM 
    public.patient_prescriptions pp
LEFT JOIN 
    public.providers p ON pp.provider_id = p.id
LEFT JOIN 
    public.patients pat ON pp.patient_id = pat.id
LEFT JOIN 
    public.medications m ON pp.medication_id = m.id;

-- Add comment to the view
COMMENT ON VIEW prescription_details IS 
    'Joined view of patient_prescriptions with provider, patient, and medication details';

/*
IMPORT INSTRUCTIONS FOR SUPABASE:

Method 1: Using the Supabase Dashboard
1. Run this SQL script in the Supabase SQL Editor to create the table and supporting objects
2. Upload each CSV file to Supabase Storage (create a bucket called "prescriptions" first)
3. For each uploaded file, run:
   SELECT import_prescriptions_from_storage('prescriptions', 'prescriptions_ids_only_timestamp_part1.csv');
   SELECT import_prescriptions_from_storage('prescriptions', 'prescriptions_ids_only_timestamp_part2.csv');
   ... and so on for each part

Method 2: Using Supabase REST API
1. Run this SQL script in the Supabase SQL Editor to create the table and supporting objects
2. For each CSV file, use the Supabase REST API to:
   a. Upload the file to Storage, or
   b. Send chunks of CSV data directly using the import_prescriptions_from_csv_string function

Method 3: Using pgAdmin or psql with a direct connection
If you have direct PostgreSQL access to your Supabase database:
1. Run this SQL script to create the table
2. Use the PostgreSQL COPY command directly:
   \COPY public.patient_prescriptions FROM '/path/to/prescriptions_ids_only_timestamp_part1.csv' WITH (FORMAT CSV, HEADER true);
*/
