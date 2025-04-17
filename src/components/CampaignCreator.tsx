import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { supabase } from '../lib/supabase';
import { Target, Send, AlertCircle } from 'lucide-react';
import { countProvidersByFilter, getProvidersByFilter } from '../lib/providerDataService';

interface CampaignForm {
  name: string;
  target_condition_id?: string;
  target_medication_id?: string;
  target_geographic_area?: string;
  target_specialty?: string;
}

interface TargetingCounts {
  total: number;
  andLogic: number;
  orLogic: number;
}

interface Provider {
  id: string;
  specialty: string;
  geographic_area: string;
}

export function CampaignCreator() {
  const navigate = useNavigate();
  const [conditions, setConditions] = useState<any[]>([]);
  const [medications, setMedications] = useState<any[]>([]);
  const [specialties, setSpecialties] = useState<any[]>([]);
  const [geographicRegions, setGeographicRegions] = useState<any[]>([]);
  const [templates, setTemplates] = useState<any[]>([]);
  const [showAddModal, setShowAddModal] = useState(false);
  const [addType, setAddType] = useState<'condition' | 'medication' | null>(null);
  const [newItemName, setNewItemName] = useState('');
  const [newItemDescription, setNewItemDescription] = useState('');
  const [newMedicationCategory, setNewMedicationCategory] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [targetingCounts, setTargetingCounts] = useState<TargetingCounts | null>(null);
  const [providerCount, setProviderCount] = useState<number | null>(null);
  const [useAndLogic, setUseAndLogic] = useState(false);
  const { register, handleSubmit, formState: { errors }, watch } = useForm<CampaignForm>();
  const watchedValues = watch();

  useEffect(() => {
    checkAuthAndFetchData();
  }, []);

  useEffect(() => {
    updateProviderCount();
  }, [watchedValues.target_specialty, watchedValues.target_geographic_area]);

  const updateProviderCount = async () => {
    try {
      // Get total provider count
      const { count: totalCount } = await supabase
        .from('providers')
        .select('*', { count: 'exact', head: true });

      if (!totalCount) {
        setTargetingCounts(null);
        return;
      }

      // Check if we have any filters
      const hasFilter = watchedValues.target_condition_id || 
                        watchedValues.target_medication_id || 
                        watchedValues.target_specialty || 
                        watchedValues.target_geographic_area;

      if (!hasFilter) {
        setProviderCount(null);
        setTargetingCounts(null);
        return;
      }

      // Convert form values to filter format
      const filter = {
        medicationIds: watchedValues.target_medication_id ? [watchedValues.target_medication_id] : [],
        specialties: watchedValues.target_specialty ? [watchedValues.target_specialty] : [],
        regions: watchedValues.target_geographic_area ? [watchedValues.target_geographic_area] : []
      };

      // Get filtered counts using the provider data service
      const andCount = await countProvidersByFilter({...filter, useAndLogic: true});
      const orCount = await countProvidersByFilter({...filter, useAndLogic: false});

      setTargetingCounts({
        total: totalCount || 0,
        andLogic: andCount || 0,
        orLogic: orCount || 0
      });

      // Set the provider count based on the current logic selection
      setProviderCount(useAndLogic ? andCount : orCount);
    } catch (error) {
      console.error('Error counting providers:', error);
      setTargetingCounts(null);
      setProviderCount(null);
    }
  };

  const checkAuthAndFetchData = async () => {
    try {
      const { data: { session }, error: sessionError } = await supabase.auth.getSession();
      
      if (sessionError) throw sessionError;
      if (!session) {
        navigate('/login');
        return;
      }

      const { data: { user }, error: authError } = await supabase.auth.getUser();
      
      if (authError) throw authError;
      if (!user) {
        navigate('/login');
        return;
      }

      await fetchReferenceData();
    } catch (error) {
      console.error('Auth error:', error);
      setError('Authentication error. Please try logging in again.');
      navigate('/login');
    }
  }

  async function fetchReferenceData() {
    try {
      setError(null);
      setLoading(true);

      const [conditionsRes, medicationsRes, specialtiesRes, regionsRes] = await Promise.all([
        supabase.from('conditions').select('*'),
        supabase.from('medications').select('*'),
        supabase.from('specialties').select('*'),
        supabase.from('geographic_regions').select('id, name, type')
      ]);
    
      if (conditionsRes.error) throw conditionsRes.error;
      if (medicationsRes.error) throw medicationsRes.error;
      if (specialtiesRes.error) throw specialtiesRes.error;
      if (regionsRes.error) throw regionsRes.error;

      setConditions(conditionsRes.data || []);
      setMedications(medicationsRes.data || []);
      setSpecialties(specialtiesRes.data || []);
      setGeographicRegions(regionsRes.data || []);
      setTemplates([]); // Set empty array as default
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to fetch data';
      console.error('Error fetching reference data:', message);
      setError('Failed to load required data. Please refresh the page.');
    } finally {
      setLoading(false);
    }
  }

  const handleAddItem = async () => {
    if (!newItemName) return;

    try {
      if (addType === 'condition') {
        const { error } = await supabase.from('conditions').insert({
          name: newItemName,
          description: newItemDescription
        });
        if (error) throw error;
      } else if (addType === 'medication') {
        const { error } = await supabase.from('medications').insert({
          name: newItemName,
          category: newMedicationCategory,
          description: newItemDescription
        });
        if (error) throw error;
      }

      // Refresh data
      await fetchReferenceData();
      
      // Reset form
      setNewItemName('');
      setNewItemDescription('');
      setNewMedicationCategory('');
      setShowAddModal(false);
      setAddType(null);
    } catch (error) {
      console.error('Error adding item:', error);
    }
  };

  const onSubmit = async (data: CampaignForm) => {
    setLoading(true);
    setError(null);

    try {
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError) throw userError;
      if (!user) {
        throw new Error('User not authenticated');
      }

      // Convert form values to filter format for getting targeted providers
      const filter = {
        medicationIds: data.target_medication_id ? [data.target_medication_id] : [],
        specialties: data.target_specialty ? [data.target_specialty] : [],
        regions: data.target_geographic_area ? [data.target_geographic_area] : [],
        useAndLogic: useAndLogic
      };

      // Get the list of targeted provider IDs
      const targetedProviders = await getProvidersByFilter(filter);

      const campaign = {
        ...data,
        creative_content: {
          headline: 'Default Campaign',
          body: 'Campaign targeting healthcare providers',
          cta: 'Learn More'
        },
        status: 'draft',
        targeting_logic: useAndLogic ? 'and' : 'or',
        created_by: user.id,
        targeted_providers: targetedProviders, // Save the list of targeted providers
        provider_count: targetedProviders.length // Save the count for quick reference
      };

      const { error: insertError } = await supabase
        .from('campaigns')
        .insert(campaign);

      if (insertError) throw insertError;
      
      navigate('/');
    } catch (error) {
      console.error('Error creating campaign:', error);
      setError(error instanceof Error ? error.message : 'Failed to create campaign');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white shadow-sm rounded-lg p-6">
      <div className="flex items-center mb-6">
        <Target className="h-6 w-6 text-indigo-600 mr-2" aria-hidden="true" />
        <h2 className="text-2xl font-bold text-gray-900">Create New Campaign</h2>
      </div>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 rounded-md p-4">
          <div className="flex">
            <AlertCircle className="h-5 w-5 text-red-400" aria-hidden="true" />
            <div className="ml-3">
              <p className="text-sm text-red-700">{error}</p>
            </div>
          </div>
        </div>
      )}

      {loading && (
        <div className="flex justify-center items-center py-8">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700">Campaign Name</label>
          <input
            type="text"
            {...register('name', { required: true })}
            className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
          />
          {errors.name && <span className="text-red-500 text-sm">This field is required</span>}
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-gray-700">Target Condition</label>
            <select
              {...register('target_condition_id')}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 mb-2"
            >
              <option value="">Select a condition</option>
              {conditions.map(condition => (
                <option key={condition.id} value={condition.id}>{condition.name}</option>
              ))}
            </select>
            <button
              type="button"
              onClick={() => { setAddType('condition'); setShowAddModal(true); }}
              className="text-sm text-indigo-600 hover:text-indigo-500"
            >
              + Add new condition
            </button>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Target Medication</label>
            <select
              {...register('target_medication_id')}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 mb-2"
            >
              <option value="">Select a medication</option>
              {medications.map(medication => (
                <option key={medication.id} value={medication.id}>{medication.name}</option>
              ))}
            </select>
            <button
              type="button"
              onClick={() => { setAddType('medication'); setShowAddModal(true); }}
              className="text-sm text-indigo-600 hover:text-indigo-500"
            >
              + Add new medication
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
          <div>
            <label className="block text-sm font-medium text-gray-700">Geographic Area</label>
            <select
              {...register('target_geographic_area')}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            >
              <option value="">Select a geographic area</option>
              {geographicRegions.map(region => (
                <option key={region.id} value={region.name}>
                  {region.name} ({region.type})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Target Specialty</label>
            <select
              {...register('target_specialty')}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
            >
              <option value="">Select a specialty</option>
              {specialties.map(specialty => (
                <option key={specialty.id} value={specialty.name}>
                  {specialty.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="bg-gray-50 p-4 rounded-lg mb-6">
          <div className="flex items-center justify-between mb-4">
            <span className="text-sm font-medium text-gray-700">Provider Targeting Logic:</span>
            <div className="flex space-x-2">
              <button
                type="button"
                onClick={() => setUseAndLogic(true)}
                className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                  useAndLogic
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                AND
              </button>
              <button
                type="button"
                onClick={() => setUseAndLogic(false)}
                className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                  !useAndLogic
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                OR
              </button>
            </div>
          </div>
          {targetingCounts && (
            <div className="text-sm text-gray-600">
              <p className="mb-2">
                Targeting <span className="font-medium text-indigo-600">{useAndLogic ? targetingCounts.andLogic : targetingCounts.orLogic}</span> out of <span className="font-medium">{targetingCounts.total}</span> total providers
              </p>
              <p className="text-xs text-gray-500">
                {useAndLogic ? 'Providers must match ALL selected criteria' : 'Providers must match ANY selected criteria'}
              </p>
            </div>
          )}
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={loading}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <Send className="h-4 w-4 mr-2" />
            {loading ? 'Creating...' : 'Create Campaign'}
          </button>
        </div>
      </form>

      {/* Add Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center">
          <div className="bg-white rounded-lg p-6 max-w-md w-full">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Add New {addType === 'condition' ? 'Condition' : 'Medication'}
            </h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Name</label>
                <input
                  type="text"
                  value={newItemName}
                  onChange={(e) => setNewItemName(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
              {addType === 'medication' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700">Category</label>
                  <input
                    type="text"
                    value={newMedicationCategory}
                    onChange={(e) => setNewMedicationCategory(e.target.value)}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  />
                </div>
              )}
              <div>
                <label className="block text-sm font-medium text-gray-700">Description</label>
                <textarea
                  value={newItemDescription}
                  onChange={(e) => setNewItemDescription(e.target.value)}
                  rows={3}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              </div>
            </div>
            <div className="mt-6 flex justify-end space-x-3">
              <button
                type="button"
                onClick={() => {
                  setShowAddModal(false);
                  setAddType(null);
                  setNewItemName('');
                  setNewItemDescription('');
                  setNewMedicationCategory('');
                }}
                className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleAddItem}
                className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Add {addType === 'condition' ? 'Condition' : 'Medication'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
