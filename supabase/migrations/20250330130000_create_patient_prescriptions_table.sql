/*
  # Create Patient Prescriptions Table
  
  This migration creates a separate table for patient-level prescription data,
  which is different from the campaign-level prescriptions table that already exists.
*/

-- Start transaction
BEGIN;

-- Create a new table for patient-level prescriptions
CREATE TABLE IF NOT EXISTS public.patient_prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id TEXT NOT NULL,
  patient_id UUID REFERENCES public.patients(id),
  medication_id TEXT NOT NULL,
  medication_name TEXT NOT NULL,
  medication_category TEXT,
  prescription_date DATE NOT NULL,
  fill_date DATE,
  quantity INTEGER NOT NULL,
  days_supply INTEGER NOT NULL,
  refills INTEGER NOT NULL DEFAULT 0,
  refill_number INTEGER DEFAULT 0,
  is_new BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_provider_id ON public.patient_prescriptions(provider_id);
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_patient_id ON public.patient_prescriptions(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_medication_id ON public.patient_prescriptions(medication_id);
CREATE INDEX IF NOT EXISTS idx_patient_prescriptions_prescription_date ON public.patient_prescriptions(prescription_date);

-- Enable RLS on the patient_prescriptions table
ALTER TABLE public.patient_prescriptions ENABLE ROW LEVEL SECURITY;

-- Create policy for patient_prescriptions
CREATE POLICY "Allow authenticated read access for patient_prescriptions"
  ON public.patient_prescriptions FOR SELECT
  TO authenticated
  USING (true);

-- Allow insert, update, delete for service roles only
CREATE POLICY "Allow all access for service role on patient_prescriptions"
  ON public.patient_prescriptions FOR ALL
  TO service_role
  USING (true);

COMMIT;
