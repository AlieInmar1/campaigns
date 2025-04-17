import React, { useState, useEffect, useCallback } from 'react';
import { useTargetingForm, TargetingState } from '../../hooks/useTargetingForm';
import { TargetingForm } from '../campaigns/targeting/TargetingForm';
import { EnhancedTargetingForm } from '../campaigns/targeting/EnhancedTargetingForm';
import { ProviderMatchSummary } from '../campaigns/targeting/ProviderMatchSummary';
import { ChevronRight, Copy, RefreshCw, ArrowLeftRight, Save } from 'lucide-react';
import { Button } from '../ui/Button';
import { cn } from '../../utils/cn';
import { ChartContainer } from '../ui/ChartContainer';

// Default targeting state for the baseline
const DEFAULT_BASELINE_TARGETING: TargetingState = {
  name: 'Baseline Audience',
  medicationCategory: 'Statins',
  medications: ['med-31', 'med-33'], // Atorvastatin, Rosuvastatin
  excludedMedications: [],
  specialties: ['Cardiology'],
  regions: ['region-1', 'region-2'], // Northeast, Mid-Atlantic
  prescribingVolume: 'high',
  timeframe: 'last_quarter',
  gender: 'all'
};

// Helper text for each step
const STEP_HELP_TEXT = {
  1: "Select medications that your target providers prescribe. Adding more medications will increase your audience size.",
  2: "Choose provider specialties and prescribing volume to refine your audience.",
  3: "Select geographic regions to target specific areas."
};

