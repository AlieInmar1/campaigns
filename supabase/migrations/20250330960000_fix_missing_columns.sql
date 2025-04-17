-- Fix missing columns in medications and providers tables
-- This migration adds the missing columns that are causing errors in the application

-- Check if the medications table exists
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'medications'
  ) THEN
    -- Check if the name column exists in medications table
    IF NOT EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'medications' 
      AND column_name = 'name'
    ) THEN
      -- Add name column to medications table
      ALTER TABLE medications ADD COLUMN name TEXT;
      
      -- Update name column with values from medication_name if it exists
      IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'medications' 
        AND column_name = 'medication_name'
      ) THEN
        UPDATE medications SET name = medication_name WHERE medication_name IS NOT NULL;
      END IF;
      
      RAISE NOTICE 'Added name column to medications table';
    ELSE
      RAISE NOTICE 'name column already exists in medications table';
    END IF;
  ELSE
    RAISE NOTICE 'medications table does not exist';
  END IF;
  
  -- Check if the providers table exists
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'providers'
  ) THEN
    -- Check if the geographic_area column exists in providers table
    IF NOT EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'providers' 
      AND column_name = 'geographic_area'
    ) THEN
      -- Add geographic_area column to providers table
      ALTER TABLE providers ADD COLUMN geographic_area TEXT;
      
      -- Update geographic_area column with values from region if it exists
      IF EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'providers' 
        AND column_name = 'region'
      ) THEN
        UPDATE providers SET geographic_area = region WHERE region IS NOT NULL;
      END IF;
      
      RAISE NOTICE 'Added geographic_area column to providers table';
    ELSE
      RAISE NOTICE 'geographic_area column already exists in providers table';
    END IF;
  ELSE
    RAISE NOTICE 'providers table does not exist';
  END IF;
END $$;

-- Create indexes on the new columns for better performance
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'medications'
  ) AND EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'medications' 
    AND column_name = 'name'
  ) THEN
    -- Create index on medications.name if it doesn't exist
    IF NOT EXISTS (
      SELECT FROM pg_indexes 
      WHERE tablename = 'medications' 
      AND indexname = 'idx_medications_name'
    ) THEN
      CREATE INDEX idx_medications_name ON medications (name);
      RAISE NOTICE 'Created index on medications.name';
    END IF;
  END IF;
  
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'providers'
  ) AND EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'providers' 
    AND column_name = 'geographic_area'
  ) THEN
    -- Create index on providers.geographic_area if it doesn't exist
    IF NOT EXISTS (
      SELECT FROM pg_indexes 
      WHERE tablename = 'providers' 
      AND indexname = 'idx_providers_geographic_area'
    ) THEN
      CREATE INDEX idx_providers_geographic_area ON providers (geographic_area);
      RAISE NOTICE 'Created index on providers.geographic_area';
    END IF;
  END IF;
END $$;
