// Date validation utilities
// This file provides date validation functions to prevent future dates and ensure proper date logic

export interface DateValidationResult {
  isValid: boolean;
  error?: string;
}

/**
 * Validates investment dates - no future dates allowed
 */
export function validateInvestmentDate(date: string): DateValidationResult {
  if (!date) {
    return { isValid: false, error: 'Investment date is required' };
  }

  const inputDate = new Date(date);
  const today = new Date();
  today.setHours(23, 59, 59, 999); // End of today

  if (isNaN(inputDate.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  if (inputDate > today) {
    return { isValid: false, error: 'Investment date cannot be in the future' };
  }

  // Check if date is too far in the past (more than 50 years)
  const fiftyYearsAgo = new Date();
  fiftyYearsAgo.setFullYear(today.getFullYear() - 50);
  
  if (inputDate < fiftyYearsAgo) {
    return { isValid: false, error: 'Investment date cannot be more than 50 years in the past' };
  }

  return { isValid: true };
}

/**
 * Validates financial record dates - no future dates allowed
 */
export function validateFinancialRecordDate(date: string): DateValidationResult {
  if (!date) {
    return { isValid: false, error: 'Financial record date is required' };
  }

  const inputDate = new Date(date);
  const today = new Date();
  today.setHours(23, 59, 59, 999); // End of today

  if (isNaN(inputDate.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  if (inputDate > today) {
    return { isValid: false, error: 'Financial record date cannot be in the future' };
  }

  // Check if date is too far in the past (more than 50 years)
  const fiftyYearsAgo = new Date();
  fiftyYearsAgo.setFullYear(today.getFullYear() - 50);
  
  if (inputDate < fiftyYearsAgo) {
    return { isValid: false, error: 'Financial record date cannot be more than 50 years in the past' };
  }

  return { isValid: true };
}

/**
 * Validates valuation dates - no future dates allowed
 */
export function validateValuationDate(date: string): DateValidationResult {
  if (!date) {
    return { isValid: false, error: 'Valuation date is required' };
  }

  const inputDate = new Date(date);
  const today = new Date();
  today.setHours(23, 59, 59, 999); // End of today

  if (isNaN(inputDate.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  if (inputDate > today) {
    return { isValid: false, error: 'Valuation date cannot be in the future' };
  }

  // Check if date is too far in the past (more than 50 years)
  const fiftyYearsAgo = new Date();
  fiftyYearsAgo.setFullYear(today.getFullYear() - 50);
  
  if (inputDate < fiftyYearsAgo) {
    return { isValid: false, error: 'Valuation date cannot be more than 50 years in the past' };
  }

  return { isValid: true };
}

/**
 * Validates employee joining dates - no future dates allowed
 */
export function validateJoiningDate(date: string): DateValidationResult {
  if (!date) {
    return { isValid: false, error: 'Joining date is required' };
  }

  const inputDate = new Date(date);
  const today = new Date();
  today.setHours(23, 59, 59, 999); // End of today

  if (isNaN(inputDate.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  if (inputDate > today) {
    return { isValid: false, error: 'Joining date cannot be in the future' };
  }

  // Check if date is too far in the past (more than 50 years)
  const fiftyYearsAgo = new Date();
  fiftyYearsAgo.setFullYear(today.getFullYear() - 50);
  
  if (inputDate < fiftyYearsAgo) {
    return { isValid: false, error: 'Joining date cannot be more than 50 years in the past' };
  }

  return { isValid: true };
}

/**
 * Validates company registration dates - no future dates allowed
 */
export function validateRegistrationDate(date: string): DateValidationResult {
  if (!date) {
    return { isValid: false, error: 'Registration date is required' };
  }

  const inputDate = new Date(date);
  const today = new Date();
  today.setHours(23, 59, 59, 999); // End of today

  if (isNaN(inputDate.getTime())) {
    return { isValid: false, error: 'Invalid date format' };
  }

  if (inputDate > today) {
    return { isValid: false, error: 'Registration date cannot be in the future' };
  }

  // Check if date is too far in the past (more than 100 years)
  const hundredYearsAgo = new Date();
  hundredYearsAgo.setFullYear(today.getFullYear() - 100);
  
  if (inputDate < hundredYearsAgo) {
    return { isValid: false, error: 'Registration date cannot be more than 100 years in the past' };
  }

  return { isValid: true };
}

/**
 * Gets the maximum allowed date string (today) for HTML date inputs
 */
export function getMaxAllowedDateString(): string {
  const today = new Date();
  return today.toISOString().split('T')[0];
}

/**
 * Gets the minimum allowed date string (50 years ago) for HTML date inputs
 */
export function getMinAllowedDateString(): string {
  const fiftyYearsAgo = new Date();
  fiftyYearsAgo.setFullYear(fiftyYearsAgo.getFullYear() - 50);
  return fiftyYearsAgo.toISOString().split('T')[0];
}
