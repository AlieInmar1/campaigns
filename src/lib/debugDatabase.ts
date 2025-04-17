import { supabase } from './supabase';
import { checkDatabaseHealth, formatHealthCheckResults } from './databaseHealth';

/**
 * Debug function to check database tables and relationships
 */
export async function debugDatabaseTables() {
  console.group('Database Debug Information');

  try {
    // Run health check first
    const healthResults = await checkDatabaseHealth();
    console.log(formatHealthCheckResults(healthResults));

    // If health check passed, run additional debug queries
    if (healthResults.isHealthy) {
      // Sample provider data
      const { data: providers, error: provError } = await supabase
        .from('providers')
        .select(`
          provider_id,
          name,
          specialty,
          geographic_area,
          prescriptions:prescriptions(count)
        `)
        .limit(5);

      console.log('\nProvider Sample Data:', {
        data: providers,
        error: provError
      });

      // Sample medication data
      const { data: medications, error: medError } = await supabase
        .from('medications')
        .select(`
          id,
          name,
          category,
          prescriptions:prescriptions(count)
        `)
        .limit(5);

      console.log('\nMedication Sample Data:', {
        data: medications,
        error: medError
      });

      // Top prescribed medications using raw SQL
      const { data: topMeds, error: topMedError } = await supabase
        .rpc('get_top_prescribed_medications', { limit_count: 5 });

      console.log('\nTop Prescribed Medications:', {
        data: topMeds,
        error: topMedError
      });

      // Provider statistics using raw SQL
      const { data: providerStats, error: statsError } = await supabase
        .rpc('get_provider_specialty_stats');

      console.log('\nProvider Statistics by Specialty:', {
        data: providerStats,
        error: statsError
      });

      // Geographic distribution using raw SQL
      const { data: geoStats, error: geoError } = await supabase
        .rpc('get_provider_geographic_stats');

      console.log('\nProvider Geographic Distribution:', {
        data: geoStats,
        error: geoError
      });

      // Check for any recent database errors in RLS policies
      const { data: recentErrors, error: logError } = await supabase
        .from('_http_response')
        .select('*')
        .eq('status', 500)
        .order('created_at', { ascending: false })
        .limit(5);

      if (recentErrors?.length) {
        console.warn('\nRecent Database Errors:', {
          data: recentErrors,
          error: logError
        });
      }
    } else {
      console.warn('\nSkipping detailed debug queries due to health check failure');
    }

  } catch (error) {
    console.error('Error during database debug:', error);
  }

  console.groupEnd();
}

/**
 * Debug function to check specific provider data
 */
export async function debugProviderData(providerId: string) {
  console.group(`Provider Debug Information: ${providerId}`);

  try {
    // Get provider details
    const { data: provider, error: provError } = await supabase
      .from('providers')
      .select(`
        *,
        prescriptions:prescriptions(
          id,
          medication:medications(
            id,
            name,
            category
          )
        )
      `)
      .eq('provider_id', providerId)
      .single();

    console.log('Provider Details:', {
      data: provider,
      error: provError
    });

    // Get prescription statistics using raw SQL
    if (provider) {
      const { data: stats, error: statsError } = await supabase
        .rpc('get_provider_prescription_stats', { provider_id: providerId });

      console.log('Prescription Statistics:', {
        data: stats,
        error: statsError
      });
    }

  } catch (error) {
    console.error('Error during provider debug:', error);
  }

  console.groupEnd();
}
