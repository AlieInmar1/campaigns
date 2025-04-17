/*
  # Create Patients Table
  
  This migration creates the patients table needed for patient-level prescription data.
*/

-- Start transaction
BEGIN;

-- Create the patients table
CREATE TABLE IF NOT EXISTS public.patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id TEXT UNIQUE,
  name TEXT,
  age INTEGER,
  gender TEXT,
  geographic_area TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_patients_geographic_area ON public.patients(geographic_area);

-- Enable RLS on the patients table
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

-- Create policy for patients
CREATE POLICY "Allow authenticated read access for patients"
  ON public.patients FOR SELECT TO authenticated
  USING (true);

-- Allow insert, update, delete for service roles only
CREATE POLICY "Allow all access for service role on patients"
  ON public.patients FOR ALL
  TO service_role
  USING (true);

COMMIT;
