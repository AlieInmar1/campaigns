-- Migration: Fix Profile Policy Without OLD Reference
-- This fixes the "missing FROM-clause entry for table "old"" error

BEGIN;

-- Drop the problematic policy
DROP POLICY IF EXISTS "Users can update their own profiles" ON public.profiles;

-- Create an improved version without the OLD reference 
-- This policy allows users to update their own profiles
-- but without allowing them to change their role
CREATE POLICY "Users can update their own profiles" 
ON public.profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id AND 
  role IS NOT NULL
);

-- Create a trigger to prevent role changes by non-admins
CREATE OR REPLACE FUNCTION prevent_role_changes_by_non_admins()
RETURNS TRIGGER AS $$
BEGIN
  -- Only allow role changes if user is an admin
  IF NEW.role <> OLD.role AND 
     NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only admins can change roles';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the trigger if it exists to avoid duplicates
DROP TRIGGER IF EXISTS prevent_role_changes ON public.profiles;

-- Create the trigger
CREATE TRIGGER prevent_role_changes
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION prevent_role_changes_by_non_admins();

-- Show a completion message
DO $$
BEGIN
  RAISE NOTICE 'Profile policy fixes applied successfully';
END $$;

COMMIT;
