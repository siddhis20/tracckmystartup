
/**
 * Generates a unique investor code in the format INV-XXXXXX
 * @returns A unique investor code
 */
export function generateInvestorCode(): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = 'INV-';
  
  for (let i = 0; i < 6; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  
  return result;
}

/**
 * Validates if a string is a valid investor code format
 * @param code The code to validate
 * @returns True if valid, false otherwise
 */
export function isValidInvestorCode(code: string): boolean {
  const investorCodeRegex = /^INV-[A-Z0-9]{6}$/;
  return investorCodeRegex.test(code);
}

