-- Add profiles with user roles
-- This migration adds user role support with a profiles table
-- It sets up the profiles table, safely migrates existing users, 
-- and designates aliecohen+2@gmail.com as an admin user

-- Use a transaction to roll back if anything fails
BEGIN;

-- Create profiles table only if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL DEFAULT 'user',
  full_name VARCHAR(255),
  company VARCHAR(255),
  title VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add an updated_at trigger for the profiles table
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger if it doesn't exist
DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- Create function to ensure all users have profiles
CREATE OR REPLACE FUNCTION public.create_profile_for_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role)
  VALUES (new.id, 'user')
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger if it doesn't exist
DROP TRIGGER IF EXISTS create_profile_after_signup ON auth.users;
CREATE TRIGGER create_profile_after_signup
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.create_profile_for_user();

-- Safely migrate existing users to profiles
INSERT INTO public.profiles (id, role)
SELECT id, 'user' 
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- Set specific admin user without disrupting others
UPDATE public.profiles 
SET role = 'admin' 
WHERE id IN (
  SELECT id FROM auth.users WHERE email = 'aliecohen+2@gmail.com'
);

-- Set up RLS (Row Level Security) for the profiles table
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies

-- Everyone can read profiles
CREATE POLICY "Profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

-- Users can update their own profiles (except role)
CREATE POLICY "Users can update their own profiles" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Create a trigger to prevent users from changing their own role
CREATE OR REPLACE FUNCTION prevent_role_self_change()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.id = auth.uid() AND OLD.role <> NEW.role THEN
    RAISE EXCEPTION 'Users cannot change their own role';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_role_self_update ON public.profiles;
CREATE TRIGGER prevent_role_self_update
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION prevent_role_self_change();

-- Only admins can update roles
CREATE POLICY "Only admins can update roles" 
ON public.profiles FOR UPDATE USING (
  auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
);

-- Only admins can insert/delete profiles
CREATE POLICY "Only admins can insert profiles" 
ON public.profiles FOR INSERT WITH CHECK (
  auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
);

CREATE POLICY "Only admins can delete profiles" 
ON public.profiles FOR DELETE USING (
  auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
);

-- Create helper function to promote a user to admin (for use by other admins)
CREATE OR REPLACE FUNCTION public.promote_to_admin(user_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  target_user_id UUID;
  calling_user_role TEXT;
BEGIN
  -- Check if the calling user is an admin
  SELECT role INTO calling_user_role 
  FROM public.profiles 
  WHERE id = auth.uid();
  
  IF calling_user_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can promote users';
  END IF;
  
  -- Find the user to promote
  SELECT id INTO target_user_id 
  FROM auth.users 
  WHERE email = user_email;
  
  IF target_user_id IS NULL THEN
    RETURN FALSE; -- User not found
  END IF;
  
  -- Promote the user
  UPDATE public.profiles
  SET role = 'admin'
  WHERE id = target_user_id;
  
  RETURN FOUND; -- Returns true if the update affected a row
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create helper function to demote an admin to regular user
CREATE OR REPLACE FUNCTION public.demote_from_admin(user_email TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  target_user_id UUID;
  calling_user_role TEXT;
  admin_count INTEGER;
BEGIN
  -- Check if the calling user is an admin
  SELECT role INTO calling_user_role 
  FROM public.profiles 
  WHERE id = auth.uid();
  
  IF calling_user_role != 'admin' THEN
    RAISE EXCEPTION 'Only admins can demote users';
  END IF;
  
  -- Find the user to demote
  SELECT id INTO target_user_id 
  FROM auth.users 
  WHERE email = user_email;
  
  IF target_user_id IS NULL THEN
    RETURN FALSE; -- User not found
  END IF;
  
  -- Make sure we're not demoting the last admin
  SELECT COUNT(*) INTO admin_count
  FROM public.profiles
  WHERE role = 'admin';
  
  IF admin_count <= 1 THEN
    RAISE EXCEPTION 'Cannot demote the last admin user';
  END IF;
  
  -- Demote the user
  UPDATE public.profiles
  SET role = 'user'
  WHERE id = target_user_id;
  
  RETURN FOUND; -- Returns true if the update affected a row
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the existing function first to avoid return type issues
DROP FUNCTION IF EXISTS public.copy_sample_data_for_new_user(UUID);

-- Recreate the function with improved error handling
CREATE FUNCTION public.copy_sample_data_for_new_user(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  campaign_count INTEGER;
BEGIN
  -- Exit early if user_id is null
  IF user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- First ensure this user has a profile
  INSERT INTO public.profiles (id, role)
  VALUES (user_id, 'user')
  ON CONFLICT (id) DO NOTHING;
  
  -- Check if user already has campaigns
  SELECT COUNT(*) INTO campaign_count FROM campaigns WHERE created_by = user_id;
  
  IF campaign_count = 0 THEN
    -- Insert sample campaigns for the user
    INSERT INTO campaigns (
      name, 
      target_condition_id, 
      target_medication_id, 
      target_geographic_area, 
      target_specialty, 
      status, 
      start_date, 
      end_date, 
      created_by
    )
    SELECT 
      c.name, 
      c.target_condition_id, 
      c.target_medication_id, 
      c.target_geographic_area, 
      c.target_specialty, 
      c.status, 
      c.start_date, 
      c.end_date, 
      user_id
    FROM campaigns c
    WHERE c.id IN (
      'c1', 'c2', 'c3' -- IDs of the sample campaigns
    )
    -- Handle the rare case where sample campaigns don't exist
    AND EXISTS (SELECT 1 FROM campaigns WHERE id = 'c1')
    LIMIT 3;
    
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- On any error, log it and return false
    RAISE NOTICE 'Error copying sample data: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
