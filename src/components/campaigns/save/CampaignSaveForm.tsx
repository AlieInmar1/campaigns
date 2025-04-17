import React, { useState } from 'react';
import { Zap } from 'lucide-react';
import { Button } from '../../ui/Button';
import { Select } from '../../ui/Select';
import { cn } from '../../../utils/cn';
import { TargetingState } from '../../../hooks/useTargetingForm';

interface CampaignSaveFormProps {
  targeting: TargetingState;
  providerCount: number | null;
  identityMatchResults: {
    matchedProviders: number;
    totalProviders: number;
    matchPercentage: number;
  } | null;
  medicationOptions: { id: string; name: string; category: string }[];
  onSubmit: (targetMedicationId: string, isScriptLiftEnabled: boolean) => Promise<void>;
  isSubmitting: boolean;
  error: string | null;
  className?: string;
}

/**
 * Form for finalizing and saving a campaign
 */
export function CampaignSaveForm({
  targeting,
  providerCount,
  identityMatchResults,
  medicationOptions,
  onSubmit,
  isSubmitting,
  error,
  className = '',
}: CampaignSaveFormProps) {
  const [selectedMedicationId, setSelectedMedicationId] = useState<string>('');
  const [enableScriptLift, setEnableScriptLift] = useState<boolean>(true);
  
  // Get available medications based on targeting
  const availableMedications = targeting.medications.length > 0
    ? medicationOptions.filter(med => targeting.medications.includes(med.id))
    : targeting.medicationCategory
      ? medicationOptions.filter(med => med.category === targeting.medicationCategory)
      : medicationOptions;
  
  // Default to first medication if none selected and list not empty
  React.useEffect(() => {
    if (!selectedMedicationId && availableMedications.length > 0) {
      setSelectedMedicationId(availableMedications[0].id);
    }
  }, [selectedMedicationId, availableMedications]);
  
  // Handle form submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!selectedMedicationId) {
      return; // Cannot submit without a medication
    }
    
    await onSubmit(selectedMedicationId, enableScriptLift);
  };
  
  return (
    <div className={`animate-fadeIn ${className}`}>
      <h3 className="text-lg font-semibold text-gray-800 mb-4">
        <Zap className="inline-block mr-2 text-primary-500" size={20} />
        Finalize Campaign
      </h3>
      
      {/* Provider match summary */}
      {identityMatchResults && (
        <div className="mb-6 p-4 bg-green-50 rounded-lg border border-green-100">
          <div className="flex justify-between items-center mb-2">
            <h4 className="text-sm font-semibold text-green-800">Provider Match Summary</h4>
            <span className="bg-green-100 text-green-800 text-xs font-medium px-2.5 py-0.5 rounded-full">
              {identityMatchResults.matchPercentage}% Match Rate
            </span>
          </div>
          
          <p className="text-sm text-green-700 mb-3">
            Your campaign is ready to target{' '}
            <span className="font-semibold">{identityMatchResults.matchedProviders.toLocaleString()}</span>{' '}
            providers with an estimated patient reach of{' '}
            <span className="font-semibold">{(identityMatchResults.matchedProviders * 250).toLocaleString()}</span>.
          </p>
        </div>
      )}
      
      {error && (
        <div className="mb-4 p-3 bg-red-50 rounded-lg border border-red-200 text-red-700">
          {error}
        </div>
      )}
      
      <form onSubmit={handleSubmit}>
        <div className="space-y-4 mb-6">
          {/* Target medication selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Select Primary Target Medication for Script Lift
            </label>
            {availableMedications.length === 0 ? (
              <div className="p-4 text-center text-gray-500 border border-gray-300 rounded-md">
                No medications available based on your targeting criteria
              </div>
            ) : (
              <Select
                options={[
                  { value: '', label: 'Select a medication' },
                  ...availableMedications.map(medication => ({
                    value: medication.id,
                    label: `${medication.name} (${medication.category})`
                  }))
                ]}
                value={selectedMedicationId}
                onChange={(value: string) => setSelectedMedicationId(value)}
                className="w-full"
              />
            )}
          </div>
          
          {/* Script lift toggle */}
          <div className="flex items-center">
            <input
              id="enable-script-lift"
              name="enableScriptLift"
              type="checkbox"
              checked={enableScriptLift}
              onChange={(e) => setEnableScriptLift(e.target.checked)}
              className="h-4 w-4 text-primary-600 focus:ring-primary-500 border-gray-300 rounded"
            />
            <label htmlFor="enable-script-lift" className="ml-2 block text-sm text-gray-900">
              Enable Script Lift Analysis
            </label>
          </div>
          
          <div className="text-xs text-gray-500 ml-6">
            Script Lift Analysis helps measure the effectiveness of your campaign by tracking prescription changes over time.
          </div>
        </div>
        
        {/* Submit button */}
        <div className="flex justify-end">
          <Button
            type="submit"
            variant="default"
            disabled={isSubmitting || !selectedMedicationId || availableMedications.length === 0}
            className="inline-flex items-center"
          >
            {isSubmitting ? (
              <>Processing...</>
            ) : (
              <>
                Create Campaign
                <Zap className="ml-2 h-4 w-4" />
              </>
            )}
          </Button>
        </div>
      </form>
    </div>
  );
}
