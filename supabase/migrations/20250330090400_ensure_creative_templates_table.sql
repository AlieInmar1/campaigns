-- Migration: Ensure Creative Templates Table
-- Creates and populates creative_templates table if it doesn't exist
-- This fixes the 404 error: "Failed to load resource: the server responded with a status of 404 ()"

BEGIN;

-- Check if creative_templates table exists
DO $$
DECLARE
  table_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public'
    AND table_name = 'creative_templates'
  ) INTO table_exists;

  IF table_exists THEN
    RAISE NOTICE 'creative_templates table exists';
  ELSE
    RAISE NOTICE 'creative_templates table does not exist - creating it now';
    
    -- Create the creative_templates table
    CREATE TABLE public.creative_templates (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      description TEXT,
      template_type VARCHAR(50) NOT NULL,
      template_data JSONB NOT NULL DEFAULT '{}'::jsonb,
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
    );
    
    -- Insert sample creative templates
    INSERT INTO public.creative_templates (name, description, template_type, template_data, is_active)
    VALUES
      -- Display/Banner Templates
      ('Standard Banner - Primary', 'Standard banner with primary brand styling', 'display', 
        jsonb_build_object(
          'width', 728,
          'height', 90,
          'background_color', '#f8f9fa',
          'border_color', '#0056b3',
          'text_color', '#212529',
          'cta_color', '#007bff',
          'cta_text', 'Learn More',
          'headline_options', jsonb_build_array('Improve Patient Outcomes', 'Discover Clinical Benefits', 'New Treatment Option')
        ), 
        TRUE
      ),
      
      ('Sidebar Banner - Primary', 'Sidebar/Rectangle banner with primary brand styling', 'display', 
        jsonb_build_object(
          'width', 300,
          'height', 250,
          'background_color', '#f8f9fa',
          'border_color', '#0056b3',
          'text_color', '#212529',
          'cta_color', '#007bff',
          'cta_text', 'Learn More',
          'headline_options', jsonb_build_array('Improve Patient Outcomes', 'Discover Clinical Benefits', 'New Treatment Option')
        ), 
        TRUE
      ),
      
      ('Animated Banner', 'Animated banner with sliding panels', 'display', 
        jsonb_build_object(
          'width', 728,
          'height', 90,
          'background_color', '#ffffff',
          'border_color', '#17a2b8',
          'text_color', '#212529',
          'cta_color', '#17a2b8',
          'cta_text', 'See How',
          'animation_type', 'slide',
          'headline_options', jsonb_build_array('Better Outcomes Start Here', 'Patient Relief With Fewer Side Effects', 'Clinically Proven Results')
        ), 
        TRUE
      ),
      
      -- Email Templates
      ('Monthly Newsletter', 'Monthly newsletter template with latest updates', 'email', 
        jsonb_build_object(
          'subject_line_options', jsonb_build_array(
            '[Month] Clinical Updates for [Specialty]',
            'Latest Research: [Product] Clinical Outcomes',
            'New Data on [Condition] Treatment Options'
          ),
          'header_image', 'header-clinical.jpg',
          'sections', jsonb_build_array(
            'featured_article',
            'clinical_research',
            'patient_resources',
            'upcoming_events'
          ),
          'footer_text', 'This email was sent to {{email}}. To unsubscribe, click here.'
        ), 
        TRUE
      ),
      
      ('Product Announcement', 'New product or indication announcement template', 'email', 
        jsonb_build_object(
          'subject_line_options', jsonb_build_array(
            'Introducing: A New Option for [Condition] Patients',
            'New Treatment Option for [Condition]',
            'Just Approved: [Product] for [Condition]'
          ),
          'header_image', 'product-announcement.jpg',
          'sections', jsonb_build_array(
            'product_introduction',
            'clinical_highlights',
            'patient_support',
            'prescribing_information'
          ),
          'footer_text', 'This email was sent to {{email}}. To unsubscribe, click here.'
        ), 
        TRUE
      ),
      
      ('Educational Series', 'Educational series on disease state or treatment', 'email', 
        jsonb_build_object(
          'subject_line_options', jsonb_build_array(
            'Understanding [Condition]: Part {{part_number}}',
            '[Condition] Management: Key Considerations',
            'Clinical Insights: [Condition] Treatment Approaches'
          ),
          'header_image', 'education-series.jpg',
          'sections', jsonb_build_array(
            'educational_content',
            'expert_insights',
            'patient_case_study',
            'additional_resources'
          ),
          'footer_text', 'This email was sent to {{email}}. To unsubscribe, click here.'
        ), 
        TRUE
      ),
      
      -- Social Media Templates
      ('LinkedIn Post', 'Professional LinkedIn post template', 'social', 
        jsonb_build_object(
          'platform', 'linkedin',
          'image_dimensions', jsonb_build_object('width', 1200, 'height', 627),
          'headline_options', jsonb_build_array(
            'New Research: [Finding] in [Journal]',
            'Clinical Insights: [Topic] for Healthcare Professionals',
            'Join the Conversation on [Topic]'
          ),
          'character_limit', 3000,
          'hashtag_options', jsonb_build_array('#MedicalInnovation', '#ClinicalResearch', '#PatientCare')
        ), 
        TRUE
      ),
      
      ('Twitter Post', 'Concise Twitter post template', 'social', 
        jsonb_build_object(
          'platform', 'twitter',
          'image_dimensions', jsonb_build_object('width', 1200, 'height', 675),
          'headline_options', jsonb_build_array(
            'New data on [Product] shows [Benefit]',
            'Just published: [Finding] for patients with [Condition]',
            'HCPs: Learn about [Topic] in our latest [Resource]'
          ),
          'character_limit', 280,
          'hashtag_options', jsonb_build_array('#MedicalInnovation', '#ClinicalResearch', '#HCP')
        ), 
        TRUE
      ),
      
      ('Instagram Post', 'Visual Instagram post template', 'social', 
        jsonb_build_object(
          'platform', 'instagram',
          'image_dimensions', jsonb_build_object('width', 1080, 'height', 1080),
          'headline_options', jsonb_build_array(
            'Transforming patient care through innovation',
            'Supporting healthcare professionals with new resources',
            'Advancing treatment options for [Condition]'
          ),
          'character_limit', 2200,
          'hashtag_options', jsonb_build_array('#MedicalInnovation', '#PatientCare', '#Healthcare')
        ), 
        TRUE
      ),
      
      -- Educational Resource Templates
      ('Clinical Summary', 'Clinical trial or study summary template', 'resource', 
        jsonb_build_object(
          'document_type', 'pdf',
          'sections', jsonb_build_array(
            'study_overview',
            'methodology',
            'key_findings',
            'clinical_implications',
            'safety_profile',
            'references'
          ),
          'headline_options', jsonb_build_array(
            '[Study Name]: Key Findings and Clinical Implications',
            'Clinical Summary: [Product] in [Condition]',
            'New Data: [Product] Efficacy and Safety'
          )
        ), 
        TRUE
      ),
      
      ('Patient Education Brochure', 'Patient-focused educational material template', 'resource', 
        jsonb_build_object(
          'document_type', 'pdf',
          'sections', jsonb_build_array(
            'condition_overview',
            'treatment_options',
            'managing_symptoms',
            'patient_resources',
            'support_programs'
          ),
          'headline_options', jsonb_build_array(
            'Living With [Condition]: A Patient Guide',
            'Understanding Your Treatment Options for [Condition]',
            'Managing [Condition]: Information for Patients'
          )
        ), 
        TRUE
      ),
      
      ('Dosing Guide', 'Product dosing and administration guide template', 'resource', 
        jsonb_build_object(
          'document_type', 'pdf',
          'sections', jsonb_build_array(
            'dosing_information',
            'administration_guidelines',
            'patient_types',
            'monitoring_recommendations',
            'safety_information'
          ),
          'headline_options', jsonb_build_array(
            '[Product] Dosing and Administration Guide',
            'Quick Reference: [Product] Dosing',
            'Prescriber Guide: [Product] Administration'
          )
        ), 
        TRUE
      );
  END IF;