export function AudienceExplorer() {
  // Enhanced filtering is hidden for now
  const useEnhancedFiltering = false;
  
  // State for the baseline (left side)
  const {
    targeting: baselineTargeting,
    updateTargeting: updateBaselineTargeting,
    providerCount: baselineProviderCount,
    potentialReach: baselinePotentialReach,
    matchingProviderIds: baselineProviderIds,
    isCalculating: isBaselineCalculating,
    error: baselineError,
    calculateProviderCounts: calculateBaselineCounts,
    resetTargeting: resetBaselineTargeting
  } = useTargetingForm();
  
  // State for the comparison (right side)
  const {
    targeting: comparisonTargeting,
    updateTargeting: updateComparisonTargeting,
    providerCount: comparisonProviderCount,
    potentialReach: comparisonPotentialReach,
    matchingProviderIds: comparisonProviderIds,
    isCalculating: isComparisonCalculating,
    error: comparisonError,
    calculateProviderCounts: calculateComparisonCounts,
    resetTargeting: resetComparisonTargeting
  } = useTargetingForm();
  
  // State for the current step in the wizard
  const [currentStep, setCurrentStep] = useState<number>(1);
  
  // State for comparison metrics
  const [comparisonMetrics, setComparisonMetrics] = useState<{
    providerCountDiff: number;
    providerCountPercent: number;
    reachDiff: number;
    reachPercent: number;
  }>({
    providerCountDiff: 0,
    providerCountPercent: 0,
    reachDiff: 0,
    reachPercent: 0
  });
  
  // Initialize with default targeting
  useEffect(() => {
    // Set baseline targeting
    Object.entries(DEFAULT_BASELINE_TARGETING).forEach(([key, value]) => {
      updateBaselineTargeting(key as keyof TargetingState, value);
    });
    
    // Copy to comparison targeting
    Object.entries(DEFAULT_BASELINE_TARGETING).forEach(([key, value]) => {
      updateComparisonTargeting(key as keyof TargetingState, value);
    });
    
    // Calculate provider counts for both sides
    setTimeout(() => {
      calculateBaselineCounts();
      calculateComparisonCounts();
    }, 500);
  }, []);
  
  // Update comparison metrics when provider counts change
  useEffect(() => {
    if (baselineProviderCount && baselineProviderCount > 0 && comparisonProviderCount && baselinePotentialReach && comparisonPotentialReach) {
      const providerCountDiff = comparisonProviderCount - baselineProviderCount;
      const providerCountPercent = baselineProviderCount > 0 
        ? (providerCountDiff / baselineProviderCount) * 100 
        : 0;
      
      const reachDiff = comparisonPotentialReach - baselinePotentialReach;
      const reachPercent = baselinePotentialReach > 0 
        ? (reachDiff / baselinePotentialReach) * 100 
        : 0;
      
      setComparisonMetrics({
        providerCountDiff,
        providerCountPercent,
        reachDiff,
        reachPercent
      });
    }
  }, [baselineProviderCount, comparisonProviderCount, baselinePotentialReach, comparisonPotentialReach]);
  
  // Copy baseline to comparison
  const copyBaselineToComparison = useCallback(() => {
    Object.entries(baselineTargeting).forEach(([key, value]) => {
      updateComparisonTargeting(key as keyof TargetingState, value);
    });
    
    // Recalculate comparison counts
    setTimeout(() => {
      calculateComparisonCounts();
    }, 100);
  }, [baselineTargeting, updateComparisonTargeting, calculateComparisonCounts]);
  
  // Copy comparison to baseline
  const copyComparisonToBaseline = useCallback(() => {
    Object.entries(comparisonTargeting).forEach(([key, value]) => {
      updateBaselineTargeting(key as keyof TargetingState, value);
    });
    
    // Recalculate baseline counts
    setTimeout(() => {
      calculateBaselineCounts();
    }, 100);
  }, [comparisonTargeting, updateBaselineTargeting, calculateBaselineCounts]);
  
  // Reset both to defaults
  const resetBoth = useCallback(() => {
    // Reset baseline targeting
    resetBaselineTargeting();
    Object.entries(DEFAULT_BASELINE_TARGETING).forEach(([key, value]) => {
      updateBaselineTargeting(key as keyof TargetingState, value);
    });
    
    // Reset comparison targeting
    resetComparisonTargeting();
    Object.entries(DEFAULT_BASELINE_TARGETING).forEach(([key, value]) => {
      updateComparisonTargeting(key as keyof TargetingState, value);
    });
    
    // Calculate provider counts for both sides
    setTimeout(() => {
      calculateBaselineCounts();
      calculateComparisonCounts();
    }, 500);
  }, [resetBaselineTargeting, resetComparisonTargeting, updateBaselineTargeting, updateComparisonTargeting, calculateBaselineCounts, calculateComparisonCounts]);
  
  // Move to next step
  const nextStep = useCallback(() => {
    if (currentStep < 3) {
      setCurrentStep(currentStep + 1);
    }
  }, [currentStep]);
  
  // Move to previous step
  const prevStep = useCallback(() => {
    if (currentStep > 1) {
      setCurrentStep(currentStep - 1);
    }
  }, [currentStep]);
  
  
  // Generate comparison chart data
  const getComparisonChartData = useCallback(() => {
    return [
      {
        name: 'Baseline',
        providers: baselineProviderCount,
        reach: baselinePotentialReach,
      },
      {
        name: 'Comparison',
        providers: comparisonProviderCount,
        reach: comparisonPotentialReach,
      }
    ];
  }, [baselineProviderCount, baselinePotentialReach, comparisonProviderCount, comparisonPotentialReach]);
  
  // Generate specialty distribution data
  const getSpecialtyDistributionData = useCallback(() => {
    // This would ideally come from real data, but for now we'll generate mock data
    const baselineSpecialties = baselineTargeting.specialties || [];
    const comparisonSpecialties = comparisonTargeting.specialties || [];
    
    // Create a combined list of all specialties
    const allSpecialties = [...new Set([...baselineSpecialties, ...comparisonSpecialties])];
    
    return allSpecialties.map(specialty => {
      const inBaseline = baselineSpecialties.includes(specialty);
      const inComparison = comparisonSpecialties.includes(specialty);
      
      // Generate realistic percentages
      const baselinePercent = inBaseline ? Math.floor(Math.random() * 30) + 20 : 0;
      const comparisonPercent = inComparison ? Math.floor(Math.random() * 30) + 20 : 0;
      
      return {
        specialty,
        baseline: baselinePercent,
        comparison: comparisonPercent,
        difference: comparisonPercent - baselinePercent
      };
    });
  }, [baselineTargeting.specialties, comparisonTargeting.specialties]);
  
  return (
    <div className="max-w-7xl mx-auto p-6 bg-white rounded-lg shadow">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-xl font-semibold">Audience Explorer</h2>
        
        <div>
          <Button
            variant="outline"
            leftIcon={<RefreshCw className="h-4 w-4" />}
            onClick={resetBoth}
            size="sm"
          >
            Reset All
          </Button>
        </div>
      </div>
      
      {/* Step indicator */}
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center">
            <div className={`rounded-full h-8 w-8 flex items-center justify-center ${
              currentStep >= 1 ? 'bg-primary-600 text-white' : 'bg-gray-200 text-gray-600'
            }`}>
              1
            </div>
            <div className={`h-1 w-12 ${
              currentStep >= 2 ? 'bg-primary-600' : 'bg-gray-200'
            }`}></div>
            <div className={`rounded-full h-8 w-8 flex items-center justify-center ${
              currentStep >= 2 ? 'bg-primary-600 text-white' : 'bg-gray-200 text-gray-600'
            }`}>
              2
            </div>
            <div className={`h-1 w-12 ${
              currentStep >= 3 ? 'bg-primary-600' : 'bg-gray-200'
            }`}></div>
            <div className={`rounded-full h-8 w-8 flex items-center justify-center ${
              currentStep >= 3 ? 'bg-primary-600 text-white' : 'bg-gray-200 text-gray-600'
            }`}>
              3
            </div>
          </div>
          <div className="text-sm text-gray-500">
            Step {currentStep} of 3: {
              currentStep === 1 ? 'Medication Selection' :
              currentStep === 2 ? 'Provider Criteria' :
              'Geographic Targeting'
            }
          </div>
        </div>
        
        {/* Help text for current step */}
        <div className="mt-3 p-3 bg-blue-50 border border-blue-100 rounded-md text-sm text-blue-700">
          <p>{STEP_HELP_TEXT[currentStep as keyof typeof STEP_HELP_TEXT]}</p>
        </div>
      </div>
      
      {/* Comparison metrics */}
      <div className="mb-6 bg-gray-50 p-4 rounded-lg">
        <h3 className="text-lg font-medium mb-3">Audience Comparison</h3>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <div className="text-sm text-gray-500">Provider Count Difference</div>
            <div className={cn(
              "text-xl font-bold",
              comparisonMetrics.providerCountDiff > 0 ? "text-green-600" : 
              comparisonMetrics.providerCountDiff < 0 ? "text-red-600" : "text-gray-600"
            )}>
              {comparisonMetrics.providerCountDiff > 0 ? '+' : ''}
              {comparisonMetrics.providerCountDiff.toLocaleString()} 
              ({comparisonMetrics.providerCountPercent > 0 ? '+' : ''}
              {comparisonMetrics.providerCountPercent.toFixed(1)}%)
            </div>
          </div>
          <div>
            <div className="text-sm text-gray-500">Potential Reach Difference</div>
            <div className={cn(
              "text-xl font-bold",
              comparisonMetrics.reachDiff > 0 ? "text-green-600" : 
              comparisonMetrics.reachDiff < 0 ? "text-red-600" : "text-gray-600"
            )}>
              {comparisonMetrics.reachDiff > 0 ? '+' : ''}
              {comparisonMetrics.reachDiff.toLocaleString()} 
              ({comparisonMetrics.reachPercent > 0 ? '+' : ''}
              {comparisonMetrics.reachPercent.toFixed(1)}%)
            </div>
          </div>
        </div>
      </div>
      
      {/* Side by side targeting forms */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Baseline (left side) */}
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-medium">Baseline Audience</h3>
            <Button
              variant="outline"
              size="sm"
              leftIcon={<Copy className="h-4 w-4" />}
              onClick={copyBaselineToComparison}
              className="text-xs py-1 px-2 h-auto"
            >
              Copy →
            </Button>
          </div>
          
          <ProviderMatchSummary
            providerCount={baselineProviderCount}
            potentialReach={baselinePotentialReach}
            isCalculating={isBaselineCalculating}
            error={baselineError}
          />
          
          <div className="mt-4">
            {useEnhancedFiltering ? (
              <EnhancedTargetingForm
                targeting={baselineTargeting}
                updateTargeting={updateBaselineTargeting}
                step={currentStep}
              />
            ) : (
              <TargetingForm
                targeting={baselineTargeting}
                updateTargeting={updateBaselineTargeting}
                step={currentStep}
              />
            )}
          </div>
        </div>
        
        {/* Comparison (right side) */}
        <div className="border border-gray-200 rounded-lg p-4">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-medium">Comparison Audience</h3>
            <Button
              variant="outline"
              size="sm"
              leftIcon={<ArrowLeftRight className="h-4 w-4" />}
              onClick={copyComparisonToBaseline}
              className="text-xs py-1 px-2 h-auto"
            >
              ← Copy
            </Button>
          </div>
          
          <ProviderMatchSummary
            providerCount={comparisonProviderCount}
            potentialReach={comparisonPotentialReach}
            isCalculating={isComparisonCalculating}
            error={comparisonError}
          />
          
          <div className="mt-4">
            {useEnhancedFiltering ? (
              <EnhancedTargetingForm
                targeting={comparisonTargeting}
                updateTargeting={updateComparisonTargeting}
                step={currentStep}
              />
            ) : (
              <TargetingForm
                targeting={comparisonTargeting}
                updateTargeting={updateComparisonTargeting}
                step={currentStep}
              />
            )}
          </div>
        </div>
      </div>
      
      {/* Comparison charts */}
      <div className="mt-8 grid grid-cols-1 lg:grid-cols-2 gap-8">
        <ChartContainer
          title="Audience Size Comparison"
          subtitle="Provider count and potential reach"
          data={getComparisonChartData()}
          type="bar"
          height={300}
          xAxisKey="name"
          yAxisKeys={["providers", "reach"]}
          labels={{
            providers: "Provider Count",
            reach: "Potential Reach"
          }}
        />
        
        <ChartContainer
          title="Specialty Distribution"
          subtitle="Percentage of providers by specialty"
          data={getSpecialtyDistributionData()}
          type="bar"
          height={300}
          xAxisKey="specialty"
          yAxisKeys={["baseline", "comparison"]}
          labels={{
            baseline: "Baseline",
            comparison: "Comparison"
          }}
        />
      </div>
      
      {/* Navigation buttons */}
      <div className="flex justify-between mt-8">
        {currentStep > 1 ? (
          <Button
            variant="outline"
            onClick={prevStep}
          >
            Previous Step
          </Button>
        ) : (
          <div></div>
        )}
        
        {currentStep < 3 ? (
          <Button
            variant="default"
            onClick={nextStep}
          >
            Next Step <ChevronRight className="h-4 w-4 ml-2" />
          </Button>
        ) : (
          <Button
            variant="default"
          >
            Finalize Audience
          </Button>
        )}
      </div>
    </div>
  );
}
