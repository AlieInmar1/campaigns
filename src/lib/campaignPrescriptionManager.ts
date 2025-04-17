import { supabase } from './supabase';
import { Campaign, Provider, Medication } from '../types';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';
import path from 'path';
import { getProvidersByFilter, enablePatientPrescriptionsFeature, ProviderFilter } from './providerDataService';

/**
 * Find targeted providers for a campaign based on its targeting criteria.
 * Returns the list of provider IDs that match the campaign targeting.
 * Uses the providerDataService to leverage actual patient prescription data.
 */
export const findTargetedProviders = async (campaign: Campaign): Promise<string[]> => {
  try {
    // Enable the patient prescriptions feature to use actual data
    await enablePatientPrescriptionsFeature();
    
    // Convert campaign targeting criteria to ProviderFilter format
    const filter: ProviderFilter = {
      // If there's a target medication ID, include it
      medicationIds: campaign.target_medication_id ? [campaign.target_medication_id] : [],
      
      // If targeting_metadata includes medication info, add it
      excludedMedicationIds: campaign.targeting_metadata?.excluded_medications || [],
      
      // Include specialty
      specialties: campaign.target_specialty ? [campaign.target_specialty] : [],
      
      // Include geographic area
      regions: campaign.target_geographic_area ? [campaign.target_geographic_area] : [],
      
      // Include prescribing volume from metadata
      prescribingVolume: campaign.targeting_metadata?.prescribing_volume || 'all',
      
      // Default to OR logic for broader reach
      useAndLogic: false
    };
    
    console.log('Finding targeted providers with filter:', JSON.stringify(filter, null, 2));
    
    // Get providers using the provider data service
    const providerIds = await getProvidersByFilter(filter);
    
    console.log(`Found ${providerIds.length} providers matching campaign criteria`);
    
    return providerIds;
  } catch (error) {
    console.error('Exception finding targeted providers:', error);
    
    // Fallback to direct query if the provider data service fails
    try {
      console.log('Falling back to direct query for providers');
      
      // Build the query based on campaign targeting
      let query = supabase.from('providers').select('id');
  
      // Apply specialty filter if specified
      if (campaign.target_specialty) {
        query = query.eq('specialty', campaign.target_specialty);
      }
  
      // Apply geographic area filter if specified
      if (campaign.target_geographic_area) {
        query = query.eq('geographic_area', campaign.target_geographic_area);
      }
  
      // Apply additional targeting criteria if specified
      if (campaign.targeting_metadata) {
        // Apply prescribing volume filter if specified
        if (campaign.targeting_metadata.prescribing_volume && 
            campaign.targeting_metadata.prescribing_volume !== 'all') {
          query = query.eq('prescribing_volume', campaign.targeting_metadata.prescribing_volume);
        }
      }
  
      // Execute the query
      const { data, error } = await query;
      
      if (error) {
        console.error('Error in fallback query for targeted providers:', error);
        return [];
      }
      
      // Extract just the provider IDs
      return data.map((provider: {id: string}) => provider.id);
    } catch (fallbackError) {
      console.error('Exception in fallback query for targeted providers:', fallbackError);
      return [];
    }
  }
};

/**
 * Write the list of affected providers to a file for tracking purposes.
 * File is saved to the logs directory with the campaign ID in the filename.
 */
export const writeProvidersToFile = async (
  campaign: Campaign, 
  providerIds: string[]
): Promise<boolean> => {
  try {
    // Create logs directory if it doesn't exist
    const logsDir = path.resolve(process.cwd(), 'logs');
    if (!fs.existsSync(logsDir)) {
      fs.mkdirSync(logsDir, { recursive: true });
    }
    
    // Create the filename with campaign ID
    const filename = path.join(
      logsDir, 
      `campaign_${campaign.id}_providers_${new Date().toISOString().split('T')[0]}.json`
    );
    
    // Create the file content
    const fileContent = JSON.stringify({
      campaign_id: campaign.id,
      campaign_name: campaign.name,
      target_specialty: campaign.target_specialty,
      target_geographic_area: campaign.target_geographic_area,
      target_medication_id: campaign.target_medication_id,
      date_range: `${campaign.start_date} to ${campaign.end_date}`,
      provider_count: providerIds.length,
      provider_ids: providerIds,
      generated_at: new Date().toISOString()
    }, null, 2);
    
    // Write the file
    fs.writeFileSync(filename, fileContent);
    
    console.log(`Saved targeted providers to ${filename}`);
    
    return true;
  } catch (error) {
    console.error('Error writing providers to file:', error);
    return false;
  }
};

