import React, { useEffect, useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../hooks';
import { Button } from '../ui/Button';
import { Input } from '../ui/Input';
import { Select } from '../ui/Select';
import { 
  ListFilter, 
  Users, 
  Search,
  RefreshCw,
  Filter,
  MapPin,
  Building,
  UserCheck,
  Pill
} from 'lucide-react';
import { cn } from '../../utils/cn';
import { supabase } from '../../lib/supabase';
import { getProvidersByFilter } from '../../lib/providerDataService';

export function ProviderList() {
  const dispatch = useAppDispatch();
  const [searchQuery, setSearchQuery] = useState('');
  const [specialtyFilter, setSpecialtyFilter] = useState<string>('');
  const [regionFilter, setRegionFilter] = useState<string>('');
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [showFilters, setShowFilters] = useState(false);

  // Provider data state
  const [providers, setProviders] = useState<Array<{
    id: string;
    provider_id: string;
    name: string;
    specialty: string;
    geographic_area: string;
    practice_size: string;
    prescribing_volume: string;
    identity_matched?: boolean;
  }>>([]);
  
  // Medication filter state
  const [medicationFilter, setMedicationFilter] = useState<string>('');

  // Get specialties for filtering
  const specialties = useAppSelector(state => {
    const refData = state.referenceData as { specialties: any[] };
    return refData.specialties || [];
  });

  // Get regions for filtering
  const regions = useAppSelector(state => {
    const refData = state.referenceData as { geographicRegions: any[] };
    return refData.geographicRegions || [];
  });

  // Get medications for filtering
  const medications = useAppSelector(state => {
    const refData = state.referenceData as { medications: any[] };
    return refData.medications || [];
  });

  // Load providers when component mounts
  useEffect(() => {
    loadFilteredProviders();
  }, []);

  // Load providers with filters
  const loadFilteredProviders = async () => {
    try {
      setIsRefreshing(true);
      
      // If medication filter is set, use the provider data service
      if (medicationFilter) {
        // Create filter object
        const filter = {
          medicationIds: [medicationFilter],
          specialties: specialtyFilter ? [specialtyFilter] : [],
          regions: regionFilter ? [regionFilter] : []
        };
        
        // Get provider IDs that match the filter
        const providerIds = await getProvidersByFilter(filter);
        
        if (providerIds.length > 0) {
          // Get provider details for the IDs
          const { data, error } = await supabase
            .from('providers')
            .select('*')
            .in('provider_id', providerIds)
            .limit(100);
          
          if (error) throw error;
          
          // Transform data to match component's expected format
          const formattedProviders = data.map(provider => ({
            ...provider,
            id: provider.id || provider.provider_id,
            identity_matched: Math.random() > 0.3 // Simulate identity matching for now
          }));
          
          setProviders(formattedProviders);
        } else {
          setProviders([]);
        }
      } else {
        // Use regular database query with filters
        let query = supabase.from('providers').select('*');
        
        if (specialtyFilter) {
          query = query.eq('specialty', specialtyFilter);
        }
        
        if (regionFilter) {
          query = query.eq('geographic_area', regionFilter);
        }
        
        const { data, error } = await query.limit(100);
        
        if (error) throw error;
        
        // Transform data to match component's expected format
        const formattedProviders = data.map(provider => ({
          ...provider,
          id: provider.id || provider.provider_id,
          identity_matched: Math.random() > 0.3 // Simulate identity matching for now
        }));
        
        setProviders(formattedProviders);
      }
    } catch (error) {
      console.error('Error loading providers:', error);
    } finally {
      setIsRefreshing(false);
    }
  };
  
  // Load providers when filters change
  useEffect(() => {
    loadFilteredProviders();
  }, [medicationFilter, specialtyFilter, regionFilter]);
  
  // Handle refresh button click
  const handleRefresh = async () => {
    await loadFilteredProviders();
  };

  // Filter providers based on search query
  const filteredProviders = providers.filter(provider => {
    // Apply search filter
    const matchesSearch = searchQuery === '' || 
      provider.name?.toLowerCase().includes(searchQuery.toLowerCase());
    
    return matchesSearch;
  });

  // Generate options for select inputs
  const specialtyOptions = [
    { value: '', label: 'All Specialties' },
    ...(specialties.length > 0 
      ? specialties.map(specialty => ({ value: specialty.name, label: specialty.name }))
      : [
          { value: 'Primary Care', label: 'Primary Care' },
          { value: 'Cardiology', label: 'Cardiology' },
          { value: 'Neurology', label: 'Neurology' },
          { value: 'Psychiatry', label: 'Psychiatry' },
          { value: 'Oncology', label: 'Oncology' }
        ]
    )
  ];
  
  const regionOptions = [
    { value: '', label: 'All Regions' },
    ...(regions.length > 0
      ? regions.map(region => ({ 
          value: region.name, 
          label: `${region.name} ${region.type ? `(${region.type})` : ''}` 
        }))
      : [
          { value: 'Northeast US', label: 'Northeast US (Region)' },
          { value: 'Southeast US', label: 'Southeast US (Region)' },
          { value: 'Midwest US', label: 'Midwest US (Region)' },
          { value: 'Southwest US', label: 'Southwest US (Region)' },
          { value: 'West US', label: 'West US (Region)' }
        ]
    )
  ];

  return (
    <div>
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center">
            <Users className="h-6 w-6 text-primary-500 mr-2" />
            <h1 className="text-2xl font-bold text-gray-900">Healthcare Providers</h1>
          </div>
        </div>
        
        <div className="bg-white p-4 rounded-lg shadow-sm mb-4">
          <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1">
              <Input
                placeholder="Search providers..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                leftIcon={<Search className="h-4 w-4 text-gray-400" />}
                fullWidth
              />
            </div>
            <div className="flex space-x-2">
              <Button 
                variant="outline" 
                onClick={() => setShowFilters(!showFilters)}
                leftIcon={<Filter className="h-4 w-4" />}
              >
                Filters
              </Button>
              <Button 
                variant="outline" 
                onClick={handleRefresh}
                leftIcon={<RefreshCw className={cn("h-4 w-4", isRefreshing && "animate-spin")} />}
              >
                Refresh
              </Button>
            </div>
          </div>
          
          {showFilters && (
            <div className="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
              <Select
                label="Specialty"
                options={specialtyOptions}
                value={specialtyFilter}
                onChange={(value) => setSpecialtyFilter(value)}
              />
              <Select
                label="Geographic Region"
                options={regionOptions}
                value={regionFilter}
                onChange={(value) => setRegionFilter(value)}
              />
              <Select
                label="Medication"
                options={[
                  { value: '', label: 'All Medications' },
                  ...(medications.length > 0 
                    ? medications.map(med => ({ value: med.id, label: med.name }))
                    : [
                        { value: 'med1', label: 'Medication 1' },
                        { value: 'med2', label: 'Medication 2' },
                        { value: 'med3', label: 'Medication 3' }
                      ]
                  )
                ]}
                value={medicationFilter}
                onChange={(value) => setMedicationFilter(value)}
              />
            </div>
          )}
        </div>
      </div>

      <div className="bg-white shadow-sm rounded-lg overflow-hidden">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900">Provider Directory</h3>
          <div className="mt-4">
            {filteredProviders.length > 0 ? (
              <ul className="divide-y divide-gray-200">
                {filteredProviders.map((provider) => (
                  <li key={provider.id} className="py-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className={cn(
                          "flex items-center justify-center h-10 w-10 rounded-full",
                          provider.identity_matched 
                            ? "bg-green-100 text-green-600" 
                            : "bg-gray-100 text-gray-500"
                        )}>
                          {provider.identity_matched ? (
                            <UserCheck className="h-5 w-5" />
                          ) : (
                            <Users className="h-5 w-5" />
                          )}
                        </div>
                        <div className="ml-4">
                          <div className="text-sm font-medium text-gray-900">{provider.name}</div>
                          <div className="mt-1 flex items-center space-x-3 text-xs text-gray-500">
                            <div className="flex items-center">
                              <Building className="h-3 w-3 mr-1" />
                              <span>{provider.specialty}</span>
                            </div>
                            <div className="flex items-center">
                              <MapPin className="h-3 w-3 mr-1" />
                              <span>{provider.geographic_area}</span>
                            </div>
                          </div>
                        </div>
                      </div>
                      <span className={cn(
                        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                        provider.identity_matched 
                          ? "bg-green-100 text-green-800" 
                          : "bg-gray-100 text-gray-800"
                      )}>
                        {provider.identity_matched ? 'Identity Matched' : 'Not ID Matched'}
                      </span>
                    </div>
                  </li>
                ))}
              </ul>
            ) : (
              <div className="text-center py-10">
                <Users className="h-10 w-10 text-gray-400 mx-auto mb-2" />
                <p className="text-gray-500 mb-2">No providers found</p>
                <p className="text-gray-400 text-sm">
                  {searchQuery || specialtyFilter || regionFilter || medicationFilter 
                    ? 'Try adjusting your search or filters'
                    : 'Please add providers to get started'}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
