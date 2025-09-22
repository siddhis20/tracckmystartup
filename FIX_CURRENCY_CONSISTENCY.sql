-- =====================================================
-- FIX CURRENCY CONSISTENCY - DATABASE SETUP
-- =====================================================
-- This script ensures the database supports currency consistency
-- =====================================================

-- Step 1: Ensure currency column exists in startups table
-- =====================================================
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS currency VARCHAR(3) DEFAULT 'USD';

-- Step 2: Update existing records to have USD as default
-- =====================================================
UPDATE public.startups 
SET currency = 'USD' 
WHERE currency IS NULL;

-- Step 3: Add comment to document the column
-- =====================================================
COMMENT ON COLUMN public.startups.currency IS 'User preferred currency for financial displays (USD, EUR, GBP, INR, CAD, AUD, JPY, CHF, SGD, CNY, etc.)';

-- Step 4: Verify the setup
-- =====================================================
SELECT 
    'currency_setup_check' as check_type,
    COUNT(*) as total_startups,
    COUNT(CASE WHEN currency = 'USD' THEN 1 END) as usd_startups,
    COUNT(CASE WHEN currency = 'INR' THEN 1 END) as inr_startups,
    COUNT(CASE WHEN currency = 'EUR' THEN 1 END) as eur_startups,
    STRING_AGG(DISTINCT currency, ', ') as all_currencies
FROM public.startups;

-- Step 5: Show sample startup data with currency
-- =====================================================
SELECT 
    'sample_startup_currencies' as check_type,
    id,
    name,
    currency,
    current_valuation,
    total_funding
FROM public.startups
ORDER BY created_at DESC
LIMIT 5;

-- Success message
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'CURRENCY CONSISTENCY DATABASE SETUP COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Currency column added to startups table';
    RAISE NOTICE '✅ All existing startups set to USD default';
    RAISE NOTICE '✅ Database ready for currency consistency';
    RAISE NOTICE '========================================';
END $$;

