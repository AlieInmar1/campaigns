import React, { useState, useEffect } from 'react';
import { TrendingUp, AlertCircle, BarChart2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useAppSelector } from '../../hooks';
import { selectCurrentCampaign } from '../../store/slices/campaignSlice';

interface ScriptLiftComparisonProps {
  campaignId?: string;
}

export const ScriptLiftComparison: React.FC<ScriptLiftComparisonProps> = ({ campaignId }) => {
  const campaign = useAppSelector(selectCurrentCampaign);
  const effectiveCampaignId = campaignId || campaign?.id;
  
  const [scriptLiftData, setScriptLiftData] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  useEffect(() => {
    const fetchScriptLiftData = async () => {
      if (!effectiveCampaignId) return;
      
      setIsLoading(true);
      setError(null);
      
      try {
        // Instead of checking creative_templates, directly fetch script lift data
        const { data, error: fetchError } = await supabase
          .from('script_lift_data')
          .select('*')
          .eq('campaign_id', effectiveCampaignId);
          
        if (fetchError) {
          console.error('Error fetching script lift data:', fetchError);
          setError('Could not load script lift data. Please try again later.');
        } else {
          setScriptLiftData(data || []);
        }
      } catch (err) {
        console.error('Exception when fetching script lift data:', err);
        setError('An unexpected error occurred when loading data.');
      } finally {
        setIsLoading(false);
      }
    };
    
    fetchScriptLiftData();
  }, [effectiveCampaignId]);
  
  if (isLoading) {
    return (
      <div className="bg-white p-6 rounded-lg shadow-sm flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }
  
  if (error) {
    return (
      <div className="bg-white p-6 rounded-lg shadow-sm">
        <div className="flex items-center text-amber-600 mb-4">
          <AlertCircle className="h-5 w-5 mr-2" />
          <h3 className="text-lg font-semibold">Error Loading Data</h3>
        </div>
        <p className="text-gray-600">{error}</p>
      </div>
    );
  }
  
  if (!effectiveCampaignId) {
    return (
      <div className="bg-white p-6 rounded-lg shadow-sm">
        <div className="flex items-center mb-4">
          <TrendingUp className="h-5 w-5 text-primary-500 mr-2" />
          <h3 className="text-lg font-semibold text-gray-900">Script Lift Data</h3>
        </div>
        <p className="text-gray-600">Please select a campaign to view prescription data.</p>
      </div>
    );
  }

  // If no script lift data is available
  if (scriptLiftData.length === 0) {
    return (
      <div className="bg-white p-6 rounded-lg shadow-sm">
        <div className="flex items-center mb-4">
          <BarChart2 className="h-5 w-5 text-primary-500 mr-2" />
          <h3 className="text-lg font-semibold text-gray-900">Script Lift Comparison</h3>
        </div>
        <div className="p-4 bg-gray-50 rounded-lg mb-4">
          <p className="text-gray-600">
            No prescription comparison data is available for this campaign yet.
          </p>
        </div>
        <p className="text-sm text-gray-500">
          Save a baseline using the "Prescription Base Data" option above to enable comparisons.
        </p>
      </div>
    );
  }

  // Basic visualization of script lift data
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Script Lift Comparison</h3>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        {scriptLiftData.map((data, index) => (
          <div key={index} className="border rounded-lg p-4">
            <div className="flex justify-between items-center mb-3">
              <h4 className="font-medium">{`Medication Impact`}</h4>
              <span className="bg-green-100 text-green-800 text-xs font-medium px-2.5 py-0.5 rounded">
                {`+${data.lift_percentage.toFixed(1)}%`}
              </span>
            </div>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-gray-600 text-sm">Baseline</span>
                <span className="font-medium">{data.baseline.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600 text-sm">Projected</span>
                <span className="font-medium">{data.projected.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600 text-sm">Confidence</span>
                <span className="font-medium">{data.confidence_score}%</span>
              </div>
            </div>
          </div>
        ))}
      </div>
      
      <div className="text-xs text-gray-500 mt-2">
        Data provided without creative template dependency.
      </div>
    </div>
  );
};
