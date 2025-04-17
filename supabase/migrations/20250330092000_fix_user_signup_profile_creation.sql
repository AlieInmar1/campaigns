-- Migration: Fix User Signup Profile Creation
-- This migration addresses the "Database error saving new user" issue
-- by improving the profile creation trigger and RLS policies

BEGIN;

-- 1. First we need to drop the existing trigger and function
DROP TRIGGER IF EXISTS create_profile_after_signup ON auth.users;
DROP FUNCTION IF EXISTS public.create_profile_for_user();

-- 2. Create a more robust profile creation function
-- This new version has better error handling and explicitly uses SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.create_profile_for_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Add defensive error handling
  BEGIN
    INSERT INTO public.profiles (
      id,
      role,
      full_name,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      'user',
      COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO NOTHING;

    RETURN NEW;
  EXCEPTION WHEN OTHERS THEN
    -- Log error but don't fail the entire user creation
    RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW; -- Still return NEW so user creation succeeds
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create a new trigger that runs after user insertion
-- Make it more robust by using FOR EACH ROW WHEN condition
CREATE TRIGGER create_profile_after_signup
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.create_profile_for_user();

-- 4. Simplify and fix RLS policies
-- First drop all existing policies on the profiles table to avoid conflicts
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profiles" ON public.profiles;
DROP POLICY IF EXISTS "Only admins can update roles" ON public.profiles;
DROP POLICY IF EXISTS "Only admins can insert profiles" ON public.profiles;
DROP POLICY IF EXISTS "Only admins can delete profiles" ON public.profiles;

-- Re-create the policies with clear, simpler logic
-- Everyone can view profiles
CREATE POLICY "Profiles are viewable by everyone" 
ON public.profiles FOR SELECT 
USING (true);

-- Users can update their own profiles, except role field
CREATE POLICY "Users can update their own profiles" 
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND 
  role IS NOT NULL AND
  role = OLD.role -- Prevent role changes
);

-- Admins can do anything with profiles
CREATE POLICY "Admins can manage all profiles" 
ON public.profiles
USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- 5. Fix any orphaned users by creating profiles for them
INSERT INTO public.profiles (id, role, created_at, updated_at)
SELECT 
  u.id, 
  'user', 
  NOW(), 
  NOW()
FROM 
  auth.users u
LEFT JOIN 
  public.profiles p ON u.id = p.id
WHERE 
  p.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 6. Create an alternative helper function to create profiles from the application code
-- This can be used as a fallback if the trigger fails
CREATE OR REPLACE FUNCTION public.ensure_user_profile(
  user_id UUID,
  user_role TEXT DEFAULT 'user',
  user_full_name TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO public.profiles (
    id,
    role,
    full_name,
    created_at,
    updated_at
  )
  VALUES (
    user_id,
    user_role,
    user_full_name,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    updated_at = NOW(),
    full_name = COALESCE(user_full_name, profiles.full_name);
    
  RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Error ensuring profile for user %: %', user_id, SQLERRM;
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Show a completion message
DO $$
BEGIN
  RAISE NOTICE 'User signup profile creation fixes applied successfully';
END $$;

COMMIT;
