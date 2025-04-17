-- Migration: Update medications table schema
-- Adds new columns required for comprehensive medication dataset

BEGIN;

-- Add code column as unique identifier if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'code'
  ) THEN
    ALTER TABLE medications ADD COLUMN code TEXT;
    CREATE UNIQUE INDEX idx_medications_code ON medications(code);
  END IF;
END $$;

-- Add subcategory column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'subcategory'
  ) THEN
    ALTER TABLE medications ADD COLUMN subcategory TEXT;
  END IF;
END $$;

-- Add specialty column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'specialty'
  ) THEN
    ALTER TABLE medications ADD COLUMN specialty TEXT;
  END IF;
END $$;

-- Add generic_name column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'generic_name'
  ) THEN
    ALTER TABLE medications ADD COLUMN generic_name TEXT;
  END IF;
END $$;

-- Add is_brand_name column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'is_brand_name'
  ) THEN
    ALTER TABLE medications ADD COLUMN is_brand_name BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add is_target_medication column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'is_target_medication'
  ) THEN
    ALTER TABLE medications ADD COLUMN is_target_medication BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add is_sample_data column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'medications' AND column_name = 'is_sample_data'
  ) THEN
    ALTER TABLE medications ADD COLUMN is_sample_data BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Create indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_medications_category ON medications(category);
CREATE INDEX IF NOT EXISTS idx_medications_subcategory ON medications(subcategory);
CREATE INDEX IF NOT EXISTS idx_medications_specialty ON medications(specialty);
CREATE INDEX IF NOT EXISTS idx_medications_is_brand_name ON medications(is_brand_name);
CREATE INDEX IF NOT EXISTS idx_medications_is_target_medication ON medications(is_target_medication);

-- Update existing records to set default values
UPDATE medications 
SET 
  is_brand_name = FALSE,
  is_target_medication = FALSE,
  is_sample_data = FALSE
WHERE 
  is_brand_name IS NULL OR
  is_target_medication IS NULL OR
  is_sample_data IS NULL;

-- Log the schema changes
DO $$
BEGIN
  RAISE NOTICE 'Medications table schema updated successfully with new columns for comprehensive dataset';
END $$;

COMMIT;
