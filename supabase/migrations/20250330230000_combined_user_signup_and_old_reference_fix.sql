-- Combined fix for user signup, profile creation, and "missing FROM-clause entry for table 'old'" error
-- This migration addresses all issues related to user signup and profile creation

-- Start transaction
BEGIN;

-- Fix the trigger function that creates a profile when a new user signs up
-- This version avoids referencing OLD in an INSERT trigger (which causes the "missing FROM-clause entry for table 'old'" error)
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

-- Create a function to generate sample campaign results for a new user
CREATE OR REPLACE FUNCTION public.generate_sample_campaign_results(user_id UUID)
RETURNS VOID AS $$
DECLARE
  campaign_rec RECORD;
BEGIN
  -- Loop through the user's campaigns
  FOR campaign_rec IN (
    SELECT id 
    FROM public.campaigns 
    WHERE created_by = user_id
  ) LOOP
    -- Create sample campaign results
    INSERT INTO public.campaign_results (
      id, 
      campaign_id, 
      impressions, 
      clicks, 
      conversions, 
      spend, 
      roi, 
      created_at, 
      updated_at
    )
    VALUES (
      gen_random_uuid(),
      campaign_rec.id,
      floor(random() * 10000) + 5000,  -- Random impressions between 5000-15000
      floor(random() * 1000) + 500,    -- Random clicks between 500-1500
      floor(random() * 100) + 50,      -- Random conversions between 50-150
      (random() * 5000) + 1000,        -- Random spend between $1000-$6000
      (random() * 5) + 2,              -- Random ROI between 2-7
      NOW() - interval '30 days',
      NOW()
    );
    
    -- Create script lift data for the campaign
    PERFORM generate_script_lift_data(campaign_rec.id);
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to generate script lift data for a campaign
CREATE OR REPLACE FUNCTION public.generate_script_lift_data(campaign_id UUID)
RETURNS VOID AS $$
DECLARE
  base_scripts INT := floor(random() * 500) + 100;  -- Random base scripts between 100-600
  lift_scripts INT := floor(random() * 300) + 50;   -- Random lift between 50-350
BEGIN
  -- Create script lift data
  INSERT INTO public.script_lift_data (
    id,
    campaign_id,
    base_scripts,
    lift_scripts,
    lift_percentage,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    campaign_id,
    base_scripts,
    lift_scripts,
    (lift_scripts::FLOAT / base_scripts) * 100,
    NOW() - interval '30 days',
    NOW()
  );
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

-- Drop the existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create the trigger to handle new user creation
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Fix the RLS policy for profiles to allow new users to access their profile
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
CREATE POLICY "Users can view their own profile"
ON public.profiles
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
ON public.profiles
FOR UPDATE
USING (auth.uid() = user_id);

-- Ensure the profiles table has the correct structure
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'role'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN role TEXT DEFAULT 'user';
  END IF;
END $$;

COMMIT;
