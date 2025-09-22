import { useMemo } from 'react';
import { Startup } from '../../types';
import { getCurrencyForCountry } from '../utils';

/**
 * Custom hook to get the startup's currency based on parent company country
 * Falls back to USD if no country is specified
 */
export const useStartupCurrency = (startup: Startup): string => {
  return useMemo(() => {
    // First try to get currency from startup object directly (from database)
    if (startup.currency) {
      return startup.currency;
    }
    
    // Then try to get currency from startup profile
    if (startup.profile?.currency) {
      return startup.profile.currency;
    }
    
    // If no currency in profile, get currency based on parent company country
    if (startup.profile?.country) {
      return getCurrencyForCountry(startup.profile.country);
    }
    
    // Fallback to USD
    return 'USD';
  }, [startup.currency, startup.profile?.currency, startup.profile?.country]);
};
