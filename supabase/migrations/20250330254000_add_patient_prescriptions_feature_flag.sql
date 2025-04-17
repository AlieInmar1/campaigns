-- Add patient prescriptions feature flag
BEGIN;

-- Create feature_flags table if it doesn't exist
CREATE TABLE IF NOT EXISTS feature_flags (
  flag_name TEXT PRIMARY KEY,
  enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create function to check if a feature flag is enabled
CREATE OR REPLACE FUNCTION is_feature_enabled(flag_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM feature_flags
    WHERE feature_flags.flag_name = $1
    AND enabled = true
  );
END;
$$ LANGUAGE plpgsql;

-- Insert or update the patient prescriptions feature flag
INSERT INTO feature_flags (flag_name, enabled)
VALUES ('use_patient_prescriptions_for_targeting', true)
ON CONFLICT (flag_name) DO UPDATE
SET enabled = true,
    updated_at = CURRENT_TIMESTAMP;

-- Enable RLS
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users
CREATE POLICY "Allow authenticated read access for feature_flags"
  ON feature_flags FOR SELECT
  TO authenticated
  USING (true);

-- Create policy for authenticated users to update feature flags
CREATE POLICY "Allow authenticated update access for feature_flags"
  ON feature_flags FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

COMMIT;
