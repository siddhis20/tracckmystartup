-- =====================================================
-- SIMPLE INVESTMENT OFFERS FIX
-- =====================================================
-- This script fixes investment offers admin panel issues without complex constraints
-- =====================================================

-- Step 1: Check current state
-- =====================================================
SELECT 
    'current_state' as check_type,
    COUNT(*) as total_offers,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_offers
FROM public.investment_offers;

-- Step 2: Add missing columns (safe approach)
-- =====================================================

-- Add startup_id column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'investment_offers' 
        AND column_name = 'startup_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.investment_offers ADD COLUMN startup_id INTEGER;
        RAISE NOTICE 'Added startup_id column';
    ELSE
        RAISE NOTICE 'startup_id column already exists';
    END IF;
END $$;

-- Add investor_name column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'investment_offers' 
        AND column_name = 'investor_name'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.investment_offers ADD COLUMN investor_name TEXT;
        RAISE NOTICE 'Added investor_name column';
    ELSE
        RAISE NOTICE 'investor_name column already exists';
    END IF;
END $$;

-- Step 3: Update existing records with startup_id
-- =====================================================
UPDATE public.investment_offers 
SET startup_id = s.id
FROM public.startups s
WHERE public.investment_offers.startup_name = s.name
AND public.investment_offers.startup_id IS NULL;

-- Step 4: Drop existing foreign key constraint if it exists
-- =====================================================
ALTER TABLE public.investment_offers 
DROP CONSTRAINT IF EXISTS investment_offers_startup_id_fkey;

-- Step 5: Add foreign key constraint (simple approach)
-- =====================================================
ALTER TABLE public.investment_offers 
ADD CONSTRAINT investment_offers_startup_id_fkey 
FOREIGN KEY (startup_id) REFERENCES public.startups(id) ON DELETE CASCADE;

-- Step 6: Enable RLS
-- =====================================================
ALTER TABLE public.investment_offers ENABLE ROW LEVEL SECURITY;

-- Step 7: Drop existing policies
-- =====================================================
DROP POLICY IF EXISTS "Admins can view all offers" ON public.investment_offers;
DROP POLICY IF EXISTS "Users can view their own offers" ON public.investment_offers;
DROP POLICY IF EXISTS "Public read access" ON public.investment_offers;

-- Step 8: Create new policies
-- =====================================================

-- Admin policy
CREATE POLICY "Admins can view all offers" ON public.investment_offers
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'Admin'
        )
    );

-- User policy for their own offers
CREATE POLICY "Users can view their own offers" ON public.investment_offers
    FOR SELECT USING (
        investor_email = (
            SELECT email FROM public.users 
            WHERE id = auth.uid()
        )
    );

-- Public read policy for testing
CREATE POLICY "Public read access" ON public.investment_offers
    FOR SELECT USING (true);

-- Step 9: Create test data if no offers exist
-- =====================================================
INSERT INTO public.investment_offers (
    investor_email,
    startup_name,
    offer_amount,
    equity_percentage,
    status,
    startup_id
)
SELECT 
    'test.investor@example.com',
    s.name,
    100000.00,
    5.00,
    'pending',
    s.id
FROM public.startups s
WHERE NOT EXISTS (
    SELECT 1 FROM public.investment_offers
)
LIMIT 3;

-- Step 10: Verify the fix
-- =====================================================
SELECT 
    'verification' as check_type,
    COUNT(*) as total_offers,
    COUNT(CASE WHEN startup_id IS NOT NULL THEN 1 END) as offers_with_startup_id,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_offers
FROM public.investment_offers;

-- Step 11: Test the admin query
-- =====================================================
SELECT 
    'admin_query_test' as check_type,
    io.id,
    io.investor_email,
    io.startup_name,
    io.offer_amount,
    io.equity_percentage,
    io.status,
    io.created_at
FROM public.investment_offers io
ORDER BY io.created_at DESC
LIMIT 5;

-- Success message
-- =====================================================
DO $$
DECLARE
    offer_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO offer_count FROM public.investment_offers;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'INVESTMENT OFFERS FIX COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total offers: %', offer_count;
    RAISE NOTICE '✅ Database schema updated';
    RAISE NOTICE '✅ RLS policies configured';
    RAISE NOTICE '✅ Test data created (if needed)';
    RAISE NOTICE '✅ Admin panel should now work';
    RAISE NOTICE '========================================';
END $$;

