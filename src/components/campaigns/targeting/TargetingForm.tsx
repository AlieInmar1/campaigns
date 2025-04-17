import React, { useState, useEffect } from 'react';
import { Pill, Users, MapPin } from 'lucide-react';
import { Select } from '../../ui/Select';
import { MultiSelect } from '../../ui/MultiSelect';
import { Input } from '../../ui/Input';
import { cn } from '../../../utils/cn';
import { TargetingState } from '../../../hooks/useTargetingForm';
import { 
  getMedicationCategories, 
  getMedicationsByCategory,
  getAvailableSpecialties,
  getAvailableRegions
} from '../../../lib/enhancedProviderDataService';

interface TargetingFormProps {
  targeting: TargetingState;
  updateTargeting: (key: keyof TargetingState, value: any) => void;
  step: number;
  className?: string;
}

export function TargetingForm({
  targeting,
  updateTargeting,
  step,
  className = '',
}: TargetingFormProps) {
  // Data state for reference options
  const [availableMedicationCategories, setAvailableMedicationCategories] = useState<string[]>([]);
  const [availableMedications, setAvailableMedications] = useState<{id: string, name: string, category: string}[]>([]);
  const [availableSpecialties, setAvailableSpecialties] = useState<{id: string, name: string}[]>([]);
  const [availableRegions, setAvailableRegions] = useState<{id: string, name: string, type: string}[]>([]);
  const [isLoadingOptions, setIsLoadingOptions] = useState(true);

  // Load reference data using mock data service
  useEffect(() => {
    const loadReferenceData = async () => {
      setIsLoadingOptions(true);
      try {
        // Load medication categories
        console.log("Loading medication categories");
        const categories = await getMedicationCategories();
        setAvailableMedicationCategories(categories);
        
        // Load all medications
        console.log("Loading all medications");
        const allMedications = await getMedicationsByCategory();
        console.log(`Loaded ${allMedications.length} total medications`);
        setAvailableMedications(allMedications);
        
        // Load specialties
        console.log("Loading specialties");
        const specialties = await getAvailableSpecialties();
        
        // Format specialties for the MultiSelect component
        const specialtiesOptions = specialties.map(specialty => ({
          id: specialty,
          name: specialty
        }));
        
        console.log('Loaded specialties:', specialtiesOptions);
        setAvailableSpecialties(specialtiesOptions);
        
        // Load regions
        console.log("Loading regions");
        const regions = await getAvailableRegions();
        
        // Format regions for the MultiSelect component
        const regionsOptions = regions.map(region => ({
          id: region,
          name: region,
          type: 'Region'
        }));
        
        console.log('Loaded regions:', regionsOptions);
        setAvailableRegions(regionsOptions);
      } catch (error) {
        console.error('Error loading reference data:', error);
      } finally {
        setIsLoadingOptions(false);
      }
    };
    
    loadReferenceData();
  }, []);

  // Filter medications based on selected category (if any)
  const filteredMedications = targeting.medicationCategory 
    ? availableMedications.filter(med => med.category === targeting.medicationCategory)
    : availableMedications;

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
        
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          <Pill className="inline-block mr-2 text-primary-500" size={20} />
          Select Medications
        </h3>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Medication Category (Optional)
            </label>
            <Select
              options={[
                { value: '', label: 'All Categories' },
                ...availableMedicationCategories.map(cat => ({ value: cat, label: cat }))
              ]}
              value={targeting.medicationCategory}
              onChange={(val) => updateTargeting('medicationCategory', val)}
              disabled={isLoadingOptions}
            />
            <div className="mt-1 text-xs text-gray-500">
              {targeting.medicationCategory 
                ? `Filtering by: ${targeting.medicationCategory}` 
                : 'Showing medications from all categories'}
            </div>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Medications to Include
            </label>
            <MultiSelect
              options={filteredMedications.map(med => ({ 
                value: med.id, 
                label: `${med.name} (${med.category})` 
              }))}
              value={targeting.medications}
              onChange={(val) => updateTargeting('medications', val)}
              isDisabled={isLoadingOptions}
              placeholder="Select medications to include"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Medications to Exclude (Optional)
            </label>
            <MultiSelect
              options={filteredMedications.map(med => ({ 
                value: med.id, 
                label: `${med.name} (${med.category})` 
              }))}
              value={targeting.excludedMedications}
              onChange={(val) => updateTargeting('excludedMedications', val)}
              isDisabled={isLoadingOptions}
              placeholder="Select medications to exclude"
              className="border-error-300 focus:border-error-500 bg-error-50"
            />
            <p className="mt-1 text-xs text-gray-500">
              These medications will be specifically excluded (useful for finding providers who prescribe competitors but not your product)
            </p>
          </div>
        </div>
      </div>
    );
  }
  
  if (step === 2) {
    return (
      <div className="animate-fadeIn">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          <Users className="inline-block mr-2 text-primary-500" size={20} />
          Define Provider Criteria
        </h3>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Provider Specialties
            </label>
            <MultiSelect
              options={availableSpecialties.map(specialty => ({ value: specialty.id, label: specialty.name }))}
              value={targeting.specialties}
              onChange={(val) => updateTargeting('specialties', val)}
              placeholder="Select target specialties"
              isDisabled={isLoadingOptions}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Prescribing Volume
            </label>
            <div className="flex space-x-2">
              {['all', 'high', 'medium', 'low'].map(volume => (
                <button
                  key={volume}
                  type="button"
                  onClick={() => updateTargeting('prescribingVolume', volume as any)}
                  className={cn(
                    "flex-1 py-2 px-3 text-sm font-medium rounded-md border",
                    targeting.prescribingVolume === volume
                      ? "bg-primary-50 border-primary-300 text-primary-700"
                      : "bg-white border-gray-300 text-gray-700 hover:bg-gray-50"
                  )}
                  disabled={isLoadingOptions}
                >
                  {volume === 'all' ? 'All Volumes' : `${volume.charAt(0).toUpperCase() + volume.slice(1)} Volume`}
                </button>
              ))}
            </div>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Provider Gender
            </label>
            <div className="flex space-x-2">
              {['all', 'male', 'female'].map(gender => (
                <button
                  key={gender}
                  type="button"
                  onClick={() => updateTargeting('gender', gender as any)}
                  className={cn(
                    "flex-1 py-2 px-3 text-sm font-medium rounded-md border",
                    targeting.gender === gender
                      ? "bg-primary-50 border-primary-300 text-primary-700"
                      : "bg-white border-gray-300 text-gray-700 hover:bg-gray-50"
                  )}
                  disabled={isLoadingOptions}
                >
                  {gender === 'all' ? 'All Genders' : `${gender.charAt(0).toUpperCase() + gender.slice(1)} Providers`}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }
  
  if (step === 3) {
    return (
      <div className="animate-fadeIn">
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          <MapPin className="inline-block mr-2 text-primary-500" size={20} />
          Geographic Targeting
        </h3>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Target Regions
            </label>
            <MultiSelect
              options={availableRegions.map(region => ({ 
                value: region.id, 
                label: `${region.name} (${region.type})` 
              }))}
              value={targeting.regions}
              onChange={(val) => updateTargeting('regions', val)}
              placeholder="Select target regions"
              isDisabled={isLoadingOptions}
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Analysis Timeframe
            </label>
            <div className="flex space-x-2">
              {[
                { value: 'last_month', label: 'Last Month' },
                { value: 'last_quarter', label: 'Last Quarter' },
                { value: 'last_year', label: 'Last Year' }
              ].map(option => (
                <button
                  key={option.value}
                  type="button"
                  onClick={() => updateTargeting('timeframe', option.value as any)}
                  className={cn(
                    "flex-1 py-2 px-3 text-sm font-medium rounded-md border",
                    targeting.timeframe === option.value
                      ? "bg-primary-50 border-primary-300 text-primary-700"
                      : "bg-white border-gray-300 text-gray-700 hover:bg-gray-50"
                  )}
                  disabled={isLoadingOptions}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }
  
  return null;
}
