import React, { useState, useEffect } from 'react';
import { Pill, Users, MapPin } from 'lucide-react';
import { Input } from '../../ui/Input';
import { cn } from '../../../utils/cn';
import { TargetingState } from '../../../hooks/useTargetingForm';
import { EnhancedProviderFilter } from '../../providers/EnhancedProviderFilter';

interface EnhancedTargetingFormProps {
  targeting: TargetingState;
  updateTargeting: (key: keyof TargetingState, value: any) => void;
  step: number;
  className?: string;
}

export function EnhancedTargetingForm({
  targeting,
  updateTargeting,
  step,
  className = '',
}: EnhancedTargetingFormProps) {
  const [estimatedProviderCount, setEstimatedProviderCount] = useState<number>(0);
  
  // Handle providers selected through the EnhancedProviderFilter
  const handleProvidersFiltered = (providers: any[]) => {
    // Extract provider IDs and update the targeting state
    const providerIds = providers.map(provider => provider.id);
    
    // This list will be used for campaign targeting
    console.log(`Selected ${providerIds.length} providers through enhanced filtering`);
    
    // We store this in a special key that doesn't exist in the original TargetingState
    // This will be handled specially in the form submission
    updateTargeting('enhancedFilteredProviders' as any, providerIds);
  };
  
  // Handle estimated count change
  const handleFilterCountChange = (count: number) => {
    setEstimatedProviderCount(count);
    // Update potential reach calculation (250 patients per provider)
    updateTargeting('potentialReach' as any, count * 250);
  };

  // Render different form sections based on current step
  if (step === 1) {
    return (
      <div className={`animate-fadeIn ${className}`}>
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          Campaign Details
        </h3>
        
        <div className="space-y-4 mb-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Campaign Name
            </label>
            <Input
              type="text"
              id="name"
              placeholder="Enter campaign name"
              value={targeting.name}
              onChange={(e) => updateTargeting('name', e.target.value)}
              fullWidth
            />
          </div>
        </div>
      </div>
    );
  }
  
  if (step === 2) {
    // Use our new enhanced provider filter component here
    return (
      <div className={`animate-fadeIn ${className}`}>
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          <Users className="inline-block mr-2 text-primary-500" size={20} />
          Enhanced Provider Targeting
        </h3>
        
        <div className="mb-4 p-3 bg-blue-50 border border-blue-100 rounded-md text-blue-800 text-sm">
          <strong>New!</strong> Our enhanced provider targeting system now allows you to filter providers based on 
          actual prescription data, specialty, medications, and geographic regions - all in one place.
        </div>
        
        <EnhancedProviderFilter
          onFilterApplied={handleProvidersFiltered}
          onFilterCountChange={handleFilterCountChange}
          defaultSpecialties={targeting.specialties}
        />
        
        <div className="mt-4 p-4 bg-gray-50 border border-gray-200 rounded-md">
          <div className="flex justify-between items-center">
            <div>
              <h4 className="font-medium text-gray-800">Estimated Campaign Reach</h4>
              <p className="text-sm text-gray-600">Based on selected filters</p>
            </div>
            <div className="text-right">
              <div className="text-2xl font-bold text-primary-700">
                {estimatedProviderCount.toLocaleString()} Providers
              </div>
              <div className="text-sm text-gray-600">
                Potential to reach ~{(estimatedProviderCount * 250).toLocaleString()} patients
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }
  
  if (step === 3) {
    return (
      <div className={`animate-fadeIn ${className}`}>
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          <MapPin className="inline-block mr-2 text-primary-500" size={20} />
          Campaign Summary
        </h3>
        
        <div className="p-4 bg-white border border-gray-200 rounded-md space-y-4">
          <div className="flex justify-between border-b pb-3">
            <div className="font-medium">Targeting Summary</div>
            <div className="text-primary-600">{estimatedProviderCount.toLocaleString()} Providers</div>
          </div>
          
          <div className="space-y-2">
            <div className="text-sm text-gray-800">
              <span className="font-medium">Campaign Name:</span> {targeting.name}
            </div>
            
            <div className="text-sm text-gray-800">
              <span className="font-medium">Provider Count:</span> {estimatedProviderCount.toLocaleString()}
            </div>
            
            <div className="text-sm text-gray-800">
              <span className="font-medium">Potential Patient Reach:</span> {(estimatedProviderCount * 250).toLocaleString()}
            </div>
          </div>
          
          <div className="pt-3 text-sm text-gray-500 italic">
            The enhanced provider targeting uses real prescription data to identify the most relevant providers for your campaign.
          </div>
        </div>
      </div>
    );
  }
  
  return null;
}
