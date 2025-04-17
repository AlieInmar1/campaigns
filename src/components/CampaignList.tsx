import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { ListFilter, ChevronRight, Target, TrendingUp, Users, ArrowUpRight, ChartBar } from 'lucide-react';
import { getSampleCampaigns } from '../lib/sampleCampaignData';

interface Campaign {
  id: string;
  name: string;
  description?: string;
  status: string;
  target_geographic_area: string;
  target_specialty: string;
  created_at: string;
  // Result metrics
  script_lift?: number;
  market_share_change?: number;
  provider_count?: number;
  provider_reach?: number;
  start_date?: string;
  end_date?: string;
}

export function CampaignList() {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Use sample data instead of fetching from Supabase
    const loadSampleCampaigns = async () => {
      try {
        // Get sample campaigns with results
        const sampleCampaigns = getSampleCampaigns();
        
        // Map sample campaigns to our Campaign interface
        const mappedCampaigns: Campaign[] = sampleCampaigns.map(sample => ({
          id: sample.id,
          name: sample.name,
          description: sample.description,
          status: sample.status,
          target_geographic_area: sample.target.geographic,
          target_specialty: sample.target.specialty,
          created_at: sample.created_at,
          script_lift: sample.metrics.scriptLift,
          market_share_change: sample.metrics.marketShareChange,
          provider_count: sample.metrics.providerCount,
          provider_reach: sample.metrics.providerReach * 25, // More realistic patient reach
          start_date: sample.startDate,
          end_date: sample.endDate
        }));
        
        setCampaigns(mappedCampaigns);
      } catch (error) {
        console.error('Error loading sample campaigns:', error);
      } finally {
        setLoading(false);
      }
    };
    
    loadSampleCampaigns();
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center">
          <ListFilter className="h-6 w-6 text-indigo-600 mr-2" />
          <h2 className="text-2xl font-bold text-gray-900">Your Campaigns</h2>
        </div>
        <Link
          to="/create"
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700"
        >
          <Target className="h-4 w-4 mr-2" />
          New Campaign
        </Link>
      </div>

      <div className="bg-white shadow-sm rounded-lg overflow-hidden">
        <ul className="divide-y divide-gray-200">
          {campaigns.map((campaign) => (
            <li key={campaign.id}>
              <Link
                to={`/results/${campaign.id}`}
                className="block hover:bg-gray-50 transition duration-150 ease-in-out"
              >
                <div className="px-6 py-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-lg font-medium text-gray-900">{campaign.name}</p>
                      <div className="mt-1 flex items-center space-x-4 text-sm text-gray-500">
                        <span>{campaign.target_geographic_area}</span>
                        <span>•</span>
                        <span>{campaign.target_specialty}</span>
                      </div>
                    </div>
                    <div className="flex items-center">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${
                        campaign.status === 'active' ? 'bg-green-100 text-green-800' :
                        campaign.status === 'draft' ? 'bg-gray-100 text-gray-800' :
                        campaign.status === 'completed' ? 'bg-blue-100 text-blue-800' :
                        'bg-yellow-100 text-yellow-800'
                      }`}>
                        {campaign.status}
                      </span>
                      <ChevronRight className="h-5 w-5 text-gray-400 ml-4" />
                    </div>
                  </div>
                  
                  {/* Campaign description */}
                  {campaign.description && (
                    <div className="mt-2 text-sm text-gray-600 line-clamp-2">
                      {campaign.description}
                    </div>
                  )}
                  
                  {/* Campaign results metrics */}
                  {(campaign.status === 'active' || campaign.status === 'completed') && campaign.script_lift !== undefined && (
                    <div className="mt-3 grid grid-cols-3 gap-4 border-t border-gray-100 pt-3">
                      <div className="flex items-center">
                        <TrendingUp className="h-4 w-4 text-green-500 mr-1" />
                        <span className="text-sm font-medium text-gray-900">{campaign.script_lift.toFixed(1)}%</span>
                        <span className="ml-1 text-xs text-gray-500">Script Lift</span>
                      </div>
                      <div className="flex items-center">
                        <ChartBar className="h-4 w-4 text-indigo-500 mr-1" />
                        <span className="text-sm font-medium text-gray-900">{campaign.market_share_change?.toFixed(1)}%</span>
                        <span className="ml-1 text-xs text-gray-500">Market Share</span>
                      </div>
                      <div className="flex items-center">
                        <Users className="h-4 w-4 text-blue-500 mr-1" />
                        <span className="text-sm font-medium text-gray-900">{campaign.provider_count?.toLocaleString()}</span>
                        <span className="ml-1 text-xs text-gray-500">Providers</span>
                      </div>
                    </div>
                  )}
                </div>
              </Link>
            </li>
          ))}
          {campaigns.length === 0 && (
            <li className="px-6 py-12">
              <div className="text-center">
                <p className="text-gray-500">No campaigns yet</p>
                <Link
                  to="/create"
                  className="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-indigo-600 bg-indigo-100 hover:bg-indigo-200"
                >
                  Create your first campaign
                </Link>
              </div>
            </li>
          )}
        </ul>
      </div>
    </div>
  );
}
