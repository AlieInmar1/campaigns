-- Check the structure of the prescriptions table
BEGIN;

-- This will output the column names and data types of the prescriptions table
DO $$
DECLARE
  column_info RECORD;
BEGIN
  RAISE NOTICE 'Prescriptions Table Structure:';
  FOR column_info IN 
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'prescriptions'
    ORDER BY ordinal_position
  LOOP
    RAISE NOTICE 'Column: %, Type: %, Nullable: %', 
      column_info.column_name, 
      column_info.data_type,
      column_info.is_nullable;
  END LOOP;
END $$;

-- Also check if the patients table exists and its structure
DO $$
DECLARE
  column_info RECORD;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'patients') THEN
    RAISE NOTICE 'Patients Table Structure:';
    FOR column_info IN 
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'patients'
      ORDER BY ordinal_position
    LOOP
      RAISE NOTICE 'Column: %, Type: %, Nullable: %', 
        column_info.column_name, 
        column_info.data_type,
        column_info.is_nullable;
    END LOOP;
  ELSE
    RAISE NOTICE 'Patients table does not exist';
  END IF;
END $$;

ROLLBACK; -- We're just checking, not making any changes
