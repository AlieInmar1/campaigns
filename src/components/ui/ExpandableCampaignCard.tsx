import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { 
  ArrowRight, 
  ChevronDown, 
  ChevronUp, 
  Calendar, 
  Users, 
  MapPin, 
  Pill, 
  Activity, 
  Target, 
  TrendingUp,
  PieChart,
  ExternalLink
} from 'lucide-react';
import { cn } from '../../utils/cn';
import { Button } from './Button';

export interface ExpandableCampaignCardProps {
  id: string;
  name: string;
  target: {
    specialty?: string;
    geographic?: string;
    condition?: string;
    medication?: string;
    targetMedicationId?: string;
  };
  metrics: {
    impressions?: number;
    clicks?: number;
    conversions?: number;
    scriptLift?: string | number;
    marketShareChange?: string | number;
    providerReach?: number;
    providerCount?: number;
  };
  status: 'active' | 'draft' | 'in_progress' | 'ended' | 'paused' | 'completed' | 'pending';
  startDate?: string;
  endDate?: string;
  targeting?: {
    medicationCategory?: string;
    medications?: string[];
    excludedMedications?: string[];
    specialties?: string[];
    regions?: string[];
    prescribingVolume?: 'all' | 'high' | 'medium' | 'low';
    timeframe?: 'last_month' | 'last_quarter' | 'last_year';
  };
  audienceCounts?: {
    providers?: number;
    patients?: number;
    identityMatched?: number;
    identityMatchRate?: number;
  };
  className?: string;
  onViewResults?: (id: string) => void;
}

// Status badge component
const StatusBadge = ({ status }: { status: string }) => {
  const getStatusStyles = () => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'draft':
        return 'bg-gray-100 text-gray-800';
      case 'in_progress':
        return 'bg-amber-100 text-amber-700';
      case 'completed':
        return 'bg-blue-100 text-blue-800';
      case 'paused':
        return 'bg-yellow-100 text-yellow-800';
      case 'pending':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <span className={cn(
      'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize',
      getStatusStyles()
    )}>
      {status === 'in_progress' ? 'in progress' : status}
    </span>
  );
};

