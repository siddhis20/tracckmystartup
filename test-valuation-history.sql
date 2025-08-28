-- =====================================================
-- VALUATION HISTORY TEST SCRIPT
-- =====================================================

-- Test 1: Check if RPC functions exist
SELECT 'Testing RPC function existence...' as test_step;

SELECT 
    routine_name,
    CASE WHEN routine_name IS NOT NULL THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_valuation_history', 'get_equity_distribution', 'get_investment_summary');

-- Test 2: Check if valuation_history table exists
SELECT 'Testing valuation_history table...' as test_step;

SELECT 
    table_name,
    CASE WHEN table_name IS NOT NULL THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'valuation_history';

-- Test 3: Check investment_records data
SELECT 'Testing investment_records data...' as test_step;

SELECT 
    COUNT(*) as total_investments,
    COUNT(DISTINCT startup_id) as unique_startups
FROM investment_records;

-- Test 4: Check if we have any investment data for testing
SELECT 'Testing investment data for startup...' as test_step;

SELECT 
    startup_id,
    COUNT(*) as investment_count,
    SUM(amount) as total_amount,
    AVG(pre_money_valuation) as avg_valuation
FROM investment_records 
GROUP BY startup_id
ORDER BY startup_id;

-- Test 5: Test the RPC function manually (replace 1 with actual startup_id)
SELECT 'Testing get_valuation_history RPC...' as test_step;

-- First, get a startup_id that has investments
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT startup_id INTO test_startup_id 
    FROM investment_records 
    LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup_id: %', test_startup_id;
        
        -- Test the RPC function
        PERFORM get_valuation_history(test_startup_id);
        RAISE NOTICE '✅ RPC function executed successfully';
    ELSE
        RAISE NOTICE '❌ No investment records found to test with';
    END IF;
END $$;

-- Test 6: Show sample valuation history data
SELECT 'Sample valuation history data...' as test_step;

SELECT 
    vh.startup_id,
    vh.date,
    vh.valuation,
    vh.investment_amount,
    vh.round_type,
    s.startup_name
FROM valuation_history vh
LEFT JOIN startups s ON vh.startup_id = s.id
ORDER BY vh.startup_id, vh.date
LIMIT 10;