END $$;

-- Add creative_templates_id to campaigns table if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'campaigns' 
    AND column_name = 'creative_template_id'
  ) THEN
    ALTER TABLE public.campaigns 
    ADD COLUMN creative_template_id UUID REFERENCES public.creative_templates(id);
    
    RAISE NOTICE 'Added creative_template_id column to campaigns table';
  ELSE
    RAISE NOTICE 'creative_template_id column already exists in campaigns table';
  END IF;
END $$;

-- Check if we have any sample campaigns that need template assignments
DO $$
DECLARE
  template_id UUID;
  campaign_rec RECORD;
  campaign_count INTEGER := 0;
BEGIN
  -- Get a default template ID to use
  SELECT id INTO template_id 
  FROM public.creative_templates 
  WHERE template_type = 'display' 
  LIMIT 1;
  
  -- Update campaigns that don't have a template assigned
  IF template_id IS NOT NULL THEN
    FOR campaign_rec IN 
      SELECT id FROM public.campaigns 
      WHERE is_sample = TRUE 
      AND (creative_template_id IS NULL)
    LOOP
      UPDATE public.campaigns 
      SET creative_template_id = template_id 
      WHERE id = campaign_rec.id;
      
      campaign_count := campaign_count + 1;
    END LOOP;
    
    RAISE NOTICE 'Assigned creative templates to % sample campaigns', campaign_count;
  END IF;
END $$;

COMMIT;
