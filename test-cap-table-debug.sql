-- =====================================================
-- CAP TABLE DEBUG SCRIPT
-- =====================================================

-- Get a startup ID for testing
DO $$
DECLARE
    test_startup_id INTEGER;
    valuation_result RECORD;
BEGIN
    -- Get first startup
    SELECT id INTO test_startup_id FROM startups LIMIT 1;
    
    IF test_startup_id IS NULL THEN
        RAISE NOTICE 'No startups found in database';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testing with startup ID: %', test_startup_id;
    
    -- Check if valuation_history table has data
    RAISE NOTICE 'Checking valuation_history table...';
    PERFORM COUNT(*) FROM valuation_history WHERE startup_id = test_startup_id;
    
    -- Check if investment_records table has data
    RAISE NOTICE 'Checking investment_records table...';
    PERFORM COUNT(*) FROM investment_records WHERE startup_id = test_startup_id;
    
    -- Test the RPC function directly
    RAISE NOTICE 'Testing get_valuation_history RPC function...';
    FOR valuation_result IN 
        SELECT * FROM get_valuation_history(test_startup_id)
    LOOP
        RAISE NOTICE 'Valuation record: round_name=%, valuation=%, investment_amount=%, date=%', 
            valuation_result.round_name, 
            valuation_result.valuation, 
            valuation_result.investment_amount, 
            valuation_result.date;
    END LOOP;
    
    -- If no results from RPC, check manual calculation
    IF NOT FOUND THEN
        RAISE NOTICE 'No results from RPC function, checking manual calculation...';
        
        -- Show investment records that would be used for manual calculation
        FOR valuation_result IN 
            SELECT 
                date,
                amount,
                pre_money_valuation,
                investor_name,
                investment_type
            FROM investment_records 
            WHERE startup_id = test_startup_id
            ORDER BY date
        LOOP
            RAISE NOTICE 'Investment record: date=%, amount=%, pre_money_valuation=%, investor=%, type=%', 
                valuation_result.date, 
                valuation_result.amount, 
                valuation_result.pre_money_valuation, 
                valuation_result.investor_name, 
                valuation_result.investment_type;
        END LOOP;
    END IF;
    
END $$;

-- Show sample data from tables
SELECT 'Sample valuation_history data:' as info;
SELECT * FROM valuation_history LIMIT 5;

SELECT 'Sample investment_records data:' as info;
SELECT * FROM investment_records LIMIT 5;
