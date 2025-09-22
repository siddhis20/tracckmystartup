-- Add currency column to startups table
-- Run this in Supabase SQL Editor

-- Add currency column to startups table
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'USD';

-- Add comment to document the column
COMMENT ON COLUMN public.startups.currency IS 'User preferred currency for financial displays (USD, EUR, GBP, INR, CAD, AUD, JPY, CHF, SGD, CNY)';

-- Update existing records to have USD as default
UPDATE public.startups 
SET currency = 'USD' 
WHERE currency IS NULL;

-- Verify the column was added
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name = 'currency';
