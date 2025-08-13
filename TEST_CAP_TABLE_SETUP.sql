-- =====================================================
-- CAP TABLE SETUP TEST SCRIPT
-- =====================================================

-- Get a startup ID for testing
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    -- Get the first available startup ID
    SELECT id INTO test_startup_id FROM startups LIMIT 1;
    
    -- If no startup exists, create one
    IF test_startup_id IS NULL THEN
        INSERT INTO startups (name, investment_type, investment_value, equity_allocation, current_valuation, compliance_status, sector, total_funding, total_revenue, registration_date)
        VALUES ('Test Startup', 'Seed', 1000000, 10, 5000000, 'Compliant', 'Technology', 1000000, 500000, '2023-01-01')
        RETURNING id INTO test_startup_id;
    END IF;
    
    RAISE NOTICE 'Using startup ID: % for testing', test_startup_id;
    
    -- Test investment records
    RAISE NOTICE 'Testing investment records...';
    PERFORM COUNT(*) FROM investment_records WHERE startup_id = test_startup_id;
    
    -- Test founders
    RAISE NOTICE 'Testing founders...';
    PERFORM COUNT(*) FROM founders WHERE startup_id = test_startup_id;
    
    -- Test fundraising details
    RAISE NOTICE 'Testing fundraising details...';
    PERFORM COUNT(*) FROM fundraising_details WHERE startup_id = test_startup_id;
    
    -- Test valuation history
    RAISE NOTICE 'Testing valuation history...';
    PERFORM COUNT(*) FROM valuation_history WHERE startup_id = test_startup_id;
    
    -- Test equity holdings
    RAISE NOTICE 'Testing equity holdings...';
    PERFORM COUNT(*) FROM equity_holdings WHERE startup_id = test_startup_id;
    
    -- Test RPC functions
    RAISE NOTICE 'Testing RPC functions...';
    
    -- Test get_investment_summary
    BEGIN
        PERFORM * FROM get_investment_summary(test_startup_id);
        RAISE NOTICE '✅ get_investment_summary function works';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_investment_summary function failed: %', SQLERRM;
    END;
    
    -- Test get_valuation_history
    BEGIN
        PERFORM * FROM get_valuation_history(test_startup_id);
        RAISE NOTICE '✅ get_valuation_history function works';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_valuation_history function failed: %', SQLERRM;
    END;
    
    -- Test get_equity_distribution
    BEGIN
        PERFORM * FROM get_equity_distribution(test_startup_id);
        RAISE NOTICE '✅ get_equity_distribution function works';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_equity_distribution function failed: %', SQLERRM;
    END;
    
    -- Test get_fundraising_status
    BEGIN
        PERFORM * FROM get_fundraising_status(test_startup_id);
        RAISE NOTICE '✅ get_fundraising_status function works';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ get_fundraising_status function failed: %', SQLERRM;
    END;
    
    RAISE NOTICE 'Cap Table setup test completed!';
END $$;

-- Show sample data
SELECT 'Investment Records' as table_name, COUNT(*) as record_count FROM investment_records
UNION ALL
SELECT 'Founders' as table_name, COUNT(*) as record_count FROM founders
UNION ALL
SELECT 'Fundraising Details' as table_name, COUNT(*) as record_count FROM fundraising_details
UNION ALL
SELECT 'Valuation History' as table_name, COUNT(*) as record_count FROM valuation_history
UNION ALL
SELECT 'Equity Holdings' as table_name, COUNT(*) as record_count FROM equity_holdings;
