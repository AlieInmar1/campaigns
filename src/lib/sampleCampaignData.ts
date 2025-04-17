/**
 * Sample campaign data for the dashboard
 * This provides realistic campaign data with varied metrics
 */

export interface SampleCampaign {
  id: string;
  name: string;
  description: string;
  status: 'active' | 'completed' | 'draft' | 'scheduled';
  startDate: string;
  endDate: string;
  target: {
    specialty: string;
    geographic: string;
    condition: string;
    medication: string;
    category: string;
  };
  metrics: {
    impressions: number;
    clicks: number;
    conversions: number;
    scriptLift: number;
    marketShareBefore: number;
    marketShareAfter: number;
    marketShareChange: number;
    providerReach: number;
    providerCount: number;
    categoryTotalScripts: number;
  };
  created_at: string;
  updated_at: string;
  // Added detailed prescription impact data
  results?: {
    prescription_metrics?: {
      prescription_impact?: {
        script_lift_percentage: number;
        baseline_monthly_scripts: number;
        current_monthly_scripts: number;
        projected_annual_scripts: number;
        provider_impact: {
          total_providers_reached: number;
          high_prescribers_reached: number;
          new_prescribers: number;
          prescriber_retention_rate: number;
        };
        medication_performance: Array<{
          medication_name: string;
          baseline_scripts: number;
          current_scripts: number;
          script_lift: number;
          market_share: number;
        }>;
      };
    };
  };
}

/**
 * Sample campaign data with detailed metrics and targeting
 */