export function ExpandableCampaignCard({
  id,
  name,
  target,
  metrics,
  status,
  startDate,
  endDate,
  targeting,
  audienceCounts,
  className,
  onViewResults
}: ExpandableCampaignCardProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  
  const formattedStartDate = startDate ? new Date(startDate).toLocaleDateString() : 'Not started';
  const formattedEndDate = endDate ? new Date(endDate).toLocaleDateString() : 'Ongoing';
  
  // Determine card border color based on status
  const statusColor = {
    active: 'border-l-success-500',
    draft: 'border-l-gray-400',
    in_progress: 'border-l-amber-500',
    ended: 'border-l-gray-500',
    paused: 'border-l-warning-500',
    completed: 'border-l-gray-500',
    pending: 'border-l-blue-400',
  };
  
  // Format numbers with commas
  const formatNumber = (num: number | undefined) => {
    if (num === undefined) return 'N/A';
    return num.toLocaleString();
  };
  
  // Format percentage
  const formatPercentage = (value: string | number | undefined) => {
    if (value === undefined) return 'N/A';
    if (typeof value === 'string' && value.includes('%')) return value;
    return `${value}%`;
  };
  
  // Toggle expanded state
  const toggleExpand = () => {
    setIsExpanded(!isExpanded);
  };
  
  // Handle view results click
  const handleViewResults = () => {
    if (onViewResults) {
      onViewResults(id);
    }
  };
  
  return (
    <div 
      className={cn(
        "bg-white rounded-lg shadow-sm overflow-hidden transition-all duration-300 hover:shadow-md border-l-4",
        statusColor[status],
        className
      )}
    >
      {/* Header - Always visible */}
      <div className="px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <div className="flex items-center">
              <h3 className="text-lg font-semibold text-gray-900 truncate mr-3">{name}</h3>
              <StatusBadge status={status} />
            </div>
            <div className="mt-1 flex flex-wrap items-center text-sm text-gray-500 gap-2">
              <span className="flex items-center">
                <Calendar className="h-4 w-4 mr-1" />
                {formattedStartDate} {endDate ? `- ${formattedEndDate}` : ''}
              </span>
              {target.specialty && (
                <>
                  <span>•</span>
                  <span>{target.specialty}</span>
                </>
              )}
              {target.geographic && (
                <>
                  <span>•</span>
                  <span>{target.geographic}</span>
                </>
              )}
            </div>
          </div>
          <button
            onClick={toggleExpand}
            className="p-2 rounded-full hover:bg-gray-100 transition-colors"
            aria-expanded={isExpanded}
            aria-label={isExpanded ? "Collapse card" : "Expand card"}
          >
            {isExpanded ? (
              <ChevronUp className="h-5 w-5 text-gray-500" />
            ) : (
              <ChevronDown className="h-5 w-5 text-gray-500" />
            )}
          </button>
        </div>
      </div>
      
      {/* Expanded Content */}
      {isExpanded && (
        <div className="animate-expandDown overflow-hidden">
          {/* Audience Information */}
          <div className="px-6 py-4 bg-gray-50 border-t border-gray-100">
            <h4 className="text-sm font-semibold text-gray-700 mb-3">
              <Users className="h-4 w-4 inline-block mr-1.5" />
              Audience Targeting
            </h4>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              {/* Left Column */}
              <div className="space-y-3">
                {targeting?.medicationCategory && (
                  <div>
                    <p className="text-xs text-gray-500">Medication Category</p>
                    <p className="text-sm font-medium">{targeting.medicationCategory}</p>
                  </div>
                )}
                
                {targeting?.medications && targeting.medications.length > 0 && (
                  <div>
                    <p className="text-xs text-gray-500">Target Medications</p>
                    <p className="text-sm font-medium">{targeting.medications.join(', ')}</p>
                  </div>
                )}
                
                {targeting?.specialties && targeting.specialties.length > 0 && (
                  <div>
                    <p className="text-xs text-gray-500">Specialties</p>
                    <p className="text-sm font-medium">{targeting.specialties.join(', ')}</p>
                  </div>
                )}
              </div>
              
              {/* Right Column */}
              <div className="space-y-3">
                {targeting?.regions && targeting.regions.length > 0 && (
                  <div>
                    <p className="text-xs text-gray-500">Geographic Regions</p>
                    <p className="text-sm font-medium">{targeting.regions.join(', ')}</p>
                  </div>
                )}
                
                {targeting?.prescribingVolume && (
                  <div>
                    <p className="text-xs text-gray-500">Prescribing Volume</p>
                    <p className="text-sm font-medium capitalize">
                      {targeting.prescribingVolume === 'all' ? 'All Volumes' : `${targeting.prescribingVolume} Volume`}
                    </p>
                  </div>
                )}
                
                {targeting?.timeframe && (
                  <div>
                    <p className="text-xs text-gray-500">Timeframe</p>
                    <p className="text-sm font-medium">
                      {targeting.timeframe === 'last_month' ? 'Last Month' : 
                       targeting.timeframe === 'last_quarter' ? 'Last Quarter' : 'Last Year'}
                    </p>
                  </div>
                )}
              </div>
            </div>
            
            {/* Audience Counts */}
            {audienceCounts && (
              <div className="mt-4 pt-3 border-t border-gray-200">
                <h5 className="text-xs font-medium text-gray-600 mb-2">Audience Reach</h5>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                  <div className="bg-white px-3 py-2 rounded border border-gray-200">
                    <p className="text-xs text-gray-500">Providers</p>
                    <p className="text-base font-semibold">
                      {formatNumber(audienceCounts.providers)}
                    </p>
                  </div>
                  <div className="bg-white px-3 py-2 rounded border border-gray-200">
                    <p className="text-xs text-gray-500">Est. Patients</p>
                    <p className="text-base font-semibold">
                      {formatNumber(audienceCounts.patients)}
                    </p>
                  </div>
                  <div className="bg-white px-3 py-2 rounded border border-gray-200">
                    <p className="text-xs text-gray-500">ID Matched</p>
                    <p className="text-base font-semibold">
                      {formatNumber(audienceCounts.identityMatched)}
                    </p>
                  </div>
                  <div className="bg-white px-3 py-2 rounded border border-gray-200">
                    <p className="text-xs text-gray-500">Match Rate</p>
                    <p className="text-base font-semibold text-primary-600">
                      {audienceCounts.identityMatchRate !== undefined 
                        ? `${audienceCounts.identityMatchRate}%` 
                        : 'N/A'}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
          
          {/* Campaign Metrics */}
          <div className="px-6 py-4 border-t border-gray-100">
            <h4 className="text-sm font-semibold text-gray-700 mb-3">
              <Activity className="h-4 w-4 inline-block mr-1.5" />
              Campaign Performance
            </h4>
            
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <span className="text-xs text-gray-500 flex items-center">
                  <PieChart className="h-3 w-3 mr-1" />
                  Script Lift
                </span>
                <span className="text-base font-semibold text-success-600">
                  {metrics.scriptLift ? formatPercentage(metrics.scriptLift) : 'N/A'}
                </span>
              </div>
              <div>
                <span className="text-xs text-gray-500 flex items-center">
                  <TrendingUp className="h-3 w-3 mr-1" />
                  Market Share
                </span>
                <span className="text-base font-semibold text-success-600">
                  {metrics.marketShareChange ? formatPercentage(metrics.marketShareChange) : 'N/A'}
                </span>
              </div>
              <div>
                <span className="text-xs text-gray-500">Impressions</span>
                <span className="text-base font-semibold">
                  {formatNumber(metrics.impressions)}
                </span>
              </div>
              <div>
                <span className="text-xs text-gray-500">Clicks</span>
                <span className="text-base font-semibold">
                  {formatNumber(metrics.clicks)}
                </span>
              </div>
            </div>
          </div>
          
          {/* Footer with actions */}
          <div className="px-6 py-3 bg-gray-50 border-t border-gray-100 flex flex-wrap justify-between gap-2">
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={handleViewResults}
                leftIcon={<Activity className="h-4 w-4" />}
              >
                View Results
              </Button>
              <Link to={`/campaigns/${id}`}>
                <Button 
                  variant="outline" 
                  size="sm"
                  leftIcon={<ExternalLink className="h-4 w-4" />}
                >
                  Full Details
                </Button>
              </Link>
            </div>
            <Link to={`/campaigns/${id}/edit`}>
              <Button 
                variant="ghost" 
                size="sm"
              >
                Edit Settings
              </Button>
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}