/**
 * Generate prescription data for a campaign and save to the database.
 * This creates realistic prescription data for the campaign's targeted
 * medication and providers, during the campaign's date range.
 */
export const generatePrescriptionData = async (
  campaign: Campaign, 
  providerIds: string[]
): Promise<boolean> => {
  try {
    // Exit early if there are no providers
    if (!providerIds.length) {
      console.warn('No providers to generate prescriptions for');
      return false;
    }
    
    // Get the target medication
    const { data: medicationData, error: medicationError } = await supabase
      .from('medications')
      .select('*')
      .eq('id', campaign.target_medication_id)
      .single();
    
    if (medicationError) {
      console.error('Error fetching target medication:', medicationError);
      return false;
    }
    
    const targetMedication = medicationData as Medication;
    
    // Get competitor medications in the same category
    const { data: competitorData, error: competitorError } = await supabase
      .from('medications')
      .select('*')
      .eq('category', targetMedication.category)
      .neq('id', targetMedication.id)
      .limit(3); // Limit to 3 competitors
    
    if (competitorError) {
      console.error('Error fetching competitor medications:', competitorError);
      return false;
    }
    
    const competitorMedications = competitorData as Medication[];
    
    // Calculate date range for prescriptions
    const campaignStartDate = new Date(campaign.start_date);
    const campaignEndDate = new Date(campaign.end_date);
    
    // Create an array to hold all prescription records
    const prescriptionRecords = [];
    
    // For each provider, generate prescription data
    for (const providerId of providerIds) {
      // Get provider details
      const { data: providerData, error: providerError } = await supabase
        .from('providers')
        .select('*')
        .eq('id', providerId)
        .single();
      
      if (providerError) {
        console.warn(`Error fetching provider ${providerId}:`, providerError);
        continue;
      }
      
      const provider = providerData as Provider;
      
      // Get relevant conditions for this medication
      const { data: conditionData, error: conditionError } = await supabase
        .from('conditions')
        .select('*')
        .limit(2); // Just get a couple of conditions
      
      if (conditionError) {
        console.warn('Error fetching conditions:', conditionError);
        continue;
      }
      
      // Generate baseline prescription data for this provider (before campaign)
      const baselineStartDate = new Date(campaignStartDate);
      baselineStartDate.setMonth(baselineStartDate.getMonth() - 1); // 1 month before campaign
      
      // Generate prescription records during the baseline period 
      // (showing normal prescribing behavior)
      const baselineRecords = generateProviderPrescriptionRecords(
        providerId,
        provider.specialty,
        provider.geographic_area,
        targetMedication,
        competitorMedications,
        conditionData,
        baselineStartDate,
        campaignStartDate,
        false // Not during campaign
      );
      
      prescriptionRecords.push(...baselineRecords);
      
      // Generate prescription records during the campaign period
      // (showing increased target med prescribing)
      const campaignRecords = generateProviderPrescriptionRecords(
        providerId,
        provider.specialty,
        provider.geographic_area,
        targetMedication,
        competitorMedications,
        conditionData,
        campaignStartDate,
        campaignEndDate,
        true // During campaign
      );
      
      prescriptionRecords.push(...campaignRecords);
    }
    
    // Insert the prescription records in batches
    const batchSize = 100;
    for (let i = 0; i < prescriptionRecords.length; i += batchSize) {
      const batch = prescriptionRecords.slice(i, i + batchSize);
      
      const { error } = await supabase
        .from('prescriptions')
        .insert(batch);
      
      if (error) {
        console.error(`Error inserting batch ${i / batchSize + 1}:`, error);
      }
    }
    
    console.log(`Generated ${prescriptionRecords.length} prescription records for ${providerIds.length} providers`);
    
    return true;
  } catch (error) {
    console.error('Error generating prescription data:', error);
    return false;
  }
};

/**
 * Generate prescription records for a single provider during a specific date range
 */