export const sampleCampaigns: SampleCampaign[] = [
  {
    id: 'camp-1',
    name: 'Lipitor Awareness Campaign',
    description: 'This campaign targets cardiologists in the Northeast region who have historically prescribed generic statins. Our goal is to increase awareness of Lipitor\'s superior efficacy for high-risk hyperlipidemia patients. The campaign emphasizes recent clinical data showing improved outcomes in patients with multiple cardiovascular risk factors.',
    status: 'completed',
    startDate: '2025-01-15',
    endDate: '2025-04-15',
    target: {
      specialty: 'Cardiology',
      geographic: 'Northeast',
      condition: 'Hyperlipidemia',
      medication: 'Lipitor',
      category: 'Statins'
    },
    metrics: {
      impressions: 156000,
      clicks: 7800,
      conversions: 3120,
      scriptLift: 17.8,
      marketShareBefore: 23.5,
      marketShareAfter: 28.7,
      marketShareChange: 5.2,
      providerReach: 1250,
      providerCount: 3750,
      categoryTotalScripts: 42500
    },
    created_at: '2025-01-10T08:30:00Z',
    updated_at: '2025-03-28T14:15:00Z',
    results: {
      prescription_metrics: {
        prescription_impact: {
          script_lift_percentage: 17.8,
          baseline_monthly_scripts: 8500,
          current_monthly_scripts: 10013,
          projected_annual_scripts: 120156,
          provider_impact: {
            total_providers_reached: 3750,
            high_prescribers_reached: 1125,
            new_prescribers: 450,
            prescriber_retention_rate: 92.5
          },
          medication_performance: [
            {
              medication_name: 'Lipitor',
              baseline_scripts: 5200,
              current_scripts: 6500,
              script_lift: 25.0,
              market_share: 28.7
            },
            {
              medication_name: 'Crestor',
              baseline_scripts: 3800,
              current_scripts: 4100,
              script_lift: 7.9,
              market_share: 18.1
            },
            {
              medication_name: 'Zocor',
              baseline_scripts: 2900,
              current_scripts: 3050,
              script_lift: 5.2,
              market_share: 13.5
            }
          ]
        }
      }
    }
  },
  {
    id: 'camp-2',
    name: 'Metformin Targeting Campaign',
    description: 'This nationwide campaign focuses on endocrinologists who treat Type 2 Diabetes patients. We\'re highlighting Metformin\'s established safety profile and updated guidelines recommending it as first-line therapy. The campaign includes educational materials about combining Metformin with newer agents for optimal glycemic control in diverse patient populations.',
    status: 'completed',
    startDate: '2025-02-01',
    endDate: '2025-05-01',
    target: {
      specialty: 'Endocrinology',
      geographic: 'Nationwide',
      condition: 'Type 2 Diabetes',
      medication: 'Metformin',
      category: 'Antidiabetics'
    },
    metrics: {
      impressions: 203000,
      clicks: 9500,
      conversions: 4270,
      scriptLift: 22.3,
      marketShareBefore: 45.2,
      marketShareAfter: 52.8,
      marketShareChange: 7.6,
      providerReach: 1580,
      providerCount: 4850,
      categoryTotalScripts: 68200
    },
    created_at: '2025-01-25T10:45:00Z',
    updated_at: '2025-03-27T16:20:00Z',
    results: {
      prescription_metrics: {
        prescription_impact: {
          script_lift_percentage: 22.3,
          baseline_monthly_scripts: 12500,
          current_monthly_scripts: 15288,
          projected_annual_scripts: 183456,
          provider_impact: {
            total_providers_reached: 4850,
            high_prescribers_reached: 1940,
            new_prescribers: 725,
            prescriber_retention_rate: 94.2
          },
          medication_performance: [
            {
              medication_name: 'Metformin',
              baseline_scripts: 7800,
              current_scripts: 10250,
              script_lift: 31.4,
              market_share: 52.8
            },
            {
              medication_name: 'Januvia',
              baseline_scripts: 4200,
              current_scripts: 4650,
              script_lift: 10.7,
              market_share: 23.9
            },
            {
              medication_name: 'Jardiance',
              baseline_scripts: 3100,
              current_scripts: 3450,
              script_lift: 11.3,
              market_share: 17.8
            }
          ]
        }
      }
    }
  },
  {
    id: 'camp-3',
    name: 'Plavix Provider Engagement',
    description: 'This targeted campaign reaches cardiologists in the Midwest who manage post-MI patients. We\'re emphasizing Plavix\'s role in reducing secondary cardiovascular events and its synergistic effects when used with other standard therapies. The campaign includes case studies showing improved outcomes in high-risk patients and practical guidance on optimizing antiplatelet therapy duration.',
    status: 'completed',
    startDate: '2025-01-10',
    endDate: '2025-04-10',
    target: {
      specialty: 'Cardiology',
      geographic: 'Midwest',
      condition: 'Post-MI Maintenance',
      medication: 'Plavix',
      category: 'Antiplatelet Agents'
    },
    metrics: {
      impressions: 142000,
      clicks: 6100,
      conversions: 2440,
      scriptLift: 14.2,
      marketShareBefore: 31.8,
      marketShareAfter: 36.5,
      marketShareChange: 4.7,
      providerReach: 980,
      providerCount: 2950,
      categoryTotalScripts: 35400
    },
    created_at: '2025-01-05T09:15:00Z',
    updated_at: '2025-03-26T11:30:00Z',
    results: {
      prescription_metrics: {
        prescription_impact: {
          script_lift_percentage: 14.2,
          baseline_monthly_scripts: 7200,
          current_monthly_scripts: 8222,
          projected_annual_scripts: 98664,
          provider_impact: {
            total_providers_reached: 2950,
            high_prescribers_reached: 885,
            new_prescribers: 320,
            prescriber_retention_rate: 89.8
          },
          medication_performance: [
            {
              medication_name: 'Plavix',
              baseline_scripts: 4500,
              current_scripts: 5400,
              script_lift: 20.0,
              market_share: 36.5
            },
            {
              medication_name: 'Brilinta',
              baseline_scripts: 2800,
              current_scripts: 3050,
              script_lift: 8.9,
              market_share: 20.7
            },
            {
              medication_name: 'Effient',
              baseline_scripts: 1900,
              current_scripts: 2000,
              script_lift: 5.3,
              market_share: 13.6
            }
          ]
        }
      }
    }
  }
];

/**
 * Get all sample campaigns
 */
export function getSampleCampaigns(): SampleCampaign[] {
  return sampleCampaigns;
}

/**
 * Get a specific sample campaign by ID
 */
export function getSampleCampaignById(id: string): SampleCampaign | undefined {
  return sampleCampaigns.find(campaign => campaign.id === id);
}

/**
 * Get active sample campaigns
 * Note: This now returns completed campaigns since all sample campaigns are marked as completed
 */
export function getActiveSampleCampaigns(): SampleCampaign[] {
  return sampleCampaigns.filter(campaign => campaign.status === 'completed');
}

/**
 * Get sample campaign metrics summary
 */
