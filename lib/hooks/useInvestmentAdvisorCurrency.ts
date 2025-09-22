import { useMemo } from 'react';
import { AuthUser } from '../auth';

/**
 * Custom hook to get the investment advisor's currency from profile data
 * Falls back to USD if no currency is specified
 */
export const useInvestmentAdvisorCurrency = (advisor: AuthUser | null): string => {
  return useMemo(() => {
    // Get currency from advisor profile, fallback to USD
    return advisor?.currency || 'USD';
  }, [advisor?.currency]);
};
