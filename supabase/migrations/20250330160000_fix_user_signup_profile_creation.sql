/*
  # Fix User Signup and Profile Creation
  
  This migration fixes the issue with user signup and profile creation.
  The original error was: "ERROR: 42P01: missing FROM-clause entry for table 'old'"
  
  This typically happens in trigger functions when trying to reference the 'old' record
  without properly declaring it in the trigger function.
*/

-- Start transaction
BEGIN;

-- First, let's check the existing trigger function for user signup
DO $$
DECLARE
  function_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'create_profile_for_new_user'
  ) INTO function_exists;
  
  IF function_exists THEN
    RAISE NOTICE 'Function create_profile_for_new_user exists';
  ELSE
    RAISE NOTICE 'Function create_profile_for_new_user does not exist';
  END IF;
END $$;

-- Drop the existing trigger if it exists
DROP TRIGGER IF EXISTS create_profile_on_signup ON auth.users;

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS public.create_profile_for_new_user();

-- Create a fixed version of the function
CREATE OR REPLACE FUNCTION public.create_profile_for_new_user()
RETURNS TRIGGER AS $$
DECLARE
  default_role TEXT := 'user';
  new_user_id UUID;
  sample_campaign_ids UUID[];
BEGIN
  -- Store the new user's ID
  new_user_id := NEW.id;
  
  -- Create a profile for the new user
  INSERT INTO public.profiles (
    id,
    user_id,
    email,
    role,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    new_user_id,
    NEW.email,
    default_role,
    NOW(),
    NOW()
  );
  
  -- Get sample campaign IDs to assign to the new user
  -- We'll get the 3 most recent sample campaigns
  SELECT array_agg(id) INTO sample_campaign_ids
  FROM public.campaigns
  WHERE is_sample = TRUE
  ORDER BY created_at DESC
  LIMIT 3;
  
  -- If we have sample campaigns, assign them to the user
  IF array_length(sample_campaign_ids, 1) > 0 THEN
    -- For each sample campaign, create a copy for the new user
    FOR i IN 1..array_length(sample_campaign_ids, 1) LOOP
      -- Create a copy of the campaign for the new user
      WITH campaign_copy AS (
        INSERT INTO public.campaigns (
          name,
          description,
          start_date,
          end_date,
          status,
          user_id,
          is_sample,
          created_at,
          updated_at
        )
        SELECT 
          name || ' (Sample ' || i || ')',
          description,
          start_date,
          end_date,
          status,
          new_user_id,
          TRUE,
          NOW(),
          NOW()
        FROM public.campaigns
        WHERE id = sample_campaign_ids[i]
        RETURNING id
      )
      -- Copy campaign results if they exist
      INSERT INTO public.campaign_results (
        campaign_id,
        metric_name,
        metric_value,
        created_at,
        updated_at
      )
      SELECT 
        (SELECT id FROM campaign_copy),
        metric_name,
        metric_value,
        NOW(),
        NOW()
      FROM public.campaign_results
      WHERE campaign_id = sample_campaign_ids[i];
    END LOOP;
  END IF;
  
  -- Return the new user record
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
CREATE TRIGGER create_profile_on_signup
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.create_profile_for_new_user();

-- Add a comment to the function
COMMENT ON FUNCTION public.create_profile_for_new_user() IS 
'Creates a profile and assigns sample campaigns when a new user signs up';

-- Verify the trigger is created
DO $$
DECLARE
  trigger_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'create_profile_on_signup'
  ) INTO trigger_exists;
  
  IF trigger_exists THEN
    RAISE NOTICE 'Trigger create_profile_on_signup exists';
  ELSE
    RAISE NOTICE 'Trigger create_profile_on_signup does not exist';
  END IF;
END $$;

-- Create a function to manually assign sample campaigns to an existing user
CREATE OR REPLACE FUNCTION public.assign_sample_campaigns_to_user(user_id UUID)
RETURNS VOID AS $$
DECLARE
  sample_campaign_ids UUID[];
  i INTEGER;
BEGIN
  -- Get sample campaign IDs
  SELECT array_agg(id) INTO sample_campaign_ids
  FROM public.campaigns
  WHERE is_sample = TRUE
  ORDER BY created_at DESC
  LIMIT 3;
  
  -- If we have sample campaigns, assign them to the user
  IF array_length(sample_campaign_ids, 1) > 0 THEN
    -- For each sample campaign, create a copy for the user
    FOR i IN 1..array_length(sample_campaign_ids, 1) LOOP
      -- Create a copy of the campaign for the user
      WITH campaign_copy AS (
        INSERT INTO public.campaigns (
          name,
          description,
          start_date,
          end_date,
          status,
          user_id,
          is_sample,
          created_at,
          updated_at
        )
        SELECT 
          name || ' (Sample ' || i || ')',
          description,
          start_date,
          end_date,
          status,
          user_id,
          TRUE,
          NOW(),
          NOW()
        FROM public.campaigns
        WHERE id = sample_campaign_ids[i]
        RETURNING id
      )
      -- Copy campaign results if they exist
      INSERT INTO public.campaign_results (
        campaign_id,
        metric_name,
        metric_value,
        created_at,
        updated_at
      )
      SELECT 
        (SELECT id FROM campaign_copy),
        metric_name,
        metric_value,
        NOW(),
        NOW()
      FROM public.campaign_results
      WHERE campaign_id = sample_campaign_ids[i];
    END LOOP;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add a comment to the function
COMMENT ON FUNCTION public.assign_sample_campaigns_to_user(UUID) IS 
'Manually assigns sample campaigns to an existing user';

COMMIT;