const generateProviderPrescriptionRecords = (
  providerId: string,
  specialty: string,
  geographicArea: string,
  targetMedication: Medication,
  competitorMedications: Medication[],
  conditions: any[],
  startDate: Date,
  endDate: Date,
  duringCampaign: boolean
) => {
  const records = [];
  
  // Number of days in the period
  const daysDiff = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
  
  // Average number of prescriptions per day (randomized)
  const dailyPrescriptionRate = Math.random() * 2 + 0.5; // 0.5 to 2.5 prescriptions per day
  
  // Total prescriptions for the period
  const totalPrescriptions = Math.floor(daysDiff * dailyPrescriptionRate);
  
  // Distribution of medications
  // During campaign, prescribe target medication more often
  let targetMedProbability = duringCampaign ? 0.6 : 0.3; // 60% vs 30% baseline probability
  
  // Distribute remaining probability among competitors
  const competitorProbabilities = competitorMedications.map(() => 
    (1 - targetMedProbability) / competitorMedications.length
  );
  
  // Generate prescription dates spread over the period
  for (let i = 0; i < totalPrescriptions; i++) {
    // Random date in the range
    const days = Math.floor(Math.random() * daysDiff);
    const prescriptionDate = new Date(startDate);
    prescriptionDate.setDate(prescriptionDate.getDate() + days);
    
    // Determine which medication to prescribe based on probabilities
    let medication: Medication;
    const random = Math.random();
    
    if (random < targetMedProbability) {
      medication = targetMedication;
    } else {
      // Pick a competitor based on remaining probability distribution
      let cumulativeProbability = targetMedProbability;
      let competitorIndex = 0;
      
      for (let j = 0; j < competitorProbabilities.length; j++) {
        cumulativeProbability += competitorProbabilities[j];
        if (random < cumulativeProbability) {
          competitorIndex = j;
          break;
        }
      }
      
      medication = competitorMedications[competitorIndex] || competitorMedications[0];
    }
    
    // Random condition that would be treated with this medication
    const condition = conditions[Math.floor(Math.random() * conditions.length)];
    
    // Random prescription details
    const quantity = Math.floor(Math.random() * 60) + 30; // 30-90 units
    const daysSupply = Math.floor(Math.random() * 30) + 30; // 30-60 days
    const refills = Math.floor(Math.random() * 3); // 0-2 refills
    
    // Create prescription record
    records.push({
      id: uuidv4(),
      provider_id: providerId,
      medication_id: medication.id,
      condition_id: condition.id,
      prescription_location: geographicArea,
      fill_location: geographicArea, // Same as prescription location for simplicity
      prescription_date: prescriptionDate.toISOString().split('T')[0],
      quantity,
      days_supply: daysSupply,
      refills,
      notes: duringCampaign 
        ? 'Prescribed during active marketing campaign'
        : 'Baseline prescription before campaign',
      created_at: new Date().toISOString()
    });
  }
  
  return records;
};

/**
 * Handle the entire process of finding targeted providers, generating
 * prescription data, and saving to file when a campaign is saved.
 */
export const handleCampaignSave = async (campaign: Campaign): Promise<boolean> => {
  try {
    // Find providers targeted by this campaign
    const providerIds = await findTargetedProviders(campaign);
    
    if (!providerIds.length) {
      console.warn('No providers found matching campaign criteria');
      return false;
    }
    
    // Update campaign with targeted provider IDs
    if (!campaign.targeting_metadata) {
      campaign.targeting_metadata = {};
    }
    campaign.targeting_metadata.affected_providers = providerIds;
    
    // Save targeted providers to file for reference
    await writeProvidersToFile(campaign, providerIds);
    
    // Insert provider IDs into campaign_provider_targets table
    console.log(`Inserting ${providerIds.length} providers into campaign_provider_targets for campaign ${campaign.id}`);
    
    // Process providers in batches to avoid potential query size limits
    const batchSize = 100;
    for (let i = 0; i < providerIds.length; i += batchSize) {
      const batch = providerIds.slice(i, i + batchSize);
      
      // Create array of records to insert
      const records = batch.map(providerId => ({
        campaign_id: campaign.id,
        provider_id: providerId,
        targeting_reason: 'Matched targeting criteria',
        potential_lift_score: Math.random() * 5 + 1, // Random score between 1-6
        created_by: campaign.created_by,
        created_at: new Date().toISOString()
      }));
      
      // Insert records into campaign_provider_targets table
      const { error } = await supabase
        .from('campaign_provider_targets')
        .insert(records);
      
      if (error) {
        console.error('Error inserting campaign provider targets:', error);
      }
    }
    
    // Generate and save prescription data for these providers
    await generatePrescriptionData(campaign, providerIds);
    
    // Update campaign with new targeting_metadata
    await supabase
      .from('campaigns')
      .update({
        targeting_metadata: campaign.targeting_metadata
      })
      .eq('id', campaign.id);
    
    return true;
  } catch (error) {
    console.error('Error handling campaign save:', error);
    return false;
  }
};
