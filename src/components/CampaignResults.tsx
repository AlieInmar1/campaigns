import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { BarChart3, TrendingUp, Users, Target, AlertCircle, ArrowLeft, ChevronDown, Clock, Globe, Activity, Brain, Microscope, HeartPulse } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { Dialog, Transition } from '@headlessui/react';

interface CampaignResult {
  id: string;
  campaign_id: string;
  metrics: any;
  engagement_metrics: any;
  demographic_metrics: any;
  roi_metrics: any;
  prescription_metrics: any;
  report_date: string;
  created_at: string;
}

export function CampaignResults() {
  const { id } = useParams<{ id: string }>();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<CampaignResult | null>(null);
  const [campaign, setCampaign] = useState<any | null>(null);
  const [selectedMetric, setSelectedMetric] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [historicalData, setHistoricalData] = useState<any[]>([]);

  useEffect(() => {
    if (id) {
      fetchCampaignData();
      fetchHistoricalData();
    }
  }, [id]);

  const fetchHistoricalData = async () => {
    try {
      const { data, error } = await supabase
        .from('campaign_results')
        .select('*')
        .eq('campaign_id', id)
        .order('report_date', { ascending: true });

      if (error) throw error;
      setHistoricalData(data || []);
    } catch (error) {
      console.error('Error fetching historical data:', error);
    }
  };

  const openMetricDetails = (metric: string) => {
    setSelectedMetric(metric);
    setIsModalOpen(true);
  };

  const fetchCampaignData = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data: campaignData, error: campaignError } = await supabase
        .from('campaigns')
        .select('*')
        .eq('id', id)
        .single();

      if (campaignError) throw campaignError;
      setCampaign(campaignData);

      const { data: resultsData, error: resultsError } = await supabase
        .from('campaign_results')
        .select('*')
        .eq('campaign_id', id)
        .order('report_date', { ascending: false })
        .limit(1);

      if (resultsError) throw resultsError;
      setResult(resultsData && resultsData.length > 0 ? resultsData[0] : null);
    } catch (error) {
      console.error('Error fetching campaign data:', error);
      setError('Failed to load campaign data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-md p-4">
        <div className="flex">
          <AlertCircle className="h-5 w-5 text-red-400" aria-hidden="true" />
          <div className="ml-3">
            <p className="text-sm text-red-700">{error}</p>
          </div>
        </div>
      </div>
    );
  }

  if (!campaign) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">Campaign not found</p>
      </div>
    );
  }

  return (
    <div className="space-y-6 pb-12">
      <Link
        to="/"
        className="inline-flex items-center text-sm font-medium text-gray-500 hover:text-gray-700 mb-4"
      >
        <ArrowLeft className="h-4 w-4 mr-1" />
        Back to Campaigns
      </Link>

      <div className="bg-white shadow-sm rounded-lg p-6">
        <div className="bg-gradient-to-r from-indigo-700 to-blue-700 rounded-lg p-8 text-white mb-6">
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center">
              <Target className="h-8 w-8 text-white mr-3" />
              <div>
                <h2 className="text-3xl font-bold">{campaign.name}</h2>
                <p className="text-blue-100 mt-1">
                  {campaign.target_specialty} • {campaign.target_geographic_area}
                </p>
              </div>
            </div>
            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${
              campaign.status === 'active' ? 'bg-green-400 text-white' :
              campaign.status === 'draft' ? 'bg-gray-100 text-gray-600' :
              'bg-yellow-400 text-white'
            }`}>
              {campaign.status}
            </span>
          </div>

          {result && (
            <div className="grid grid-cols-4 gap-6 mt-8">
              <div className="bg-white/10 rounded-lg p-4">
                <div className="flex items-center text-blue-100 mb-2">
                  <Activity className="h-5 w-5 mr-2" />
                  <span>Engagement Rate</span>
                </div>
                <p className="text-4xl font-bold">
                  {((result.metrics.clicks / result.metrics.impressions) * 100).toFixed(1)}%
                </p>
              </div>
              <div className="bg-white/10 rounded-lg p-4">
                <div className="flex items-center text-blue-100 mb-2">
                  <Brain className="h-5 w-5 mr-2" />
                  <span>Avg. Time on Page</span>
                </div>
                <p className="text-4xl font-bold">
                  {result.engagement_metrics.avg_time_on_page}s
                </p>
              </div>
              <div className="bg-white/10 rounded-lg p-4">
                <div className="flex items-center text-blue-100 mb-2">
                  <HeartPulse className="h-5 w-5 mr-2" />
                  <span>Patient Impact</span>
                </div>
                <p className="text-4xl font-bold">
                  {result.prescription_metrics.total_prescription_change}%
                </p>
              </div>
              <div className="bg-white/10 rounded-lg p-4">
                <div className="flex items-center text-blue-100 mb-2">
                  <Globe className="h-5 w-5 mr-2" />
                  <span>Market Share</span>
                </div>
                <p className="text-4xl font-bold">
                  {result.prescription_metrics.market_share_change}%
                </p>
              </div>
            </div>
          )}
        </div>

        {result ? (
          <div className="grid grid-cols-1 gap-8 lg:grid-cols-4">
            <div className="bg-white p-6 rounded-lg shadow-lg hover:shadow-xl transition-shadow duration-200 cursor-pointer"
                 onClick={() => openMetricDetails('campaign')}>
              <h3 className="text-xl font-semibold text-gray-900 mb-6 flex items-center justify-between">
                <div className="flex items-center">
                  <BarChart3 className="h-5 w-5 text-indigo-500 mr-2" />
                  Campaign Metrics
                </div>
                <ChevronDown className="h-5 w-5 text-gray-400" />
              </h3>
              <dl className="space-y-4">
                <div>
                  <dt className="text-sm font-medium text-gray-500">Impressions</dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    {result.metrics.impressions.toLocaleString()}
                    <span className="text-sm text-green-600 ml-2">+12.5%</span>
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">Clicks</dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    {result.metrics.clicks.toLocaleString()}
                    <span className="text-sm text-green-600 ml-2">+8.3%</span>
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">Conversions</dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    {result.metrics.conversions.toLocaleString()}
                    <span className="text-sm text-green-600 ml-2">+15.7%</span>
                  </dd>
                </div>
                <div className="pt-4">
                  <ResponsiveContainer width="100%" height={100}>
                    <AreaChart data={historicalData}>
                      <defs>
                        <linearGradient id="colorImpressions" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#4F46E5" stopOpacity={0.1}/>
                          <stop offset="95%" stopColor="#4F46E5" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <Area type="monotone" dataKey="metrics.impressions" stroke="#4F46E5" fillOpacity={1} fill="url(#colorImpressions)" />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </dl>
            </div>

            <div className="bg-white p-6 rounded-lg shadow-lg hover:shadow-xl transition-shadow duration-200 cursor-pointer"
                 onClick={() => openMetricDetails('adPerformance')}>
              <h3 className="text-xl font-semibold text-gray-900 mb-6 flex items-center justify-between">
                <div className="flex items-center">
                  <Activity className="h-5 w-5 text-indigo-500 mr-2" />
                  Ad Performance
                </div>
                <ChevronDown className="h-5 w-5 text-gray-400" />
              </h3>
              <dl className="space-y-4">
                {result && result.metrics && result.metrics.ad_performance ? (
                  <>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">CTR</dt>
                      <dd className="mt-1 text-3xl font-semibold text-gray-900">
                        {result.metrics.ad_performance.ctr}%
                        <span className="text-sm text-green-600 ml-2">+1.8%</span>
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Completion Rate</dt>
                      <dd className="mt-1 text-3xl font-semibold text-gray-900">
                        {result.metrics.ad_performance.completion_rate}%
                        <span className="text-sm text-green-600 ml-2">+3.2%</span>
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Brand Awareness Lift</dt>
                      <dd className="mt-1 text-3xl font-semibold text-gray-900">
                        {result.metrics.ad_performance.brand_awareness_lift}%
                        <span className="text-sm text-green-600 ml-2">+5.4%</span>
                      </dd>
                    </div>
                  </>
                ) : (
                  <div className="text-center py-4">
                    <p className="text-gray-500">No ad performance data available</p>
                  </div>
                )}
                <div className="pt-4">
                  <ResponsiveContainer width="100%" height={100}>
                    <LineChart data={historicalData}>
                      <Line type="monotone" dataKey="metrics.ad_performance.ctr" stroke="#F59E0B" strokeWidth={2} dot={false} />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </dl>
            </div>

            <div className="bg-white p-6 rounded-lg shadow-lg hover:shadow-xl transition-shadow duration-200 cursor-pointer"
                 onClick={() => openMetricDetails('roi')}>
              <h3 className="text-xl font-semibold text-gray-900 mb-6 flex items-center justify-between">
                <div className="flex items-center">
                  <TrendingUp className="h-5 w-5 text-indigo-500 mr-2" />
                  ROI Metrics
                </div>
                <ChevronDown className="h-5 w-5 text-gray-400" />
              </h3>
              <dl className="space-y-4">
                <div>
                  <dt className="text-sm font-medium text-gray-500">Total Campaign Cost</dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    ${result.roi_metrics.total_campaign_cost.toLocaleString()}
                    <span className="text-sm text-red-600 ml-2">+5.2%</span>
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">ROI Percentage</dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    {result.roi_metrics.roi_percentage}%
                    <span className="text-sm text-green-600 ml-2">+2.8%</span>
                  </dd>
                </div>
                <div>
                  <dt className="text-sm font-medium text-gray-500">Revenue Impact</dt>
                  <dd className="mt-1 text-3xl font-semibold text-gray-900">
                    ${result.roi_metrics.estimated_revenue_impact.toLocaleString()}
                    <span className="text-sm text-green-600 ml-2">+18.4%</span>
                  </dd>
                </div>
                <div className="pt-4">
                  <ResponsiveContainer width="100%" height={100}>
                    <LineChart data={historicalData}>
                      <Line type="monotone" dataKey="roi_metrics.roi_percentage" stroke="#10B981" strokeWidth={2} dot={false} />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </dl>
            </div>

            <div className="bg-white p-6 rounded-lg shadow-lg hover:shadow-xl transition-shadow duration-200 cursor-pointer"
                 onClick={() => openMetricDetails('prescriptions')}>
              <h3 className="text-xl font-semibold text-gray-900 mb-6 flex items-center justify-between">
                <div className="flex items-center">
                  <Users className="h-5 w-5 text-indigo-500 mr-2" />
                  Prescription Impact
                </div>
                <ChevronDown className="h-5 w-5 text-gray-400" />
              </h3>
              <dl className="space-y-4">
                {result.prescription_metrics.prescription_impact ? (
                  <>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Script Lift</dt>
                      <dd className="mt-1 text-3xl font-semibold text-gray-900">
                        {result.prescription_metrics.prescription_impact.script_lift_percentage}%
                        <span className="text-sm text-green-600 ml-2">+5.7%</span>
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Baseline vs Current</dt>
                      <dd className="mt-1 text-2xl font-semibold text-gray-900">
                        {result.prescription_metrics.prescription_impact.baseline_monthly_scripts.toLocaleString()} → {result.prescription_metrics.prescription_impact.current_monthly_scripts.toLocaleString()}
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Projected Annual</dt>
                      <dd className="mt-1 text-3xl font-semibold text-gray-900">
                        {result.prescription_metrics.prescription_impact.projected_annual_scripts.toLocaleString()}
                      </dd>
                    </div>
                  </>
                ) : (
                  <>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">New Prescriptions</dt>
                      <dd className="mt-1 text-3xl font-semibold text-gray-900">
                        {result.prescription_metrics.new_prescriptions.toLocaleString()}
                        <span className="text-sm text-green-600 ml-2">+21.3%</span>
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Market Share Change</dt>
                      <dd className="mt-1 text-3xl font-semibold text-gray-900">
                        {result.prescription_metrics.market_share_change}%
                        <span className="text-sm text-green-600 ml-2">+1.2%</span>
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">Patient Adherence Rate</dt>
                      <dd className="mt-1 text-3xl font-semibold text-gray-900">
                        {result.prescription_metrics.patient_adherence_rate}%
                        <span className="text-sm text-green-600 ml-2">+4.5%</span>
                      </dd>
                    </div>
                  </>
                )}
                <div className="pt-4">
                  <ResponsiveContainer width="100%" height={100}>
                    <AreaChart data={historicalData}>
                      <defs>
                        <linearGradient id="colorPrescriptions" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#10B981" stopOpacity={0.1}/>
                          <stop offset="95%" stopColor="#10B981" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <Area type="monotone" dataKey="prescription_metrics.new_prescriptions" stroke="#10B981" fillOpacity={1} fill="url(#colorPrescriptions)" />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </dl>
            </div>
          </div>
        ) : (
          <div className="text-center py-12">
            <p className="text-gray-500">No results available yet</p>
          </div>
        )}
      </div>

      <Transition show={isModalOpen} as={React.Fragment}>
        <Dialog
          as="div"
          className="fixed inset-0 z-10 overflow-y-auto"
          onClose={() => setIsModalOpen(false)}
        >
          <div className="min-h-screen px-4 text-center">
            <Transition.Child
              as={React.Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0"
              enterTo="opacity-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100"
              leaveTo="opacity-0"
            >
              <div className="fixed inset-0 bg-black opacity-30" />
            </Transition.Child>

            <span
              className="inline-block h-screen align-middle"
              aria-hidden="true"
            >
              &#8203;
            </span>

            <Transition.Child
              as={React.Fragment}
              enter="ease-out duration-300"
              enterFrom="opacity-0 scale-95"
              enterTo="opacity-100 scale-100"
              leave="ease-in duration-200"
              leaveFrom="opacity-100 scale-100"
              leaveTo="opacity-0 scale-95"
            >
              <div className="inline-block w-full max-w-4xl p-6 my-8 overflow-hidden text-left align-middle transition-all transform bg-white shadow-xl rounded-2xl">
                <div className="absolute top-0 right-0 pt-6 pr-6">
                  <button
                    type="button"
                    className="text-gray-400 hover:text-gray-500"
                    onClick={() => setIsModalOpen(false)}
                  >
                    <span className="sr-only">Close</span>
                    <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>

                {selectedMetric === 'campaign' && (
                  <div className="mt-2">
                    <Dialog.Title
                      as="h3"
                      className="text-2xl font-bold text-gray-900 mb-8"
                    >
                      Campaign Performance Details
                    </Dialog.Title>
                    
                    <div className="space-y-8">
                      <div>
                        <h4 className="text-lg font-medium text-gray-900 mb-4">Engagement Trends</h4>
                        <div className="h-80">
                          <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={historicalData}>
                              <CartesianGrid strokeDasharray="3 3" />
                              <XAxis dataKey="report_date" />
                              <YAxis />
                              <Tooltip />
                              <Line type="monotone" dataKey="metrics.impressions" name="Impressions" stroke="#4F46E5" />
                              <Line type="monotone" dataKey="metrics.clicks" name="Clicks" stroke="#10B981" />
                              <Line type="monotone" dataKey="metrics.conversions" name="Conversions" stroke="#F59E0B" />
                            </LineChart>
                          </ResponsiveContainer>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-6">
                        <div>
                          <h4 className="text-lg font-medium text-gray-900 mb-4">Engagement Breakdown</h4>
                          <dl className="space-y-4">
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Click-through Rate</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                {((result.metrics.clicks / result.metrics.impressions) * 100).toFixed(2)}%
                              </dd>
                            </div>
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Conversion Rate</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                {((result.metrics.conversions / result.metrics.clicks) * 100).toFixed(2)}%
                              </dd>
                            </div>
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Bounce Rate</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                {result.engagement_metrics.bounce_rate}%
                              </dd>
                            </div>
                          </dl>
                        </div>

                        <div>
                          <h4 className="text-lg font-medium text-gray-900 mb-4">Engagement Quality</h4>
                          <dl className="space-y-4">
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Avg. Time on Page</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                {result.engagement_metrics.avg_time_on_page}s
                              </dd>
                            </div>
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Return Visits</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                {result.engagement_metrics.return_visits}
                              </dd>
                            </div>
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Resource Downloads</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                {result.engagement_metrics.resource_downloads}
                              </dd>
                            </div>
                          </dl>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {selectedMetric === 'roi' && (
                  <div className="mt-2">
                    <Dialog.Title
                      as="h3"
                      className="text-2xl font-bold text-gray-900 mb-8"
                    >
                      ROI Analysis
                    </Dialog.Title>
                    
                    <div className="space-y-8">
                      <div>
                        <h4 className="text-lg font-medium text-gray-900 mb-4">ROI Trends</h4>
                        <div className="h-80">
                          <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={historicalData}>
                              <CartesianGrid strokeDasharray="3 3" />
                              <XAxis dataKey="report_date" />
                              <YAxis />
                              <Tooltip />
                              <Line type="monotone" dataKey="roi_metrics.roi_percentage" name="ROI %" stroke="#4F46E5" />
                              <Line type="monotone" dataKey="roi_metrics.estimated_revenue_impact" name="Revenue Impact" stroke="#10B981" />
                            </LineChart>
                          </ResponsiveContainer>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-6">
                        <div>
                          <h4 className="text-lg font-medium text-gray-900 mb-4">Cost Analysis</h4>
                          <dl className="space-y-4">
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Cost per Click</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                ${result.roi_metrics.cost_per_click}
                              </dd>
                            </div>
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Cost per Conversion</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                ${result.roi_metrics.cost_per_conversion}
                              </dd>
                            </div>
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Cost per Impression</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                ${result.roi_metrics.cost_per_impression}
                              </dd>
                            </div>
                          </dl>
                        </div>

                        <div>
                          <h4 className="text-lg font-medium text-gray-900 mb-4">Value Metrics</h4>
                          <dl className="space-y-4">
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Lifetime Value Impact</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                ${result.roi_metrics.lifetime_value_impact.toLocaleString()}
                              </dd>
                            </div>
                            <div>
                              <dt className="text-sm font-medium text-gray-500">Revenue per Conversion</dt>
                              <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                ${(result.roi_metrics.estimated_revenue_impact / result.metrics.conversions).toFixed(2)}
                              </dd>
                            </div>
                          </dl>
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {selectedMetric === 'prescriptions' && (
                  <div className="mt-2">
                    <Dialog.Title
                      as="h3"
                      className="text-2xl font-bold text-gray-900 mb-8"
                    >
                      Prescription Impact Analysis
                    </Dialog.Title>
                    
                    <div className="space-y-8">
                      <div>
                        <h4 className="text-lg font-medium text-gray-900 mb-4">Prescription Trends</h4>
                        <div className="h-80">
                          <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={historicalData}>
                              <CartesianGrid strokeDasharray="3 3" />
                              <XAxis dataKey="report_date" />
                              <YAxis />
                              <Tooltip />
                              <Line type="monotone" dataKey="prescription_metrics.new_prescriptions" name="New Prescriptions" stroke="#4F46E5" />
                              <Line type="monotone" dataKey="prescription_metrics.prescription_renewals" name="Renewals" stroke="#10B981" />
                            </LineChart>
                          </ResponsiveContainer>
                        </div>
                      </div>

                      <div className="grid grid-cols-2 gap-6">
                        <div>
                          <h4 className="text-lg font-medium text-gray-900 mb-4">Geographic Distribution</h4>
                          <dl className="space-y-4">
                            {Object.entries(result.prescription_metrics.prescription_by_region).map(([region, count]) => (
                              <div key={region}>
                                <dt className="text-sm font-medium text-gray-500">{region}</dt>
                                <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                  {count}
                                </dd>
                              </div>
                            ))}
                          </dl>
                        </div>

                        <div>
                          <h4 className="text-lg font-medium text-gray-900 mb-4">Specialty Distribution</h4>
                          <dl className="space-y-4">
                            {Object.entries(result.prescription_metrics.prescription_by_specialty).map(([specialty, count]) => (
                              <div key={specialty}>
                                <dt className="text-sm font-medium text-gray-500">{specialty}</dt>
                                <dd className="mt-1 text-2xl font-semibold text-gray-900">
                                  {count}
                                </dd>
                              </div>
                            ))}
                          </dl>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </Transition.Child>
          </div>
        </Dialog>
      </Transition>
    </div>
  );
}
