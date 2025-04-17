/**
 * Script to apply the missing columns fix directly using the Supabase client
 * This script doesn't require the DATABASE_URL environment variable
 */

import { supabase } from './src/lib/supabase.ts';

async function applyMissingColumnsFix() {
  console.log('Applying missing columns fix...');

  try {
    // Add name column to medications table if it doesn't exist
    console.log('Checking medications table for name column...');
    const { data: medicationsColumnCheck, error: medicationsColumnError } = await supabase
      .from('information_schema.columns')
      .select('column_name')
      .eq('table_name', 'medications')
      .eq('column_name', 'name');

    if (medicationsColumnError) {
      console.error('Error checking medications table:', medicationsColumnError);
      return;
    }

    if (!medicationsColumnCheck || medicationsColumnCheck.length === 0) {
      console.log('Adding name column to medications table...');
      
      // Execute raw SQL to add the column
      const { error: addColumnError } = await supabase.rpc('execute_sql', {
        sql_query: `
          ALTER TABLE medications ADD COLUMN name TEXT;
          
          -- Update name column with values from medication_name if it exists
          DO $$
          BEGIN
            IF EXISTS (
              SELECT FROM information_schema.columns 
              WHERE table_schema = 'public' 
              AND table_name = 'medications' 
              AND column_name = 'medication_name'
            ) THEN
              UPDATE medications SET name = medication_name WHERE medication_name IS NOT NULL;
            END IF;
          END $$;
          
          -- Create index on medications.name if it doesn't exist
          DO $$
          BEGIN
            IF NOT EXISTS (
              SELECT FROM pg_indexes 
              WHERE tablename = 'medications' 
              AND indexname = 'idx_medications_name'
            ) THEN
              CREATE INDEX idx_medications_name ON medications (name);
            END IF;
          END $$;
        `
      });

      if (addColumnError) {
        console.error('Error adding name column to medications table:', addColumnError);
      } else {
        console.log('Successfully added name column to medications table');
      }
    } else {
      console.log('name column already exists in medications table');
    }

    // Add geographic_area column to providers table if it doesn't exist
    console.log('Checking providers table for geographic_area column...');
    const { data: providersColumnCheck, error: providersColumnError } = await supabase
      .from('information_schema.columns')
      .select('column_name')
      .eq('table_name', 'providers')
      .eq('column_name', 'geographic_area');

    if (providersColumnError) {
      console.error('Error checking providers table:', providersColumnError);
      return;
    }

    if (!providersColumnCheck || providersColumnCheck.length === 0) {
      console.log('Adding geographic_area column to providers table...');
      
      // Execute raw SQL to add the column
      const { error: addColumnError } = await supabase.rpc('execute_sql', {
        sql_query: `
          ALTER TABLE providers ADD COLUMN geographic_area TEXT;
          
          -- Update geographic_area column with values from region if it exists
          DO $$
          BEGIN
            IF EXISTS (
              SELECT FROM information_schema.columns 
              WHERE table_schema = 'public' 
              AND table_name = 'providers' 
              AND column_name = 'region'
            ) THEN
              UPDATE providers SET geographic_area = region WHERE region IS NOT NULL;
            END IF;
          END $$;
          
          -- Create index on providers.geographic_area if it doesn't exist
          DO $$
          BEGIN
            IF NOT EXISTS (
              SELECT FROM pg_indexes 
              WHERE tablename = 'providers' 
              AND indexname = 'idx_providers_geographic_area'
            ) THEN
              CREATE INDEX idx_providers_geographic_area ON providers (geographic_area);
            END IF;
          END $$;
        `
      });

      if (addColumnError) {
        console.error('Error adding geographic_area column to providers table:', addColumnError);
      } else {
        console.log('Successfully added geographic_area column to providers table');
      }
    } else {
      console.log('geographic_area column already exists in providers table');
    }

    // Create script_lift_data table if it doesn't exist
    console.log('Checking if script_lift_data table exists...');
    const { data: scriptLiftTableCheck, error: scriptLiftTableError } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_name', 'script_lift_data');

    if (scriptLiftTableError) {
      console.error('Error checking script_lift_data table:', scriptLiftTableError);
      return;
    }

    if (!scriptLiftTableCheck || scriptLiftTableCheck.length === 0) {
      console.log('Creating script_lift_data table...');
      
      // Execute raw SQL to create the table
      const { error: createTableError } = await supabase.rpc('execute_sql', {
        sql_query: `
          CREATE TABLE IF NOT EXISTS script_lift_data (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
            baseline INTEGER NOT NULL,
            projected INTEGER NOT NULL,
            lift_percentage NUMERIC(5,2) NOT NULL,
            confidence_score INTEGER NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );
          
          -- Add sample data to script_lift_data if the table is empty
          INSERT INTO script_lift_data (campaign_id, baseline, projected, lift_percentage, confidence_score)
          SELECT 
            id as campaign_id,
            FLOOR(RANDOM() * 5000 + 1000)::INTEGER as baseline,
            FLOOR(RANDOM() * 8000 + 5000)::INTEGER as projected,
            (RANDOM() * 20 + 5)::NUMERIC(5,2) as lift_percentage,
            (RANDOM() * 30 + 65)::INTEGER as confidence_score
          FROM campaigns
          WHERE NOT EXISTS (SELECT 1 FROM script_lift_data LIMIT 1)
          LIMIT 10;
        `
      });

      if (createTableError) {
        console.error('Error creating script_lift_data table:', createTableError);
      } else {
        console.log('Successfully created script_lift_data table');
      }
    } else {
      console.log('script_lift_data table already exists');
    }

    // Ensure campaign_results table has the necessary structure
    console.log('Checking if campaign_results table exists...');
    const { data: campaignResultsTableCheck, error: campaignResultsTableError } = await supabase
      .from('information_schema.tables')
      .select('table_name')
      .eq('table_name', 'campaign_results');

    if (campaignResultsTableError) {
      console.error('Error checking campaign_results table:', campaignResultsTableError);
      return;
    }

    if (!campaignResultsTableCheck || campaignResultsTableCheck.length === 0) {
      console.log('Creating campaign_results table...');
      
      // Execute raw SQL to create the table
      const { error: createTableError } = await supabase.rpc('execute_sql', {
        sql_query: `
          CREATE TABLE IF NOT EXISTS campaign_results (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
            metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
            engagement_metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
            demographic_metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
            roi_metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
            prescription_metrics JSONB NOT NULL DEFAULT '{}'::JSONB,
            report_date DATE NOT NULL DEFAULT CURRENT_DATE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
          );
          
          -- Add sample data to campaign_results if the table is empty
          INSERT INTO campaign_results (
            campaign_id, 
            metrics, 
            engagement_metrics, 
            demographic_metrics, 
            roi_metrics, 
            prescription_metrics
          )
          SELECT 
            id as campaign_id,
            jsonb_build_object(
              'impressions', FLOOR(RANDOM() * 100000 + 50000),
              'clicks', FLOOR(RANDOM() * 5000 + 2500),
              'conversions', FLOOR(RANDOM() * 1000 + 500)
            ) as metrics,
            jsonb_build_object(
              'avg_time_on_page', FLOOR(RANDOM() * 60 + 30),
              'bounce_rate', FLOOR(RANDOM() * 40 + 20),
              'return_visits', FLOOR(RANDOM() * 100 + 50),
              'resource_downloads', FLOOR(RANDOM() * 50 + 20)
            ) as engagement_metrics,
            jsonb_build_object(
              'age_groups', jsonb_build_object(
                '25-34', FLOOR(RANDOM() * 20 + 10),
                '35-44', FLOOR(RANDOM() * 30 + 20),
                '45-54', FLOOR(RANDOM() * 30 + 20),
                '55-64', FLOOR(RANDOM() * 20 + 10),
                '65+', FLOOR(RANDOM() * 10 + 5)
              ),
              'genders', jsonb_build_object(
                'Male', FLOOR(RANDOM() * 60 + 40),
                'Female', FLOOR(RANDOM() * 60 + 40)
              )
            ) as demographic_metrics,
            jsonb_build_object(
              'total_campaign_cost', FLOOR(RANDOM() * 20000 + 10000),
              'roi_percentage', FLOOR(RANDOM() * 100 + 100),
              'estimated_revenue_impact', FLOOR(RANDOM() * 50000 + 20000),
              'cost_per_click', (RANDOM() * 30 + 10)::NUMERIC(10,2),
              'cost_per_conversion', (RANDOM() * 300 + 100)::NUMERIC(10,2),
              'cost_per_impression', (RANDOM() * 2 + 0.5)::NUMERIC(10,2),
              'lifetime_value_impact', FLOOR(RANDOM() * 100000 + 50000)
            ) as roi_metrics,
            jsonb_build_object(
              'new_prescriptions', FLOOR(RANDOM() * 100 + 50),
              'prescription_renewals', FLOOR(RANDOM() * 200 + 100),
              'market_share_change', (RANDOM() * 5 + 1)::NUMERIC(10,2),
              'patient_adherence_rate', FLOOR(RANDOM() * 30 + 50),
              'total_prescription_change', (RANDOM() * 20 + 5)::NUMERIC(10,2),
              'prescription_by_region', jsonb_build_object(
                'Northeast', FLOOR(RANDOM() * 40 + 20),
                'Southeast', FLOOR(RANDOM() * 30 + 15),
                'Midwest', FLOOR(RANDOM() * 25 + 10),
                'Southwest', FLOOR(RANDOM() * 20 + 10),
                'West', FLOOR(RANDOM() * 20 + 10)
              ),
              'prescription_by_specialty', jsonb_build_object(
                'Primary Care', FLOOR(RANDOM() * 50 + 30),
                'Cardiology', FLOOR(RANDOM() * 30 + 10),
                'Neurology', FLOOR(RANDOM() * 20 + 10),
                'Endocrinology', FLOOR(RANDOM() * 25 + 15),
                'Other', FLOOR(RANDOM() * 15 + 5)
              )
            ) as prescription_metrics
          FROM campaigns
          WHERE NOT EXISTS (SELECT 1 FROM campaign_results LIMIT 1)
          LIMIT 10;
        `
      });

      if (createTableError) {
        console.error('Error creating campaign_results table:', createTableError);
      } else {
        console.log('Successfully created campaign_results table');
      }
    } else {
      console.log('campaign_results table already exists');
    }

    console.log('Fix applied successfully!');
    console.log('You should now be able to access the ExploreDatabase component and Campaign Results without errors.');
  } catch (error) {
    console.error('Error applying fix:', error);
  }
}

// Run the fix
applyMissingColumnsFix();