export function getSampleCampaignMetricsSummary() {
  const activeCampaigns = getActiveSampleCampaigns();
  
  // Calculate average metrics
  const totalImpressions = activeCampaigns.reduce((sum, campaign) => sum + campaign.metrics.impressions, 0);
  const totalClicks = activeCampaigns.reduce((sum, campaign) => sum + campaign.metrics.clicks, 0);
  const totalConversions = activeCampaigns.reduce((sum, campaign) => sum + campaign.metrics.conversions, 0);
  const totalProviderReach = activeCampaigns.reduce((sum, campaign) => sum + campaign.metrics.providerReach, 0);
  
  // Calculate weighted average for script lift and market share change
  const weightedScriptLift = activeCampaigns.reduce((sum, campaign) => 
    sum + (campaign.metrics.scriptLift * campaign.metrics.providerReach), 0) / totalProviderReach;
  
  const weightedMarketShareChange = activeCampaigns.reduce((sum, campaign) => 
    sum + (campaign.metrics.marketShareChange * campaign.metrics.providerReach), 0) / totalProviderReach;
  
  return {
    campaignCount: activeCampaigns.length,
    totalImpressions,
    totalClicks,
    totalConversions,
    totalProviderReach,
    averageScriptLift: weightedScriptLift,
    averageMarketShareChange: weightedMarketShareChange,
    totalProviderCount: activeCampaigns.reduce((sum, campaign) => sum + campaign.metrics.providerCount, 0),
    totalCategoryScripts: activeCampaigns.reduce((sum, campaign) => sum + campaign.metrics.categoryTotalScripts, 0),
    clickThroughRate: (totalClicks / totalImpressions) * 100,
    conversionRate: (totalConversions / totalClicks) * 100
  };
}

/**
 * Get sample campaign performance data for charts
 */
export function getSampleCampaignPerformanceData(timeframe: '1m' | '3m' | '6m' | '1y' = '6m') {
  // Determine how many months to show based on timeframe
  const monthCount = timeframe === '1m' ? 1 : 
                     timeframe === '3m' ? 3 : 
                     timeframe === '6m' ? 6 : 12;
  
  // Create month labels going back from current month
  const today = new Date();
  const months = [];
  for (let i = monthCount - 1; i >= 0; i--) {
    const d = new Date(today.getFullYear(), today.getMonth() - i, 1);
    months.push(d.toLocaleString('default', { month: 'short' }));
  }
  
  // Get active campaigns to scale the metrics
  const activeCampaignCount = getActiveSampleCampaigns().length;
  const scaleFactor = activeCampaignCount / 3; // Assuming 3 is an average baseline
  
  // Generate data with some randomness but trending upward
  return months.map((month, index) => {
    // Base numbers that increase each month
    const baseImpressions = 15000 + (index * 2000);
    const baseClicks = 3500 + (index * 300);
    const basePrescriptions = 900 + (index * 100);
    const baseConversions = 1800 + (index * 150);
    
    // Add some randomness and scale by active campaigns
    return {
      month,
      impressions: Math.round((baseImpressions + (Math.random() * 2000 - 1000)) * scaleFactor),
      clicks: Math.round((baseClicks + (Math.random() * 400 - 200)) * scaleFactor),
      prescriptions: Math.round((basePrescriptions + (Math.random() * 100 - 50)) * scaleFactor),
      conversions: Math.round((baseConversions + (Math.random() * 300 - 150)) * scaleFactor)
    };
  });
}

/**
 * Get sample campaign comparison data for charts
 */
export function getSampleCampaignComparisonData() {
  // Get active campaigns, sorted by script lift (descending)
  return getActiveSampleCampaigns()
    .sort((a, b) => b.metrics.scriptLift - a.metrics.scriptLift)
    .map(campaign => {
      return {
        campaign: campaign.name,
        marketShareChange: campaign.metrics.marketShareChange,
        providerReach: campaign.metrics.providerReach,
        scriptLift: campaign.metrics.scriptLift,
        clicks: campaign.metrics.clicks,
        impressions: campaign.metrics.impressions,
        providerCount: campaign.metrics.providerCount
      };
    });
}

/**
 * Get sample specialty distribution data for charts
 */
export function getSampleSpecialtyDistributionData() {
  return [
    { name: 'Cardiology', value: 42 },
    { name: 'Endocrinology', value: 23 },
    { name: 'Primary Care', value: 15 },
    { name: 'Internal Medicine', value: 12 },
    { name: 'Other', value: 8 },
  ];
}

/**
 * Get sample region distribution data for charts
 */
export function getSampleRegionDistributionData() {
  return [
    { name: 'Northeast', value: 32 },
    { name: 'Midwest', value: 27 },
    { name: 'South', value: 25 },
    { name: 'West', value: 16 },
  ];
}
