import React from 'react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label: string;
  containerClassName?: string;
  helpText?: string;
}

const Input: React.FC<InputProps> = ({ label, id, containerClassName = '', className = '', helpText, ...props }) => {
  const defaultInputClasses = "block w-full px-3 py-2 bg-white border border-slate-300 rounded-md shadow-sm placeholder-slate-400 focus:outline-none focus:ring-brand-primary focus:border-brand-primary sm:text-sm disabled:bg-slate-50 disabled:text-slate-500 disabled:border-slate-200 disabled:shadow-none";
  const combinedClasses = className ? `${defaultInputClasses} ${className}` : defaultInputClasses;
  
  return (
    <div className={containerClassName}>
      <label htmlFor={id} className="block text-sm font-medium text-slate-700 mb-1">
        {label}
      </label>
      <input
        id={id}
        className={combinedClasses}
        {...props}
      />
      {helpText && (
        <p className="mt-1 text-sm text-slate-500">
          {helpText}
        </p>
      )}
    </div>
  );
};

export default Input;
