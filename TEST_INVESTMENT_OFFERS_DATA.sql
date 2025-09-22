-- =====================================================
-- TEST INVESTMENT OFFERS DATA
-- =====================================================
-- This script creates test investment offers to verify admin panel functionality
-- =====================================================

-- Step 1: Check if we have any startups to create offers for
-- =====================================================
SELECT 
    'startups_available' as check_type,
    COUNT(*) as total_startups,
    STRING_AGG(name, ', ') as startup_names
FROM public.startups
LIMIT 5;

-- Step 2: Create test investment offers if none exist
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
    SELECT 1 FROM public.investment_offers io 
    WHERE io.startup_name = s.name
)
LIMIT 3;

-- Step 3: Create additional test offers with different statuses
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
    'another.investor@example.com',
    s.name,
    250000.00,
    10.00,
    'approved',
    s.id
FROM public.startups s
WHERE NOT EXISTS (
    SELECT 1 FROM public.investment_offers io 
    WHERE io.startup_name = s.name 
    AND io.investor_email = 'another.investor@example.com'
)
LIMIT 2;

-- Step 4: Verify the test data was created
-- =====================================================
SELECT 
    'test_data_created' as check_type,
    COUNT(*) as total_offers,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_offers,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_offers,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_offers
FROM public.investment_offers;

-- Step 5: Show the test offers
-- =====================================================
SELECT 
    'test_offers' as check_type,
    id,
    investor_email,
    startup_name,
    offer_amount,
    equity_percentage,
    status,
    startup_id,
    created_at
FROM public.investment_offers
ORDER BY created_at DESC;

-- Step 6: Test the admin query that the service uses
-- =====================================================
SELECT 
    'admin_service_query_test' as check_type,
    io.id,
    io.investor_email,
    io.startup_name,
    io.offer_amount,
    io.equity_percentage,
    io.status,
    io.created_at,
    s.id as startup_id_from_join,
    s.name as startup_name_from_join
FROM public.investment_offers io
LEFT JOIN public.startups s ON io.startup_id = s.id
ORDER BY io.created_at DESC;

-- Success message
-- =====================================================
DO $$
DECLARE
    offer_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO offer_count FROM public.investment_offers;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'TEST INVESTMENT OFFERS CREATED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Total offers in database: %', offer_count;
    RAISE NOTICE '✅ Test offers created for admin panel testing';
    RAISE NOTICE '✅ Admin should now see investment offers';
    RAISE NOTICE '========================================';
END $$;

