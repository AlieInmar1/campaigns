import { Campaign } from '../types';
import { supabase } from './supabase';
import { generateCampaignPrescriptionData } from './prescriptionDataGenerator';
import { handleCampaignSave } from './campaignPrescriptionManager';

/**
 * Updates a campaign's status based on its date range (SYNCHRONOUS version for Redux)
 * - If start_date is in the future -> "pending"
 * - If current date is within start_date and end_date -> "in progress" (was "active")
 * - If current date is after end_date -> "completed"
 * - Preserves "draft" status (doesn't auto-activate drafts)
 * - Preserves "sample" status for sample campaigns
 * - Returns the updated campaign object
 */
export const updateCampaignStatus = (campaign: Campaign): Campaign => {
  // Skip status update if campaign is in draft mode
  if (!campaign || campaign.status === 'draft') {
    return campaign;
  }
  
  // Skip status update for sample campaigns to preserve their status
  if (campaign.is_sample) {
    return campaign;
  }
  
  const now = new Date();
  const startDate = campaign.start_date ? new Date(campaign.start_date) : null;
  const endDate = campaign.end_date ? new Date(campaign.end_date) : null;
  
  // Clone campaign to avoid mutating the original
  const updatedCampaign = { ...campaign };
  
  // Campaign has both start and end date
  if (startDate && endDate) {
    if (startDate > now) {
      updatedCampaign.status = 'pending';
    } else if (now >= startDate && now <= endDate) {
      updatedCampaign.status = 'in_progress';
    } else if (now > endDate) {
      updatedCampaign.status = 'completed';
    }
  }
  // Campaign has only start date (indefinite end)
  else if (startDate && !endDate) {
    if (startDate > now) {
      updatedCampaign.status = 'pending';
    } else if (now >= startDate) {
      updatedCampaign.status = 'in_progress';
    }
  }
  // Campaign has only end date (already running)
  else if (!startDate && endDate) {
    if (now <= endDate) {
      updatedCampaign.status = 'in_progress';
    } else {
      updatedCampaign.status = 'completed';
    }
  }
  
  return updatedCampaign;
};

/**
 * Process a list of campaigns and update their statuses based on date ranges (SYNCHRONOUS for Redux)
 */
export const updateCampaignStatuses = (campaigns: Campaign[]): Campaign[] => {
  if (!campaigns || !Array.isArray(campaigns)) {
    return [];
  }
  
  return campaigns.map(updateCampaignStatus);
};

/**
 * Updates a campaign's status based on its date range WITH side effects (ASYNC version)
 * This handles database updates and prescription data generation
 */
export const updateCampaignStatusWithSideEffects = async (campaign: Campaign): Promise<Campaign> => {
  // First get the updated status without side effects
  const updatedCampaign = updateCampaignStatus(campaign);
  
  // Skip if nothing changed
  if (updatedCampaign.status === campaign.status) {
    return updatedCampaign;
  }
  
  // Store previous status to detect changes
  const previousStatus = campaign.status;
  
  try {
    // If status has changed to active, generate prescription data
    if (previousStatus !== 'active' && updatedCampaign.status === 'active') {
      // Use our new comprehensive function that:
      // 1. Finds targeted providers
      // 2. Writes them to a file for tracking
      // 3. Generates prescription data in the regular prescriptions table
      await handleCampaignSave(updatedCampaign);
    }
    
    // Update campaign status in database
    await supabase
      .from('campaigns')
      .update({ status: updatedCampaign.status })
      .eq('id', updatedCampaign.id);
      
    return updatedCampaign;
  } catch (error) {
    console.error('Error updating campaign with side effects:', error);
    return updatedCampaign; // Return the updated campaign even if side effects fail
  }
};

/**
 * Process a list of campaigns and update their statuses with side effects (ASYNC)
 */
export const updateCampaignStatusesWithSideEffects = async (campaigns: Campaign[]): Promise<Campaign[]> => {
  if (!campaigns || !Array.isArray(campaigns)) {
    return [];
  }
  
  // Process all campaigns in parallel
  const results = await Promise.all(
    campaigns.map(campaign => updateCampaignStatusWithSideEffects(campaign))
  );
  
  return results;
};
