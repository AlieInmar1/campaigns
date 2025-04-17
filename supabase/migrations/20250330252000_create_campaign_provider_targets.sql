-- Create campaign provider targets table
BEGIN;

-- Create the table
CREATE TABLE IF NOT EXISTS campaign_provider_targets (
  campaign_id UUID REFERENCES campaigns(id),
  provider_id TEXT REFERENCES providers(provider_id),
  matched_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (campaign_id, provider_id)
);

-- Enable RLS
ALTER TABLE campaign_provider_targets ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users
CREATE POLICY "Allow authenticated read access for campaign_provider_targets"
  ON campaign_provider_targets FOR SELECT
  TO authenticated
  USING (true);

COMMIT;
