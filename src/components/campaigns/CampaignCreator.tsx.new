import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppDispatch, useAppSelector } from '../../hooks';
import { createCampaign } from '../../store/slices/campaignSlice';
import { fetchAllReferenceData } from '../../store/slices/referenceDataSlice';
import { generateAndStoreResults } from '../../store/slices/campaignResultsSlice';
import { addNotification } from '../../store/slices/uiSlice';
import { ChevronRight, ChevronLeft, Zap } from 'lucide-react';
import { cn } from '../../utils/cn';

// Custom hooks
import { useTargetingForm, TargetingState } from '../../hooks/useTargetingForm';

// Components
import { TargetingForm } from './targeting/TargetingForm';
import { EnhancedTargetingForm } from './targeting/EnhancedTargetingForm';
import { ProviderMatchSummary } from './targeting/ProviderMatchSummary';
import { CampaignReviewSummary } from './review/CampaignReviewSummary';
import { IdentityMatchingProcess, IdentityMatchProgress } from './identity/IdentityMatchingProcess';
import { CampaignSaveForm } from './save/CampaignSaveForm';
import { StepperProgress } from './common/StepperProgress';

/**
 * CampaignCreator component
 * Uses a wizard pattern to guide users through campaign creation
 */
export function CampaignCreator(): JSX.Element {
  const navigate = useNavigate();
  const dispatch = useAppDispatch();
  const { user } = useAppSelector(state => state.auth);
  
  // UI state with enhanced filtering toggle
  const [currentStep, setCurrentStep] = useState<number>(1);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [useEnhancedFiltering, setUseEnhancedFiltering] = useState<boolean>(true);
  
  // Reference data from store
  const medications = useAppSelector(state => {
    const refData = state.referenceData as { medications: any[] };
    return refData.medications || [];
  });
  
  const specialties = useAppSelector(state => {
    const refData = state.referenceData as { specialties: any[] };
    return refData.specialties || [];
  });
  
  const regions = useAppSelector(state => {
    const refData = state.referenceData as { geographicRegions: any[] };
    return refData.geographicRegions || [];
  });
  
  // Targeting and provider data (using our new hook)
  const {
    targeting,
    updateTargeting,
    providerCount,
    potentialReach,
    matchingProviderIds,
    isCalculating,
    error: targetingError,
    calculateProviderCounts,
    resetTargeting
  } = useTargetingForm();
  
  // Identity matching state
  const [isShowingIdentityMatching, setIsShowingIdentityMatching] = useState<boolean>(false);
  const [identityMatchResults, setIdentityMatchResults] = useState<{
    matchedProviders: number;
    totalProviders: number;
    matchPercentage: number;
  } | null>(null);
  
  // Step definitions for our wizard - different for enhanced filtering
  const standardSteps = [
    'Campaign Details',
    'Provider Criteria',
    'Geographic',
    'Review',
    'Complete'
  ];
  
  const enhancedSteps = [
    'Campaign Details',
    'Provider Targeting',
    'Review',
    'Complete'
  ];
  
  // Choose steps based on filtering mode
  const steps = useEnhancedFiltering ? enhancedSteps : standardSteps;
  
  // Load reference data on mount
  useEffect(() => {
    const loadReferenceData = async () => {
      try {
        await dispatch(fetchAllReferenceData());
      } catch (err) {
        console.error('Error loading reference data:', err);
        setError('Unable to load necessary data. Please try again later.');
      }
    };
    
    loadReferenceData();
  }, [dispatch]);
  
  // Handle identity matching completion
  const handleIdentityMatchingComplete = (results: {
    matchedProviders: number;
    totalProviders: number;
    matchPercentage: number;
  }) => {
    setIdentityMatchResults(results);
    setIsShowingIdentityMatching(false);
    setCurrentStep(useEnhancedFiltering ? 4 : 5); // Go to complete step based on mode
  };
  
  // Move to next step in the wizard
  const nextStep = () => {
    if (useEnhancedFiltering) {
      // Enhanced flow has fewer steps
      if (currentStep < 3) {
        setCurrentStep(currentStep + 1);
      } else if (currentStep === 3) {
        // Start identity matching in enhanced mode
        setIsShowingIdentityMatching(true);
      }
    } else {
      // Standard flow
      if (currentStep < 4) {
        setCurrentStep(currentStep + 1);
      } else if (currentStep === 4) {
        // Start identity matching
        setIsShowingIdentityMatching(true);
      }
    }
  };
  
  // Move to previous step
  const prevStep = () => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  };
  
  // Toggle between standard and enhanced filtering
  const toggleEnhancedFiltering = () => {
    // Reset to step 1 when toggling modes
    setCurrentStep(1);
    setUseEnhancedFiltering(!useEnhancedFiltering);
  };
  
  // Handle final campaign submission
  const submitCampaign = async (targetMedicationId: string, isScriptLiftEnabled: boolean) => {
    if (!targeting.name) {
      setError('Please provide a campaign name.');
      return;
    }
    
    if ((!targeting.medicationCategory && targeting.medications.length === 0) || 
        targeting.specialties.length === 0) {
      setError('Please select at least a medication category or specific medications, and at least one specialty.');
      return;
    }
    
    if (!user?.id) {
      setError('User authentication required. Please log in again.');
      return;
    }
    
    if (!identityMatchResults) {
      setError('Identity matching must be completed before creating a campaign.');
      return;
    }
    
    try {
      setIsSubmitting(true);
      setError(null);
      
      // Find target specialty and region if selected
      const targetSpecialty = targeting.specialties.length > 0
        ? specialties.find(spec => spec.id === targeting.specialties[0])?.name
        : undefined;
        
      const targetRegion = targeting.regions.length > 0
        ? regions.find(reg => reg.id === targeting.regions[0])?.name
        : undefined;
      
      // Create the campaign object
      const campaignData: any = {
        name: targeting.name,
        status: 'draft',
        created_at: new Date().toISOString(),
        created_by: user.id,
        targeting_logic: 'and',
        target_medication_id: targetMedicationId,
        script_lift_enabled: isScriptLiftEnabled
      };
      
      // Add optional targeting fields if available
      if (targetSpecialty) {
        campaignData.target_specialty = targetSpecialty;
      }
      
      if (targetRegion) {
        campaignData.target_geographic_area = targetRegion;
      }
      
      // Store targeting information in metadata
      campaignData.targeting_metadata = {
        medicationCategory: targeting.medicationCategory,
        medications: targeting.medications,
        excluded_medications: targeting.excludedMedications,
        specialties: targeting.specialties,
        regions: targeting.regions,
        prescribing_volume: targeting.prescribingVolume,
        timeframe: targeting.timeframe,
        provider_count: identityMatchResults.matchedProviders,
        potential_reach: identityMatchResults.matchedProviders * 250,
        enhanced_filtering_used: useEnhancedFiltering
      };
      
      // Store the matching provider IDs
      // Use enhancedFilteredProviders if available
      const providerIdsToUse = targeting.enhancedFilteredProviders || matchingProviderIds;
      campaignData.provider_ids = providerIdsToUse;
      
      console.log(`Saving campaign with ${providerIdsToUse.length} targeted providers`);
      
      // Create the campaign
      console.log('Creating campaign:', campaignData);
      const result = await dispatch(createCampaign(campaignData));
      
      // Check for errors
      if (result.type.endsWith('/rejected')) {
        console.error('Campaign creation failed:', result.payload);
        setError(`Campaign creation failed: ${result.payload || 'Unknown error'}`);
        setIsSubmitting(false);
        return;
      }
      
      // Success notification
      dispatch(addNotification({
        type: 'success',
        message: 'Campaign created successfully!'
      }));
      
      // Store ID for highlighting in list
      if (result.payload && typeof result.payload === 'object' && 'id' in result.payload) {
        const campaignId = String(result.payload.id);
        localStorage.setItem('newCampaignId', campaignId);
        
        // Generate results data
        try {
          console.log('Generating results for new campaign:', campaignId);
          const createdCampaign = result.payload as any;
          await dispatch(generateAndStoreResults({
            campaign: createdCampaign,
            medications: medications
          }));
        } catch (error) {
          console.error('Error generating campaign results:', error);
        }
      }
      
      // Navigate to campaigns list
      navigate('/campaigns');
    } catch (error: any) {
      console.error('Error creating campaign:', error);
      
      // Provide more specific error message if possible
      const errorMessage = error.message || 'Failed to create campaign';
      
      if (error.message?.includes('400')) {
        setError('Bad request: The campaign data format is incorrect. Please check required fields.');
      } else if (error.message?.includes('401')) {
        setError('Authentication error: Please log in again.');
      } else if (error.message?.includes('403')) {
        setError('Permission denied: You do not have permission to create campaigns.');
      } else if (error.message?.includes('409')) {
        setError('Conflict: A campaign with this name may already exist.');
      } else if (error.message?.includes('500')) {
        setError('Server error: There was a problem on the server. Please try again later.');
      } else {
        setError(`Failed to create campaign: ${errorMessage}`);
      }
    } finally {
      setIsSubmitting(false);
    }
  };
  
  return (
    <div className="max-w-4xl mx-auto p-6 bg-white rounded-lg shadow">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-semibold">Create New Campaign</h2>
        
        {/* Enhanced Filtering Toggle */}
        <div className="inline-flex items-center">
          <button
            onClick={toggleEnhancedFiltering}
            className={cn(
              "inline-flex items-center px-3 py-1.5 text-sm font-medium rounded-md",
              useEnhancedFiltering 
                ? "bg-primary-50 text-primary-700 border border-primary-200" 
                : "bg-gray-100 text-gray-700 border border-gray-200 hover:bg-gray-200"
            )}
          >
            <Zap 
              size={16} 
              className={cn(
                "mr-1.5",
                useEnhancedFiltering ? "text-primary-600" : "text-gray-500"
              )} 
            />
            {useEnhancedFiltering ? "Using Enhanced Filtering" : "Use Enhanced Filtering"}
          </button>
        </div>
      </div>
      
      {/* Progress steps */}
      <StepperProgress 
        steps={steps}
        currentStep={currentStep}
        className="mb-8"
      />
      
      {/* Error message */}
      {(error || targetingError) && (
        <div className="mb-4 p-3 bg-red-50 rounded-lg border border-red-200 text-red-700">
          {error || targetingError}
        </div>
      )}
      
      {/* Provider count summary - visible on all steps */}
      <ProviderMatchSummary
        providerCount={providerCount}
        potentialReach={potentialReach}
        isCalculating={isCalculating}
        error={targetingError}
      />
      
      {/* Main content area - render different components based on mode and step */}
      <div className="mb-6">
        {/* Enhanced mode */}
        {useEnhancedFiltering && (
          <>
            {/* Step 1: Campaign Details */}
            {currentStep === 1 && (
              <EnhancedTargetingForm
                targeting={targeting}
                updateTargeting={updateTargeting}
                step={1}
              />
            )}
            
            {/* Step 2: Enhanced Provider Targeting */}
            {currentStep === 2 && (
              <EnhancedTargetingForm
                targeting={targeting}
                updateTargeting={updateTargeting}
                step={2}
              />
            )}
            
            {/* Step 3: Campaign Review */}
            {currentStep === 3 && (
              <CampaignReviewSummary 
                targeting={targeting}
                medicationOptions={medications}
                specialtyOptions={specialties}
                regionOptions={regions}
              />
            )}
            
            {/* Step 4: Complete Campaign */}
            {currentStep === 4 && (
              <CampaignSaveForm
                targeting={targeting}
                providerCount={providerCount}
                identityMatchResults={identityMatchResults}
                medicationOptions={medications}
                onSubmit={submitCampaign}
                isSubmitting={isSubmitting}
                error={error}
              />
            )}
          </>
        )}
        
        {/* Standard mode */}
        {!useEnhancedFiltering && (
          <>
            {/* Step 1-3: Standard Targeting Form */}
            {currentStep <= 3 && (
              <TargetingForm
                targeting={targeting}
                updateTargeting={updateTargeting}
                step={currentStep}
              />
            )}
            
            {/* Step 4: Campaign Review */}
            {currentStep === 4 && (
              <CampaignReviewSummary 
                targeting={targeting}
                medicationOptions={medications}
                specialtyOptions={specialties}
                regionOptions={regions}
              />
            )}
            
            {/* Step 5: Complete Campaign */}
            {currentStep === 5 && (
              <CampaignSaveForm
                targeting={targeting}
                providerCount={providerCount}
                identityMatchResults={identityMatchResults}
                medicationOptions={medications}
                onSubmit={submitCampaign}
                isSubmitting={isSubmitting}
                error={error}
              />
            )}
          </>
        )}
      </div>
      
      {/* Identity matching process overlay */}
      {isShowingIdentityMatching && (
        <IdentityMatchingProcess
          providerCount={providerCount}
          onMatchingComplete={handleIdentityMatchingComplete}
        />
      )}
      
      {/* Navigation buttons */}
      {!isShowingIdentityMatching && currentStep !== (useEnhancedFiltering ? 4 : 5) && (
        <div className="flex justify-between mt-8">
          {currentStep > 1 ? (
            <button
              type="button"
              onClick={prevStep}
              className="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
            >
              <ChevronLeft className="mr-2 h-4 w-4" />
              Previous
            </button>
          ) : (
            <div></div>
          )}
          
          <button
            type="button"
            onClick={nextStep}
            disabled={isCalculating}
            className={cn(
              "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500",
              isCalculating && "opacity-70 cursor-not-allowed"
            )}
          >
            {isCalculating ? (
              <>
                Processing...
              </>
            ) : (useEnhancedFiltering && currentStep === 3) || (!useEnhancedFiltering && currentStep === 4) ? (
              <>
                Run Identity Matching
                <ChevronRight className="ml-2 h-4 w-4" />
              </>
            ) : (
              <>
                Next Step
                <ChevronRight className="ml-2 h-4 w-4" />
              </>
            )}
          </button>
        </div>
      )}
    </div>
  );
}
