import React, { SelectHTMLAttributes } from 'react';
import { cn } from '../../utils/cn';

interface SelectOption {
  value: string;
  label: string;
}

interface SelectProps extends Omit<SelectHTMLAttributes<HTMLSelectElement>, 'onChange'> {
  options: SelectOption[];
  value: string;
  onChange: (value: string) => void;
}

export function Select({
  className,
  options,
  value,
  onChange,
  ...props
}: SelectProps) {
  return (
    <select
      className={cn(
        'block w-full rounded-md border-gray-300 shadow-sm',
        'focus:border-primary-500 focus:ring-primary-500',
        'text-sm',
        className
      )}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      {...props}
    >
      {options.map((option) => (
        <option key={option.value} value={option.value}>
          {option.label}
        </option>
      ))}
    </select>
  );
}
