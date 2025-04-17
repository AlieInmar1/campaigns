-- Migration: Fix Campaign RLS and Sample Data
-- This migration adds RLS policies for the campaigns table and ensures sample data is properly created

BEGIN;

-- =============================================
-- PART 1: Add RLS policies for the campaigns table
-- =============================================

-- First, enable RLS on the campaigns table if it's not already enabled
ALTER TABLE IF EXISTS public.campaigns ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view their own campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Users can insert their own campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Users can update their own campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Users can delete their own campaigns" ON public.campaigns;
DROP POLICY IF EXISTS "Admins can manage all campaigns" ON public.campaigns;

-- Create policies for regular users
-- Users can view their own campaigns
CREATE POLICY "Users can view their own campaigns" 
ON public.campaigns FOR SELECT 
USING (auth.uid() = created_by);

-- Users can insert their own campaigns
CREATE POLICY "Users can insert their own campaigns" 
ON public.campaigns FOR INSERT 
WITH CHECK (auth.uid() = created_by);

-- Users can update their own campaigns
CREATE POLICY "Users can update their own campaigns" 
ON public.campaigns FOR UPDATE 
USING (auth.uid() = created_by);

-- Users can delete their own campaigns
CREATE POLICY "Users can delete their own campaigns" 
ON public.campaigns FOR DELETE 
USING (auth.uid() = created_by);

-- Create policy for admins (using explicit table alias to avoid recursion)
CREATE POLICY "Admins can manage all campaigns" 
ON public.campaigns
USING (
  EXISTS (
    SELECT 1 FROM public.profiles AS admin_profiles 
    WHERE admin_profiles.id = auth.uid() AND admin_profiles.role = 'admin'
  )
);

-- =============================================
-- PART 2: Verify sample campaign templates exist
-- =============================================

-- Check if sample_campaign_templates table exists and has data
DO $$
DECLARE
  template_count INTEGER;
BEGIN
  -- Check if the table exists
  IF EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'sample_campaign_templates'
  ) THEN
    -- Count templates
    SELECT COUNT(*) INTO template_count FROM public.sample_campaign_templates;
    
    -- If no templates exist, raise a notice
    IF template_count = 0 THEN
      RAISE NOTICE 'No sample campaign templates found. Run the 20250330091000_fix_user_signup_sample_data.sql migration to create them.';
    ELSE
      RAISE NOTICE 'Found % sample campaign templates', template_count;
    END IF;
  ELSE
    RAISE NOTICE 'sample_campaign_templates table does not exist. Run the 20250330091000_fix_user_signup_sample_data.sql migration to create it.';
  END IF;
END $$;

-- =============================================
-- PART 3: Ensure the copy_sample_data_for_new_user function has necessary permissions
-- =============================================

-- Grant necessary permissions to the function
DO $$
BEGIN
  -- Check if the function exists
  IF EXISTS (
    SELECT FROM pg_proc 
    WHERE proname = 'copy_sample_data_for_new_user'
  ) THEN
    -- Alter the function to ensure it has SECURITY DEFINER
    ALTER FUNCTION public.copy_sample_data_for_new_user(UUID) SECURITY DEFINER;
    
    -- Grant execute permission to authenticated users
    GRANT EXECUTE ON FUNCTION public.copy_sample_data_for_new_user(UUID) TO authenticated;
    
    RAISE NOTICE 'Updated permissions for copy_sample_data_for_new_user function';
  ELSE
    RAISE NOTICE 'copy_sample_data_for_new_user function does not exist. Run the 20250330091000_fix_user_signup_sample_data.sql migration to create it.';
  END IF;
END $$;

-- =============================================
-- PART 4: Add a user_id column to campaigns if it doesn't exist
-- =============================================

-- Check if the campaigns table has a user_id column
DO $$
BEGIN
  -- Check if the user_id column exists
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'campaigns' 
    AND column_name = 'user_id'
  ) THEN
    -- Add the user_id column
    ALTER TABLE public.campaigns ADD COLUMN user_id UUID REFERENCES auth.users(id);
    
    -- Update existing campaigns to set user_id = created_by
    UPDATE public.campaigns SET user_id = created_by WHERE user_id IS NULL;
    
    RAISE NOTICE 'Added user_id column to campaigns table and updated existing campaigns';
  ELSE
    RAISE NOTICE 'user_id column already exists in campaigns table';
  END IF;
END $$;

-- Show a completion message
DO $$
BEGIN
  RAISE NOTICE 'Campaign RLS and sample data fixes applied successfully';
END $$;

COMMIT;
