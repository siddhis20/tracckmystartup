import React, { useState, useEffect, useRef } from 'react';
import Button from '../ui/Button';
import { capTableService } from '../../lib/capTableService';

interface PricePerShareInputProps {
  startupId: number;
  initialValue: number;
  currency: string;
  onValueChange?: (value: number) => void;
}

const PricePerShareInput: React.FC<PricePerShareInputProps> = ({
  startupId,
  initialValue,
  currency,
  onValueChange
}) => {
  const [value, setValue] = useState<number>(initialValue);
  const [isLoading, setIsLoading] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  // Update local state when initialValue changes
  useEffect(() => {
    setValue(initialValue);
    if (inputRef.current) {
      inputRef.current.value = initialValue.toString();
    }
  }, [initialValue]);

  const handleSave = async (newValue: number) => {
    if (isLoading) return;
    
    setIsLoading(true);
    try {
      console.log('🔄 Saving price per share:', newValue, 'for startup:', startupId);
      const savedValue = await capTableService.upsertPricePerShare(startupId, newValue);
      console.log('✅ Price per share saved:', savedValue);
      
      setValue(savedValue);
      if (inputRef.current) {
        inputRef.current.value = savedValue.toString();
      }
      
      if (onValueChange) {
        onValueChange(savedValue);
      }
    } catch (error) {
      console.error('❌ Failed to save price per share:', error);
      // Revert to previous value on error
      if (inputRef.current) {
        inputRef.current.value = value.toString();
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleInitialize = async () => {
    if (isLoading) return;
    
    setIsLoading(true);
    try {
      console.log('🔄 Initializing startup shares for startup:', startupId);
      await capTableService.initializeStartupShares(startupId, 1000000, 1.0);
      console.log('✅ Startup shares initialized');
      
      setValue(1.0);
      if (inputRef.current) {
        inputRef.current.value = '1.0';
      }
      
      if (onValueChange) {
        onValueChange(1.0);
      }
    } catch (error) {
      console.error('❌ Failed to initialize startup shares:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleBlur = () => {
    const inputValue = parseFloat(inputRef.current?.value || '0') || 0;
    if (inputValue !== value) {
      handleSave(inputValue);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleBlur();
    }
  };

  return (
    <div className="flex items-center gap-3">
      <input
        ref={inputRef}
        type="number"
        step="0.01"
        min="0"
        defaultValue={value}
        onBlur={handleBlur}
        onKeyPress={handleKeyPress}
        disabled={isLoading}
        className="flex-1 px-3 py-2 border border-slate-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
        placeholder="e.g., 1.50"
      />
      <Button 
        size="sm" 
        variant="outline"
        onClick={handleInitialize}
        disabled={isLoading}
      >
        {isLoading ? 'Loading...' : 'Initialize'}
      </Button>
    </div>
  );
};

export default PricePerShareInput;

