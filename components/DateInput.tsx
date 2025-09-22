import React from 'react';
import { getMaxAllowedDateString } from '../lib/dateValidation';

interface DateInputProps {
  label: string;
  id: string;
  name: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  required?: boolean;
  disabled?: boolean;
  className?: string;
  placeholder?: string;
  allowFuture?: boolean;
  fieldName?: string;
  maxYearsPast?: number;
  error?: string;
}

const DateInput: React.FC<DateInputProps> = ({
  label,
  id,
  name,
  value,
  onChange,
  required = false,
  disabled = false,
  className = '',
  placeholder,
  allowFuture = false,
  fieldName,
  maxYearsPast = 50,
  error: externalError
}) => {
  // Get the maximum allowed date (today if future dates are not allowed)
  const maxDate = allowFuture ? undefined : getMaxAllowedDateString();

  const hasError = Boolean(externalError);

  return (
    <div className="space-y-1">
      <label 
        htmlFor={id} 
        className="block text-sm font-medium text-gray-700"
      >
        {label}
        {required && <span className="text-red-500 ml-1">*</span>}
      </label>
      
      <input
        type="date"
        id={id}
        name={name}
        value={value}
        onChange={onChange}
        max={maxDate}
        required={required}
        disabled={disabled}
        placeholder={placeholder}
        className={`
          w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent
          ${hasError 
            ? 'border-red-300 bg-red-50 focus:ring-red-500' 
            : 'border-gray-300 focus:border-blue-500'
          }
          ${disabled ? 'bg-gray-100 cursor-not-allowed' : 'bg-white'}
          ${className}
        `}
      />
      
      {hasError && (
        <p className="text-sm text-red-600 flex items-center">
          <svg 
            className="w-4 h-4 mr-1 flex-shrink-0" 
            fill="currentColor" 
            viewBox="0 0 20 20"
          >
            <path 
              fillRule="evenodd" 
              d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" 
              clipRule="evenodd" 
            />
          </svg>
          {externalError}
        </p>
      )}
      
      {!allowFuture && !hasError && (
        <p className="text-xs text-gray-500">
          Maximum allowed date: {getMaxAllowedDateString()}
        </p>
      )}
    </div>
  );
};

export default DateInput;
