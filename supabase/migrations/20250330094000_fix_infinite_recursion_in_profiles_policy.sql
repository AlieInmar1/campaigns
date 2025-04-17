-- Migration: Fix Infinite Recursion in Profiles Policy
-- This migration fixes the "infinite recursion detected in policy for relation 'profiles'" error
-- by replacing the problematic admin policy with a more efficient approach

BEGIN;

-- Drop the problematic policy that's causing infinite recursion
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;

-- Create separate policies for each operation instead of one general policy
-- This avoids the recursion by being more specific about what admins can do

-- Admins can insert new profiles
CREATE POLICY "Admins can insert profiles" 
ON public.profiles FOR INSERT
WITH CHECK (
  -- Use a subquery with explicit column reference to avoid recursion
  EXISTS (
    SELECT 1 FROM public.profiles AS admin_profiles 
    WHERE admin_profiles.id = auth.uid() AND admin_profiles.role = 'admin'
  )
);

-- Admins can update any profile
CREATE POLICY "Admins can update profiles" 
ON public.profiles FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles AS admin_profiles 
    WHERE admin_profiles.id = auth.uid() AND admin_profiles.role = 'admin'
  )
);

-- Admins can delete profiles
CREATE POLICY "Admins can delete profiles" 
ON public.profiles FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles AS admin_profiles 
    WHERE admin_profiles.id = auth.uid() AND admin_profiles.role = 'admin'
  )
);

-- Show a completion message
DO $$
BEGIN
  RAISE NOTICE 'Fixed infinite recursion in profiles policy';
END $$;

COMMIT;
