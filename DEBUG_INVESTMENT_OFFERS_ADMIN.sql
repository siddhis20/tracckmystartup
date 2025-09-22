-- =====================================================
-- DEBUG INVESTMENT OFFERS ADMIN ISSUE
-- =====================================================
-- This script helps diagnose why investment offers are not showing in admin panel
-- =====================================================

-- Step 1: Check if investment_offers table exists
-- =====================================================
SELECT 
    'table_exists_check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'investment_offers') 
        THEN '✅ investment_offers table exists'
        ELSE '❌ investment_offers table missing'
    END as status;

-- Step 2: Check investment_offers table structure
-- =====================================================
SELECT 
    'table_structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'investment_offers' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 3: Check if there are any investment offers in the database
-- =====================================================
SELECT 
    'offers_count' as check_type,
    COUNT(*) as total_offers,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_offers,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_offers,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_offers
FROM public.investment_offers;

-- Step 4: Show sample investment offers (if any exist)
-- =====================================================
SELECT 
    'sample_offers' as check_type,
    id,
    investor_email,
    startup_name,
    offer_amount,
    equity_percentage,
    status,
    created_at
FROM public.investment_offers 
ORDER BY created_at DESC
LIMIT 10;

-- Step 5: Check foreign key constraints
-- =====================================================
SELECT 
    'foreign_key_check' as check_type,
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='investment_offers';

-- Step 6: Check if startups table exists and has data
-- =====================================================
SELECT 
    'startups_check' as check_type,
    COUNT(*) as total_startups
FROM public.startups;

-- Step 7: Check RLS policies on investment_offers
-- =====================================================
SELECT 
    'rls_policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'investment_offers' 
AND schemaname = 'public'
ORDER BY policyname;

-- Step 8: Check if RLS is enabled on investment_offers
-- =====================================================
SELECT 
    'rls_status' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'investment_offers' 
AND schemaname = 'public';

-- Step 9: Test query that the admin service uses
-- =====================================================
SELECT 
    'admin_query_test' as check_type,
    id,
    investor_email,
    startup_name,
    offer_amount,
    equity_percentage,
    status,
    created_at
FROM public.investment_offers
ORDER BY created_at DESC
LIMIT 5;

-- Step 10: Check if there are any errors in the query
-- =====================================================
-- This will help identify if there are any data type mismatches or missing columns
SELECT 
    'data_validation' as check_type,
    CASE 
        WHEN COUNT(*) = 0 THEN 'No offers found - this is why admin panel is empty'
        ELSE 'Offers exist - check RLS policies or service query'
    END as diagnosis
FROM public.investment_offers;

