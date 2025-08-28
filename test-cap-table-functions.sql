-- =====================================================
-- CAP TABLE FUNCTIONS TEST SCRIPT
-- =====================================================

-- Test 1: Check if tables exist
SELECT 'Testing table existence...' as test_step;

SELECT 
    table_name,
    CASE WHEN table_name IS NOT NULL THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('investment_records', 'founders', 'fundraising_details', 'valuation_history', 'equity_holdings');

-- Test 2: Check if functions exist
SELECT 'Testing function existence...' as test_step;

SELECT 
    routine_name,
    CASE WHEN routine_name IS NOT NULL THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_investment_summary', 'get_valuation_history', 'get_equity_distribution', 'get_fundraising_status');

-- Test 3: Get or create a startup for testing
SELECT 'Getting startup for testing...' as test_step;

DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    -- Get first startup or create one
    SELECT id INTO test_startup_id FROM startups LIMIT 1;
    
    IF test_startup_id IS NULL THEN
        -- Create a test startup
        INSERT INTO startups (name, user_id, total_funding, current_valuation)
        VALUES ('Test Startup', (SELECT id FROM auth.users LIMIT 1), 1000000, 5000000)
        RETURNING id INTO test_startup_id;
    END IF;
    
    RAISE NOTICE 'Using startup ID: %', test_startup_id;
    
    -- Test 4: Test investment summary function
    RAISE NOTICE 'Testing get_investment_summary...';
    PERFORM * FROM get_investment_summary(test_startup_id);
    
    -- Test 5: Test valuation history function
    RAISE NOTICE 'Testing get_valuation_history...';
    PERFORM * FROM get_valuation_history(test_startup_id);
    
    -- Test 6: Test equity distribution function
    RAISE NOTICE 'Testing get_equity_distribution...';
    PERFORM * FROM get_equity_distribution(test_startup_id);
    
    -- Test 7: Test fundraising status function
    RAISE NOTICE 'Testing get_fundraising_status...';
    PERFORM * FROM get_fundraising_status(test_startup_id);
    
END $$;

-- Test 8: Check sample data
SELECT 'Checking sample data...' as test_step;

SELECT 'Investment Records' as table_name, COUNT(*) as record_count FROM investment_records
UNION ALL
SELECT 'Founders' as table_name, COUNT(*) as record_count FROM founders
UNION ALL
SELECT 'Fundraising Details' as table_name, COUNT(*) as record_count FROM fundraising_details
UNION ALL
SELECT 'Valuation History' as table_name, COUNT(*) as record_count FROM valuation_history
UNION ALL
SELECT 'Equity Holdings' as table_name, COUNT(*) as record_count FROM equity_holdings;

-- Test 9: Test RLS policies
SELECT 'Testing RLS policies...' as test_step;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('investment_records', 'founders', 'fundraising_details', 'valuation_history', 'equity_holdings');

-- Test 10: Check triggers
SELECT 'Testing triggers...' as test_step;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND event_object_table IN ('investment_records', 'founders', 'fundraising_details', 'equity_holdings');

SELECT 'Cap Table functions test completed!' as final_status;
