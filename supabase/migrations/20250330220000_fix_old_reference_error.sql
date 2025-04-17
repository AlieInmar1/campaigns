-- Fix for "missing FROM-clause entry for table 'old'" error
-- This migration fixes the error that occurs when trying to reference the OLD record in an INSERT trigger

-- Start transaction
BEGIN;

-- Fix the handle_new_user function to avoid referencing OLD in an INSERT trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  default_role TEXT := 'user';
  new_user_id UUID := NEW.id;
  sample_campaign_ids UUID[];
BEGIN
  -- Create a profile for the new user
  INSERT INTO public.profiles (id, user_id, role, created_at, updated_at)
  VALUES (gen_random_uuid(), new_user_id, default_role, NOW(), NOW());
  
  -- Get sample campaign IDs to assign to the new user
  SELECT ARRAY_AGG(id) INTO sample_campaign_ids
  FROM public.campaigns
  WHERE is_sample = TRUE
  LIMIT 3;
  
  -- Assign sample campaigns to the new user if available
  IF array_length(sample_campaign_ids, 1) > 0 THEN
    -- Update the campaigns to be owned by the new user
    UPDATE public.campaigns
    SET created_by = new_user_id
    WHERE id = ANY(sample_campaign_ids);
    
    -- Generate sample campaign results for the user
    PERFORM generate_sample_campaign_results(new_user_id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix any other functions that might be referencing OLD in INSERT triggers
-- Check and fix the profile_update_timestamp function
CREATE OR REPLACE FUNCTION public.profile_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  -- Only set updated_at on UPDATE operations
  IF TG_OP = 'UPDATE' THEN
    NEW.updated_at = NOW();
  -- For INSERT operations, both created_at and updated_at are set
  ELSIF TG_OP = 'INSERT' THEN
    NEW.created_at = NOW();
    NEW.updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Check and fix the campaign_update_timestamp function
CREATE OR REPLACE FUNCTION public.campaign_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  -- Only set updated_at on UPDATE operations
  IF TG_OP = 'UPDATE' THEN
    NEW.updated_at = NOW();
  -- For INSERT operations, both created_at and updated_at are set
  ELSIF TG_OP = 'INSERT' THEN
    NEW.created_at = NOW();
    NEW.updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Check and fix any other timestamp triggers
DO $$
DECLARE
  trigger_rec RECORD;
BEGIN
  FOR trigger_rec IN (
    SELECT tgname, tgrelid::regclass AS table_name
    FROM pg_trigger
    WHERE tgname LIKE '%_timestamp'
  ) LOOP
    EXECUTE format('
      CREATE OR REPLACE FUNCTION public.%I()
      RETURNS TRIGGER AS $$
      BEGIN
        -- Only set updated_at on UPDATE operations
        IF TG_OP = ''UPDATE'' THEN
          NEW.updated_at = NOW();
        -- For INSERT operations, both created_at and updated_at are set
        ELSIF TG_OP = ''INSERT'' THEN
          NEW.created_at = NOW();
          NEW.updated_at = NOW();
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    ', trigger_rec.tgname);
  END LOOP;
END $$;

COMMIT;
