-- Fix missing columns in medications and providers tables
-- This migration adds the 'name' column to medications table and 'geographic_area' column to providers table

-- Add name column to medications table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'medications' AND column_name = 'name'
    ) THEN
        ALTER TABLE medications ADD COLUMN name TEXT;
        
        -- Update the name column based on existing data if possible
        -- For example, if there's a 'label' or 'medication_name' column, we could copy from there
        -- Otherwise, we'll set a default value based on the medication_id
        UPDATE medications 
        SET name = 'Medication ' || medication_id::text
        WHERE name IS NULL;
        
        -- Make the column NOT NULL after populating it
        ALTER TABLE medications ALTER COLUMN name SET NOT NULL;
    END IF;
END
$$;

-- Add geographic_area column to providers table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'providers' AND column_name = 'geographic_area'
    ) THEN
        ALTER TABLE providers ADD COLUMN geographic_area TEXT;
        
        -- Update the geographic_area column based on existing data if possible
        -- If there's a 'region' column, we'll copy from there
        -- Otherwise, we'll set a default value
        UPDATE providers 
        SET geographic_area = region
        WHERE geographic_area IS NULL AND region IS NOT NULL;
        
        -- For any remaining NULL values, set a default
        UPDATE providers 
        SET geographic_area = 'Unknown'
        WHERE geographic_area IS NULL;
    END IF;
END
$$;

-- Create an index on the new columns to improve query performance
CREATE INDEX IF NOT EXISTS idx_medications_name ON medications(name);
CREATE INDEX IF NOT EXISTS idx_providers_geographic_area ON providers(geographic_area);

-- Add a comment to the migration for documentation
COMMENT ON COLUMN medications.name IS 'The display name of the medication';
COMMENT ON COLUMN providers.geographic_area IS 'The geographic area where the provider is located';
