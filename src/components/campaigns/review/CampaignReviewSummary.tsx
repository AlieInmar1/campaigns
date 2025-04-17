import React from 'react';
import { Filter } from 'lucide-react';
import { TargetingState } from '../../../hooks/useTargetingForm';

interface CampaignReviewSummaryProps {
  targeting: TargetingState;
  medicationOptions: { id: string; name: string; category: string }[];
  specialtyOptions: { id: string; name: string }[];
  regionOptions: { id: string; name: string; type: string }[];
  className?: string;
}

/**
 * Component to display a summary of campaign targeting for review
 */
export function CampaignReviewSummary({
  targeting,
  medicationOptions,
  specialtyOptions,
  regionOptions,
  className = '',
}: CampaignReviewSummaryProps) {
  return (
    <div className={`animate-fadeIn ${className}`}>
      <h3 className="text-lg font-semibold text-gray-800 mb-4">
        <Filter className="inline-block mr-2 text-primary-500" size={20} />
        Review Campaign Settings
      </h3>
      
      <div className="space-y-4">
        <div className="bg-gray-50 rounded-lg p-4 border border-gray-200">
          <h4 className="text-sm font-semibold text-gray-700 mb-2">Campaign Details</h4>
          <div className="flex justify-between text-sm mb-3">
            <span className="text-gray-600">Campaign Name:</span>
            <span className="font-medium text-gray-900">
              {targeting.name || 'Unnamed Campaign'}
            </span>
          </div>
        </div>
        
        <div className="bg-gray-50 rounded-lg p-4 border border-gray-200">
          <h4 className="text-sm font-semibold text-gray-700 mb-2">Targeting Criteria</h4>
          
          <div className="space-y-3">
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Medication Category:</span>
              <span className="font-medium text-gray-900" data-testid="selected-category">
                {targeting.medicationCategory || 'Any'}
              </span>
            </div>
            
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Included Medications:</span>
              <span className="font-medium text-gray-900">
                {targeting.medications.length > 0
                  ? targeting.medications.map(id => 
                      medicationOptions.find(m => m.id === id)?.name).join(', ')
                  : targeting.medicationCategory 
                      ? `All ${targeting.medicationCategory}` 
                      : 'All medications'}
              </span>
            </div>
            
            {targeting.excludedMedications.length > 0 && (
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Excluded Medications:</span>
                <span className="font-medium text-error-700">
                  {targeting.excludedMedications.map(id => 
                    medicationOptions.find(m => m.id === id)?.name).join(', ')}
                </span>
              </div>
            )}
            
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Provider Specialties:</span>
              <span className="font-medium text-gray-900">
                {targeting.specialties.length > 0
                  ? targeting.specialties.map(id => {
                      // Try to find from specialtyOptions first
                      const specialty = specialtyOptions.find(spec => spec.id === id);
                      // If not found, display the ID directly (since in our new structure, ID is the specialty name)
                      return specialty?.name || id;
                    }).join(', ')
                  : 'Any'}
              </span>
            </div>
            
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Geographic Regions:</span>
              <span className="font-medium text-gray-900">
                {targeting.regions.length > 0
                  ? targeting.regions.map(id => 
                      regionOptions.find(reg => reg.id === id)?.name).join(', ')
                  : 'Any'}
              </span>
            </div>
            
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Prescribing Volume:</span>
              <span className="font-medium text-gray-900">
                {targeting.prescribingVolume === 'all' 
                  ? 'All Volumes' 
                  : `${targeting.prescribingVolume.charAt(0).toUpperCase() + targeting.prescribingVolume.slice(1)} Volume`}
              </span>
            </div>
            
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Analysis Timeframe:</span>
              <span className="font-medium text-gray-900">
                {targeting.timeframe === 'last_month' 
                  ? 'Last Month' 
                  : targeting.timeframe === 'last_quarter'
                    ? 'Last Quarter'
                    : 'Last Year'}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
