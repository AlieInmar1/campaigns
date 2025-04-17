import React, { useState, useEffect } from 'react';
import { Users, Loader2 } from 'lucide-react';

interface IdentityMatchingResults {
  matchedProviders: number;
  totalProviders: number;
  matchPercentage: number;
}

interface IdentityMatchingProcessProps {
  providerCount: number | null;
  onMatchingComplete: (results: IdentityMatchingResults) => void;
  className?: string;
}

export interface IdentityMatchProgress {
  stage: 'not_started' | 'parsing' | 'matching' | 'analyzing' | 'complete';
  progress: number; // 0-100
  currentOperation?: string;
  results?: IdentityMatchingResults;
}

/**
 * Component to handle and visualize the identity matching process
 * This is a slightly fictionalized visualization of the matching process
 * In a real app, this would connect to an actual identity resolution service
 */
export function IdentityMatchingProcess({
  providerCount,
  onMatchingComplete,
  className = '',
}: IdentityMatchingProcessProps) {
  const [progress, setProgress] = useState<IdentityMatchProgress>({
    stage: 'not_started',
    progress: 0
  });
  
  const [showPopup, setShowPopup] = useState(true);
  
  // Start the matching process
  useEffect(() => {
    const runMatching = async () => {
      // Start with parsing stage
      setProgress({
        stage: 'parsing',
        progress: 10,
        currentOperation: 'Preparing provider data'
      });
      
      // Fast simulation of the stages to fit within 8 seconds
      setTimeout(() => {
        setProgress({
          stage: 'matching',
          progress: 30,
          currentOperation: 'Matching provider identities'
        });
        
        setTimeout(() => {
          setProgress({
            stage: 'analyzing',
            progress: 70,
            currentOperation: 'Analyzing provider data'
          });
          
          setTimeout(() => {
            // Complete the process with 98% match rate
            const results = {
              matchedProviders: Math.floor((providerCount || 1000) * 0.98),
              totalProviders: providerCount || 1000,
              matchPercentage: 98
            };
            
            setProgress({
              stage: 'complete',
              progress: 100,
              currentOperation: 'Providers successfully matched',
              results
            });
            
            // After 8 seconds total, close popup and advance to results
            setTimeout(() => {
              setShowPopup(false);
              onMatchingComplete(results);
            }, 1000); // Short delay to show 100% complete
            
          }, 2500); // 2.5s for analyzing
        }, 2500); // 2.5s for matching
      }, 2000); // 2s for parsing
    };
    
    runMatching();
  }, [providerCount, onMatchingComplete]);

  // If matching is complete, show the results
  if (progress.stage === 'complete' && progress.results) {
    return (
      <div className={`animate-fadeIn ${className}`}>
        <h3 className="text-lg font-semibold text-gray-800 mb-4">
          <Users className="inline-block mr-2 text-primary-500" size={20} />
          Provider Identity Matching
        </h3>
        
        <div className="space-y-4 mb-6">
          <div className="bg-green-50 rounded-lg p-4 border border-green-100">
            <div className="flex justify-between items-center mb-2">
              <h4 className="text-sm font-semibold text-green-800">Match Results</h4>
              <span className="bg-green-100 text-green-800 text-xs font-medium px-2.5 py-0.5 rounded-full">
                {progress.results.matchPercentage}% Match Rate
              </span>
            </div>
            
            <div className="grid grid-cols-2 gap-6 mt-2">
              <div className="text-center">
                <div className="text-3xl font-bold text-green-700">
                  {progress.results.matchedProviders.toLocaleString()}
                </div>
                <div className="text-sm text-green-600">Matched Providers</div>
              </div>
              
              <div className="text-center">
                <div className="text-3xl font-bold text-green-700">
                  {progress.results.totalProviders.toLocaleString()}
                </div>
                <div className="text-sm text-green-600">Total Providers</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Show the popup with matching progress
  if (showPopup) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
        <div className="bg-white p-6 rounded-lg shadow-lg max-w-md w-full">
          <h3 className="text-lg font-medium mb-4">
            Provider Identity Matching
          </h3>
          
          <div className="mb-4">
            <div className="relative pt-1">
              <div className="flex mb-2 items-center justify-between">
                <div>
                  <span className="text-xs font-semibold inline-block py-1 px-2 uppercase rounded-full bg-primary-50 text-primary-600">
                    {progress.stage.replace('_', ' ').replace(/\w\S*/g, w => 
                      w.charAt(0).toUpperCase() + w.substring(1).toLowerCase()
                    )}
                  </span>
                </div>
                <div className="text-right">
                  <span className="text-xs font-semibold inline-block text-primary-600">
                    {progress.progress}%
                  </span>
                </div>
              </div>
              <div className="overflow-hidden h-2 mb-4 text-xs flex rounded bg-primary-50">
                <div 
                  style={{ width: `${progress.progress}%` }} 
                  className="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-primary-500 transition-all duration-500"
                ></div>
              </div>
            </div>
            
            <p className="text-sm text-gray-600 flex items-center">
              <Loader2 className="h-4 w-4 animate-spin text-primary-600 mr-2" />
              {progress.currentOperation}
            </p>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
