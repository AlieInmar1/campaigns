import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAppDispatch, useAppSelector } from '../../hooks';
import { 
  getSampleCampaigns, 
  getSampleCampaignMetricsSummary, 
  getSampleCampaignPerformanceData,
  getSampleCampaignComparisonData,
  getSampleSpecialtyDistributionData,
  getSampleRegionDistributionData
} from '../../lib/sampleCampaignData';
import {
  TrendingUp,
  Users,
  Target,
  ChevronRight,
  Plus,
  Activity,
  PieChart as PieChartIcon,
  Globe,
  Filter,
  Calendar,
  Pill,
  Stethoscope,
  AlertTriangle
} from 'lucide-react';
import { Button } from '../ui/Button';
import { Select } from '../ui/Select';
import { cn } from '../../utils/cn';
import { colors } from '../../theme/colors';

// Import our new UI components
import { MedicationSection } from './MedicationSection';
import { MetricCard } from '../ui/MetricCard';
import { ChartContainer } from '../ui/ChartContainer';
import { CampaignCard } from '../ui/CampaignCard';


export function Dashboard() {
  const [isLoading, setIsLoading] = useState(true);
  const [timeframe, setTimeframe] = useState('6m');
  const [activeTab, setActiveTab] = useState('overview');
  const [selectedCampaignId, setSelectedCampaignId] = useState<string | undefined>();
  const [dbError, setDbError] = useState<string | null>(null);
  
  // Get sample campaign data
  const [campaigns, setCampaigns] = useState(getSampleCampaigns());
  
  // Get timeframe for medication section
  const getTimeframeForMedicationSection = () => {
    return {
      daysBefore: timeframe === '1m' ? 30 : timeframe === '3m' ? 90 : timeframe === '6m' ? 180 : 365,
      daysAfter: 0
    };
  };
  
  // Handle campaign selection from campaign cards
  // Note: We no longer switch tabs since only Overview is shown
  const handleCampaignSelect = (campaignId: string) => {
    setSelectedCampaignId(campaignId);
  };

  useEffect(() => {
    // Simulate loading data
    const timer = setTimeout(() => {
      setIsLoading(false);
    }, 1000);
    
    return () => clearTimeout(timer);
  }, []);
  
  // Get metrics from sample data
  const metricsSummary = getSampleCampaignMetricsSummary();
  
  const metrics = {
    activeCampaigns: metricsSummary.campaignCount,
    totalProviders: 150000,
    scriptLift: `${metricsSummary.averageScriptLift.toFixed(1)}%`,
    totalPrescriptions: 3750000, // 150,000 providers * 25 prescriptions avg
    marketShareChange: `${metricsSummary.averageMarketShareChange.toFixed(1)}%`,
    providerEngagement: '42.5%',
    identityMatched: 127500, // 85% of 150,000
    identityMatchRate: '85.0%',
    // Add trend data
    campaignsTrend: [1, 2, 2, 3, 3, metricsSummary.campaignCount],
    providersTrend: [105000, 117000, 129000, 138000, 145000, 150000],
    // Add change values
    campaignsChange: '+1',
    providersChange: '+3.3%'
  };

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-full space-y-4">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
        <p className="text-gray-500">Loading dashboard data...</p>
      </div>
    );
  }

  return (
    <div className="space-y-10 pb-10 max-w-[1600px] mx-auto">
      {/* Header with Filters */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Campaign Performance</h1>
          <p className="text-gray-500 mt-1">Track and analyze marketing campaign metrics</p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center">
            <Calendar className="h-4 w-4 text-gray-400 mr-2" />
            <Select
              options={[
                { value: '1m', label: 'Last Month' },
                { value: '3m', label: 'Last 3 Months' },
                { value: '6m', label: 'Last 6 Months' },
                { value: '1y', label: 'Last Year' },
              ]}
              value={timeframe}
              onChange={(value) => {
                console.log('Changing timeframe to', value);
                setTimeframe(value);
              }}
            />
          </div>
          <Link to="/campaigns/create">
            <Button variant="default" leftIcon={<Plus className="h-4 w-4" />}>
              New Campaign
            </Button>
          </Link>
        </div>
      </div>

      {/* Tab Navigation - Only Overview tab is shown */}
      <div className="border-b border-gray-200 overflow-x-auto pb-px">
        <div className="flex min-w-max space-x-2 sm:space-x-6">
          <button
            onClick={() => setActiveTab('overview')}
            className="py-2 px-2 sm:py-3 sm:px-0 font-medium text-xs sm:text-sm border-b-2 transition-colors min-w-[4rem] border-primary-500 text-primary-600"
          >
            Overview
          </button>
        </div>
      </div>

      {/* Database Error Notification */}
      {dbError && (
        <div className="bg-danger-50 border border-danger-200 rounded-lg p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <AlertTriangle className="h-5 w-5 text-danger-500" />
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-danger-800">Database Error</h3>
              <div className="mt-2 text-sm text-danger-700">
                <p>{dbError}</p>
              </div>
              <div className="mt-4">
                <div className="-mx-2 -my-1.5 flex">
                  <button
                    type="button"
                    className="bg-danger-50 px-2 py-1.5 rounded-md text-sm font-medium text-danger-800 hover:bg-danger-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-danger-500"
                  >
                    View Migration Console
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Overview Tab Content - Always shown */}
      {(
        <>
          {/* Key Metrics Cards with real data */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            <MetricCard
              title="Active Campaigns"
              value={metrics.activeCampaigns}
              changeValue={metrics.campaignsChange}
              changeType="increase"
              icon={<Target className="h-5 w-5" />}
              variant="glass"
              trend={metrics.campaignsTrend}
            />
            <MetricCard
              title="Script Lift"
              value={metrics.scriptLift}
              subValue="across all campaigns"
              changeValue="+3.2%"
              changeType="increase"
              icon={<Pill className="h-5 w-5" />}
              variant="gradient"
              trend={[12, 15, 14, 18, 16, 20]}
            />
            <MetricCard
              title="Provider Database"
              value={metrics.totalProviders.toLocaleString()}
              subValue="total providers"
              changeValue={metrics.providersChange}
              changeType="increase"
              icon={<Stethoscope className="h-5 w-5" />}
              trend={metrics.providersTrend}
            />
            <MetricCard
              title="Market Share Gain"
              value={metrics.marketShareChange}
              subValue="category share increase"
              changeValue="+1.2%"
              changeType="increase"
              icon={<Activity className="h-5 w-5" />}
              variant="gradient"
              trend={[3.2, 3.8, 4.5, 5.1, 5.8, 6.2]}
            />
          </div>

          {/* Charts with dynamic data based on timeframe */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <ChartContainer
              title="Campaign Performance"
              subtitle="Impressions, clicks, and prescriptions over time"
              data={getSampleCampaignPerformanceData(timeframe as any)}
              type="line"
              height={320}
              xAxisKey="month"
              yAxisKeys={["impressions", "clicks", "prescriptions"]}
              labels={{
                impressions: "Ad Impressions",
                clicks: "Ad Clicks",
                prescriptions: "New Prescriptions"
              }}
              downloadable
            />

            <ChartContainer
              title="Prescription Impact"
              subtitle="Campaign influence on prescription behavior"
              data={getSampleCampaignComparisonData()}
              type="bar"
              height={320}
              xAxisKey="campaign"
              yAxisKeys={["scriptLift", "clicks"]}
              labels={{
                scriptLift: "Script Lift %",
                clicks: "Click Engagement"
              }}
              downloadable
            />
          </div>

          {/* Distribution Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <ChartContainer
              title="Provider Specialty Distribution"
              subtitle="Breakdown of targeted providers by specialty"
              data={getSampleSpecialtyDistributionData()}
              type="pie"
              height={300}
              xAxisKey="name"
              yAxisKeys={["value"]}
              labels={{
                value: "Percentage"
              }}
            />

            <ChartContainer
              title="Geographic Targeting Distribution"
              subtitle="Campaign reach by geographic region"
              data={getSampleRegionDistributionData()}
              type="pie"
              height={300}
              xAxisKey="name"
              yAxisKeys={["value"]}
              labels={{
                value: "Percentage"
              }}
            />
          </div>
          
          {/* Patient Impact Analysis Section */}
          <div className="mt-10">
            <div className="flex items-baseline justify-between mb-6">
              <div>
                <h2 className="text-xl font-bold text-gray-900">Patient Impact Analysis</h2>
                <p className="text-sm text-gray-500 mt-1">Campaign effectiveness on patient outcomes</p>
              </div>
            </div>
            
            <div className="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <ChartContainer
                title="Patient Reach & Script Lift by Campaign"
                subtitle="Comparing patient outcomes across campaigns"
                data={getSampleCampaignComparisonData()}
                type="bar"
                height={400}
                xAxisKey="campaign"
                yAxisKeys={["scriptLift", "providerReach"]}
                labels={{
                  scriptLift: "Script Lift %",
                  providerReach: "Provider Reach"
                }}
                downloadable
              />
            </div>
          </div>
        </>
      )}

      {/* Campaign Tab Content - Removed as requested */}

      {/* Provider Analysis Tab Content */}
      {activeTab === 'providers' && (
        <>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <ChartContainer
              title="Provider Specialty Distribution"
              subtitle="Target audience by medical specialty"
              data={getSampleSpecialtyDistributionData()}
              type="pie"
              height={350}
              xAxisKey="name"
              yAxisKeys={["value"]}
              labels={{
                value: "Percentage"
              }}
            />

            <ChartContainer
              title="Provider Engagement by Specialty"
              subtitle="Campaign effectiveness across specialties"
              data={[
                { specialty: 'Primary Care', engagement: 58, prescriptions: 1250 },
                { specialty: 'Cardiology', engagement: 72, prescriptions: 980 },
                { specialty: 'Endocrinology', engagement: 68, prescriptions: 780 },
                { specialty: 'Psychiatry', engagement: 41, prescriptions: 540 },
                { specialty: 'Other', engagement: 35, prescriptions: 420 },
              ]}
              type="bar"
              height={350}
              xAxisKey="specialty"
              yAxisKeys={["engagement", "prescriptions"]}
              labels={{
                engagement: "Engagement Rate (%)",
                prescriptions: "Prescriptions"
              }}
            />
          </div>
        </>
      )}
      
      {/* Medication Analysis Tab Content */}
      {activeTab === 'medications' && (
        <MedicationSection 
          timeframe={getTimeframeForMedicationSection()}
          initialCampaignId={selectedCampaignId}
        />
      )}
    </div>
  );
}
