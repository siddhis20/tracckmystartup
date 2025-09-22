import { useMemo } from 'react';
import { Startup } from '../../types';

/**
 * Custom hook to get the startup's currency preference
 * Falls back to USD if no currency is specified
 */
export const useCurrency = (startup?: Startup): string => {
  return useMemo(() => {
    // Get currency from startup profile, fallback to USD
    return startup?.currency || 'USD';
  }, [startup?.currency]);
};

/**
 * Custom hook to get currency for admin view
 * For admin view, we might want to show a default currency or allow selection
 */
export const useAdminCurrency = (): string => {
  return useMemo(() => {
    // For admin view, default to USD
    // In the future, this could be made configurable
    return 'USD';
  }, []);
};

/**
 * Custom hook to get currency for investor view
 * Investors might have their own currency preference
 */
export const useInvestorCurrency = (): string => {
  return useMemo(() => {
    // For investor view, default to USD
    // In the future, this could be made configurable per investor
    return 'USD';
  }, []);
};

