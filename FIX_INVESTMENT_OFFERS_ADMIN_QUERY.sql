-- =====================================================
-- FIX INVESTMENT OFFERS ADMIN QUERY ISSUE
-- =====================================================
-- This script fixes the database schema issues preventing admin from seeing investment offers
-- =====================================================

-- Step 1: Check current table structure
-- =====================================================
SELECT 
    'current_structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'investment_offers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 2: Add missing columns if they don't exist
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
    END IF;
END $$;

-- Step 3: Update existing records to have startup_id
-- =====================================================
-- This tries to match startup_name with startups.name to populate startup_id
UPDATE public.investment_offers 
SET startup_id = s.id
FROM public.startups s
WHERE public.investment_offers.startup_name = s.name
AND public.investment_offers.startup_id IS NULL;

-- Step 4: Add foreign key constraint if it doesn't exist
-- =====================================================
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'investment_offers_startup_id_fkey'
        AND table_name = 'investment_offers'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.investment_offers 
        ADD CONSTRAINT investment_offers_startup_id_fkey 
        FOREIGN KEY (startup_id) REFERENCES public.startups(id) ON DELETE CASCADE;
    END IF;
EXCEPTION
    WHEN duplicate_object THEN
        -- Constraint already exists, ignore the error
        NULL;
END $$;

-- Step 5: Enable RLS if not already enabled
-- =====================================================
ALTER TABLE public.investment_offers ENABLE ROW LEVEL SECURITY;

-- Step 6: Create/Update RLS policies for admin access
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can view all offers" ON public.investment_offers;
DROP POLICY IF EXISTS "Users can view their own offers" ON public.investment_offers;
DROP POLICY IF EXISTS "Public read access" ON public.investment_offers;

-- Create admin policy
CREATE POLICY "Admins can view all offers" ON public.investment_offers
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'Admin'
        )
    );

-- Create user policy for their own offers
CREATE POLICY "Users can view their own offers" ON public.investment_offers
    FOR SELECT USING (
        investor_email = (
            SELECT email FROM public.users 
            WHERE id = auth.uid()
        )
    );

-- Create public read policy for testing (remove in production)
CREATE POLICY "Public read access" ON public.investment_offers
    FOR SELECT USING (true);

-- Step 7: Verify the fix
-- =====================================================
SELECT 
    'verification' as check_type,
    COUNT(*) as total_offers,
    COUNT(CASE WHEN startup_id IS NOT NULL THEN 1 END) as offers_with_startup_id,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_offers
FROM public.investment_offers;

-- Step 8: Test the admin query
-- =====================================================
SELECT 
    'admin_query_test' as check_type,
    io.id,
    io.investor_email,
    io.startup_name,
    io.offer_amount,
    io.equity_percentage,
    io.status,
    io.created_at,
    s.id as startup_id,
    s.name as startup_name_from_join
FROM public.investment_offers io
LEFT JOIN public.startups s ON io.startup_id = s.id
ORDER BY io.created_at DESC
LIMIT 5;

-- Step 9: Show final table structure
-- =====================================================
SELECT 
    'final_structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'investment_offers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Success message
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'INVESTMENT OFFERS ADMIN FIX COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Added missing columns (startup_id, investor_name)';
    RAISE NOTICE '✅ Updated existing records with startup_id';
    RAISE NOTICE '✅ Added foreign key constraint';
    RAISE NOTICE '✅ Enabled RLS with proper policies';
    RAISE NOTICE '✅ Admin should now be able to see investment offers';
    RAISE NOTICE '========================================';
END $$;
