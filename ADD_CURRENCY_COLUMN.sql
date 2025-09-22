-- Add currency column to startups table
-- This script adds the currency field to store user's preferred currency

-- Add currency column to startups table
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'USD';

-- Add comment to document the column
COMMENT ON COLUMN public.startups.currency IS 'User preferred currency for financial displays (USD, EUR, GBP, INR, CAD, AUD, JPY, CHF, SGD, CNY)';

-- Update the database types to include currency
-- Note: This will be reflected in the TypeScript types when regenerated
