-- Migration: Fix Creative Templates Table
-- This migration ensures the creative_templates table exists and is properly structured
-- Addresses the 404 error on creative_templates table

BEGIN;

-- Create creative_templates table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.creative_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  headline TEXT NOT NULL,
  body TEXT NOT NULL,
  cta TEXT NOT NULL, -- Call to action
  image_url TEXT,
  theme VARCHAR(100),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create function to handle updated_at column
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at trigger
DROP TRIGGER IF EXISTS set_creative_templates_updated_at ON public.creative_templates;
CREATE TRIGGER set_creative_templates_updated_at
BEFORE UPDATE ON public.creative_templates
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- Set up RLS (Row Level Security) for the creative_templates table
ALTER TABLE public.creative_templates ENABLE ROW LEVEL SECURITY;

-- Create policies to control access
-- Everyone can view templates
DROP POLICY IF EXISTS "Creative templates are viewable by everyone" ON public.creative_templates;
CREATE POLICY "Creative templates are viewable by everyone" 
ON public.creative_templates FOR SELECT USING (true);

-- Users can create their own templates
DROP POLICY IF EXISTS "Users can create their own templates" ON public.creative_templates;
CREATE POLICY "Users can create their own templates" 
ON public.creative_templates FOR INSERT 
WITH CHECK (auth.uid() = created_by);

-- Users can update their own templates, admins can update any
DROP POLICY IF EXISTS "Users can update their own templates" ON public.creative_templates;
CREATE POLICY "Users can update their own templates" 
ON public.creative_templates FOR UPDATE
USING (
  auth.uid() = created_by OR
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Users can delete their own templates, admins can delete any
DROP POLICY IF EXISTS "Users can delete their own templates" ON public.creative_templates;
CREATE POLICY "Users can delete their own templates" 
ON public.creative_templates FOR DELETE
USING (
  auth.uid() = created_by OR
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Insert default templates if none exist
INSERT INTO public.creative_templates (name, description, headline, body, cta, theme)
SELECT 
  'Clinical Study Results', 
  'Template for sharing clinical study results',
  'New Clinical Evidence for {{medication_name}}',
  'Recent studies show {{medication_name}} demonstrated {{percentage}}% improvement in {{metric}} compared to standard of care. Learn how this could benefit your patients with {{condition_name}}.',
  'Read Full Study',
  'clinical'
WHERE NOT EXISTS (SELECT 1 FROM public.creative_templates LIMIT 1);

INSERT INTO public.creative_templates (name, description, headline, body, cta, theme)
SELECT 
  'New Treatment Option', 
  'Template for introducing new treatment options',
  'Introducing: A New Option for {{condition_name}}',
  '{{medication_name}} offers a new approach to treating {{condition_name}} with a convenient {{dosing_schedule}} dosing schedule and improved safety profile.',
  'Learn More',
  'innovative'
WHERE NOT EXISTS (SELECT 1 FROM public.creative_templates WHERE name = 'New Treatment Option');

INSERT INTO public.creative_templates (name, description, headline, body, cta, theme)
SELECT 
  'Patient Support Program', 
  'Template for patient support programs',
  'Supporting Your {{condition_name}} Patients',
  'Our comprehensive support program helps patients stay on {{medication_name}} therapy with resources including financial assistance, educational materials, and adherence tools.',
  'Enroll Patients',
  'supportive'
WHERE NOT EXISTS (SELECT 1 FROM public.creative_templates WHERE name = 'Patient Support Program');

-- Create function to fix creative templates - can be called from other migrations
CREATE OR REPLACE FUNCTION public.fix_creative_templates()
RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = 'creative_templates') THEN
    CREATE TABLE public.creative_templates (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      description TEXT,
      headline TEXT NOT NULL,
      body TEXT NOT NULL,
      cta TEXT NOT NULL,
      image_url TEXT,
      theme VARCHAR(100),
      created_by UUID REFERENCES auth.users(id),
      created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
    );
    
    -- Add some default templates
    INSERT INTO public.creative_templates (name, description, headline, body, cta, theme)
    VALUES 
      (
        'Clinical Study Results', 
        'Template for sharing clinical study results',
        'New Clinical Evidence for {{medication_name}}',
        'Recent studies show {{medication_name}} demonstrated {{percentage}}% improvement in {{metric}} compared to standard of care. Learn how this could benefit your patients with {{condition_name}}.',
        'Read Full Study',
        'clinical'
      ),
      (
        'New Treatment Option', 
        'Template for introducing new treatment options',
        'Introducing: A New Option for {{condition_name}}',
        '{{medication_name}} offers a new approach to treating {{condition_name}} with a convenient {{dosing_schedule}} dosing schedule and improved safety profile.',
        'Learn More',
        'innovative'
      ),
      (
        'Patient Support Program', 
        'Template for patient support programs',
        'Supporting Your {{condition_name}} Patients',
        'Our comprehensive support program helps patients stay on {{medication_name}} therapy with resources including financial assistance, educational materials, and adherence tools.',
        'Enroll Patients',
        'supportive'
      );
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Execute the fix function
SELECT public.fix_creative_templates();

COMMIT;
