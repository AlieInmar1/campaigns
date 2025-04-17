import React, { useState, useRef, useEffect } from 'react';
import { cn } from '../../utils/cn';
import { X, ChevronDown, Search } from 'lucide-react';

interface MultiSelectOption {
  value: string;
  label: string;
  category?: string; // Optional category for grouping/filtering
}

interface MultiSelectProps {
  options: MultiSelectOption[];
  value: string[];
  onChange: (value: string[]) => void;
  placeholder?: string;
  className?: string;
  isDisabled?: boolean;
}

export function MultiSelect({
  options,
  value,
  onChange,
  placeholder = 'Select options...',
  className,
  isDisabled = false
}: MultiSelectProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const containerRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
        setSearchTerm(''); // Clear search when closing
      }
    }

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Focus search input when dropdown opens
  useEffect(() => {
    if (isOpen && searchInputRef.current) {
      searchInputRef.current.focus();
    }
  }, [isOpen]);

  const selectedOptions = options.filter(option => value.includes(option.value));
  
  // Filter options based on search term
  const filteredOptions = options.filter(option => 
    option.label.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (option.category && option.category.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const handleToggleOption = (optionValue: string) => {
    if (value.includes(optionValue)) {
      onChange(value.filter(v => v !== optionValue));
    } else {
      onChange([...value, optionValue]);
    }
  };

  const handleRemoveOption = (optionValue: string, e: React.MouseEvent) => {
    e.stopPropagation();
    onChange(value.filter(v => v !== optionValue));
  };

  return (
    <div className="relative" ref={containerRef}>
      <div
        className={cn(
          'min-h-[38px] w-full rounded-md border border-gray-300 bg-white',
          'px-3 py-2 text-sm',
          'focus:border-primary-500 focus:ring-primary-500',
          isDisabled && 'bg-gray-100 cursor-not-allowed',
          className
        )}
        onClick={() => !isDisabled && setIsOpen(!isOpen)}
      >
        <div className="flex flex-wrap gap-1">
          {selectedOptions.length > 0 ? (
            selectedOptions.map(option => (
              <span
                key={option.value}
                className="inline-flex items-center rounded-md bg-primary-50 px-2 py-1 text-sm font-medium text-primary-700"
              >
                {option.label}
                <button
                  onClick={(e) => handleRemoveOption(option.value, e)}
                  className="ml-1 inline-flex h-4 w-4 items-center justify-center rounded-full hover:bg-primary-200"
                >
                  <X className="h-3 w-3" />
                </button>
              </span>
            ))
          ) : (
            <span className="text-gray-500">{placeholder}</span>
          )}
        </div>
        <div className="absolute right-2 top-2">
          <ChevronDown className={cn(
            "h-5 w-5 text-gray-400 transition-transform",
            isOpen && "transform rotate-180"
          )} />
        </div>
      </div>

      {isOpen && !isDisabled && (
        <div className="absolute z-10 mt-1 w-full rounded-md bg-white shadow-lg">
          {/* Search input */}
          <div className="sticky top-0 p-2 bg-white border-b border-gray-200">
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search className="h-4 w-4 text-gray-400" />
              </div>
              <input
                ref={searchInputRef}
                type="text"
                className="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md leading-5 bg-white placeholder-gray-500 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
                placeholder="Search options..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                onClick={(e) => e.stopPropagation()}
              />
            </div>
          </div>
          
          <div className="max-h-60 overflow-auto">
            {filteredOptions.length === 0 ? (
              <div className="px-4 py-2 text-sm text-gray-500">No options found</div>
            ) : (
              filteredOptions.map(option => (
              <div
                key={option.value}
                className={cn(
                  'px-4 py-2 text-sm cursor-pointer',
                  value.includes(option.value)
                    ? 'bg-primary-50 text-primary-700'
                    : 'text-gray-900 hover:bg-gray-100'
                )}
                onClick={() => handleToggleOption(option.value)}
              >
                {option.label}
                {option.category && (
                  <span className="ml-2 text-xs text-gray-500">({option.category})</span>
                )}
              </div>
            )))}
          </div>
        </div>
      )}
    </div>
  );
}
