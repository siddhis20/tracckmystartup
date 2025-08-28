export const formatIndianCurrency = (value: number | undefined | null): string => {
  // Handle null/undefined values
  if (value === null || value === undefined || isNaN(value)) {
    return '₹0';
  }
  
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(value);
};

export const formatIndianCurrencyCompact = (value: number | undefined | null): string => {
  // Handle null/undefined values
  if (value === null || value === undefined || isNaN(value)) {
    return '₹0';
  }
  
  if (value >= 1000000000) {
    return `₹${(value / 1000000000).toFixed(1)}B`;
  } else if (value >= 10000000) {
    return `₹${(value / 10000000).toFixed(1)}M`;
  } else if (value >= 100000) {
    return `₹${(value / 100000).toFixed(1)}L`;
  } else if (value >= 1000) {
    return `₹${(value / 1000).toFixed(1)}K`;
  } else {
    return `₹${value.toFixed(0)}`;
  }
};
