import React from 'react';
import { Check } from 'lucide-react';
import { cn } from '../../../utils/cn';

interface StepperProgressProps {
  steps: string[];
  currentStep: number;
  className?: string;
}

/**
 * Reusable stepper component for multi-step forms
 */
export function StepperProgress({
  steps,
  currentStep,
  className = '',
}: StepperProgressProps) {
  return (
    <div className={className}>
      <div className="flex items-center justify-between">
        {steps.map((stepName, index) => (
          <div 
            key={index}
            className={cn(
              "flex items-center justify-center w-10 h-10 rounded-full font-medium text-sm",
              currentStep === index + 1
                ? "bg-primary-500 text-white"
                : currentStep > index + 1
                  ? "bg-primary-100 text-primary-700"
                  : "bg-gray-100 text-gray-500"
            )}
          >
            {currentStep > index + 1 ? <Check size={16} /> : index + 1}
          </div>
        ))}
      </div>
      
      <div className="flex justify-between mt-2 text-sm text-gray-500">
        {steps.map((stepName, index) => (
          <span key={index} className={cn(
            currentStep === index + 1 && "font-medium text-primary-600"
          )}>
            {stepName}
          </span>
        ))}
      </div>
    </div>
  );
}
