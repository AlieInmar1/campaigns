-- Fix missing columns in medications and providers tables
-- This migration adds the missing columns that are causing errors

-- Add name column to medications table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'medications' AND column_name = 'name'
    ) THEN
        ALTER TABLE medications ADD COLUMN name TEXT;
        
        -- Update existing records with name values based on id
        UPDATE medications SET name = 'Medication ' || id WHERE name IS NULL;
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
        
        -- Update existing records with geographic_area values based on region
        UPDATE providers SET geographic_area = region WHERE geographic_area IS NULL;
    END IF;
END
$$;

-- Create a function to ensure these columns exist for future operations
CREATE OR REPLACE FUNCTION check_required_columns()
RETURNS VOID AS $$
BEGIN
    -- Check medications table
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'medications' AND column_name = 'name'
    ) THEN
        RAISE EXCEPTION 'medications table is missing the name column';
    END IF;
    
    -- Check providers table
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'providers' AND column_name = 'geographic_area'
    ) THEN
        RAISE EXCEPTION 'providers table is missing the geographic_area column';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Run the check to verify columns exist
SELECT check_required_columns();
