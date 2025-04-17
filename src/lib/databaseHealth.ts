import { supabase } from './supabase';
import { PostgrestResponse } from '@supabase/supabase-js';

interface TableCounts {
  providers: number;
  medications: number;
  prescriptions: number;
}

interface HealthCheckResult {
  isHealthy: boolean;
  tableCounts: TableCounts;
  errors: string[];
  warnings: string[];
}

interface CountResponse {
  count: number | null;
}

/**
 * Check database health and data consistency
 */
export async function checkDatabaseHealth(): Promise<HealthCheckResult> {
  const result: HealthCheckResult = {
    isHealthy: true,
    tableCounts: {
      providers: 0,
      medications: 0,
      prescriptions: 0
    },
    errors: [],
    warnings: []
  };

  try {
    // Check table counts
    const { count: providerCount, error: provError } = await supabase
      .from('providers')
      .select('*', { count: 'exact', head: true }) as PostgrestResponse<CountResponse>;

    if (provError) {
      result.errors.push(`Error accessing providers table: ${provError.message}`);
      result.isHealthy = false;
    } else {
      result.tableCounts.providers = providerCount || 0;
      if (result.tableCounts.providers === 0) {
        result.warnings.push('No providers found in database');
      }
    }

    const { count: medCount, error: medError } = await supabase
      .from('medications')
      .select('*', { count: 'exact', head: true }) as PostgrestResponse<CountResponse>;

    if (medError) {
      result.errors.push(`Error accessing medications table: ${medError.message}`);
      result.isHealthy = false;
    } else {
      result.tableCounts.medications = medCount || 0;
      if (result.tableCounts.medications === 0) {
        result.warnings.push('No medications found in database');
      }
    }

    const { count: presCount, error: presError } = await supabase
      .from('prescriptions')
      .select('*', { count: 'exact', head: true }) as PostgrestResponse<CountResponse>;

    if (presError) {
      result.errors.push(`Error accessing prescriptions table: ${presError.message}`);
      result.isHealthy = false;
    } else {
      result.tableCounts.prescriptions = presCount || 0;
      if (result.tableCounts.prescriptions === 0) {
        result.warnings.push('No prescriptions found in database');
      }
    }

    // Check for invalid prescriptions
    const { data: invalidPrescriptions, error: invalidError } = await supabase
      .from('prescriptions')
      .select(`
        id,
        provider:providers!inner(provider_id),
        medication:medications!inner(id)
      `)
      .limit(1);

    if (invalidError) {
      result.errors.push(`Error checking prescription relationships: ${invalidError.message}`);
      result.isHealthy = false;
    }

    // Check feature flags
    const { data: featureFlags, error: flagError } = await supabase
      .from('feature_flags')
      .select('*')
      .eq('flag_name', 'use_patient_prescriptions_for_targeting')
      .single();

    if (flagError) {
      result.errors.push(`Error checking feature flags: ${flagError.message}`);
      result.isHealthy = false;
    } else if (!featureFlags?.enabled) {
      result.warnings.push('Patient prescriptions feature flag is not enabled');
    }

    // Check for providers without prescriptions
    const { count: providersWithoutPrescriptions, error: noPresError } = await supabase
      .from('providers')
      .select('*', { count: 'exact' })
      .not('provider_id', 'in', `(select distinct provider_id from prescriptions)`) as PostgrestResponse<CountResponse>;

    if (noPresError) {
      result.errors.push(`Error checking providers without prescriptions: ${noPresError.message}`);
    } else if (providersWithoutPrescriptions && providersWithoutPrescriptions > 0) {
      result.warnings.push(`Found ${providersWithoutPrescriptions} providers without any prescriptions`);
    }

    // Check for medications without prescriptions
    const { count: medsWithoutPrescriptions, error: noMedError } = await supabase
      .from('medications')
      .select('*', { count: 'exact' })
      .not('id', 'in', `(select distinct medication_id from prescriptions)`) as PostgrestResponse<CountResponse>;

    if (noMedError) {
      result.errors.push(`Error checking medications without prescriptions: ${noMedError.message}`);
    } else if (medsWithoutPrescriptions && medsWithoutPrescriptions > 0) {
      result.warnings.push(`Found ${medsWithoutPrescriptions} medications without any prescriptions`);
    }

  } catch (error) {
    result.errors.push(`Unexpected error during health check: ${error}`);
    result.isHealthy = false;
  }

  return result;
}

/**
 * Format health check results for display
 */
export function formatHealthCheckResults(results: HealthCheckResult): string {
  const lines: string[] = [
    'Database Health Check Results:',
    '----------------------------',
    '',
    'Table Counts:',
    `- Providers: ${results.tableCounts.providers.toLocaleString()}`,
    `- Medications: ${results.tableCounts.medications.toLocaleString()}`,
    `- Prescriptions: ${results.tableCounts.prescriptions.toLocaleString()}`,
    ''
  ];

  if (results.errors.length > 0) {
    lines.push('Errors:');
    results.errors.forEach(error => lines.push(`- ${error}`));
    lines.push('');
  }

  if (results.warnings.length > 0) {
    lines.push('Warnings:');
    results.warnings.forEach(warning => lines.push(`- ${warning}`));
    lines.push('');
  }

  lines.push(`Overall Status: ${results.isHealthy ? '✅ Healthy' : '❌ Issues Found'}`);

  return lines.join('\n');
}
