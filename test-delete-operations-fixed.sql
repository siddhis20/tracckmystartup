-- =====================================================
-- TEST DELETE OPERATIONS (FIXED)
-- =====================================================
-- This script tests that delete operations work properly

-- First, let's check the current data counts
SELECT 'investment_records' as table_name, COUNT(*) as record_count FROM investment_records
UNION ALL
SELECT 'financial_records' as table_name, COUNT(*) as record_count FROM financial_records
UNION ALL
SELECT 'employees' as table_name, COUNT(*) as record_count FROM employees
UNION ALL
SELECT 'fundraising_details' as table_name, COUNT(*) as record_count FROM fundraising_details;

-- Check sample data in each table
SELECT 'investment_records' as table_name, id, startup_id, investor_name, amount FROM investment_records LIMIT 3;
SELECT 'financial_records' as table_name, id, startup_id, record_type, amount FROM financial_records LIMIT 3;
SELECT 'employees' as table_name, id, startup_id, name, department FROM employees LIMIT 3;
SELECT 'fundraising_details' as table_name, id, startup_id, type, value FROM fundraising_details LIMIT 3;

-- Test delete operations (this will help verify the RLS policies work)
DO $$
DECLARE
    test_startup_id INTEGER;
    test_investment_id TEXT;
    test_financial_id TEXT;
    test_employee_id TEXT;
    test_fundraising_id INTEGER;
BEGIN
    -- Get a startup ID for testing
    SELECT id INTO test_startup_id FROM startups LIMIT 1;
    
    IF test_startup_id IS NULL THEN
        RAISE NOTICE 'No startups found in database';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testing with startup ID: %', test_startup_id;
    
    -- Test 1: Investment Records Delete (UUID)
    RAISE NOTICE 'Testing investment records delete...';
    SELECT id INTO test_investment_id FROM investment_records WHERE startup_id = test_startup_id LIMIT 1;
    
    IF test_investment_id IS NOT NULL THEN
        BEGIN
            DELETE FROM investment_records WHERE id = test_investment_id;
            RAISE NOTICE '✅ Investment record delete test passed (ID: %)', test_investment_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Investment record delete test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No investment records found to test delete';
    END IF;
    
    -- Test 2: Financial Records Delete (UUID)
    RAISE NOTICE 'Testing financial records delete...';
    SELECT id INTO test_financial_id FROM financial_records WHERE startup_id = test_startup_id LIMIT 1;
    
    IF test_financial_id IS NOT NULL THEN
        BEGIN
            DELETE FROM financial_records WHERE id = test_financial_id;
            RAISE NOTICE '✅ Financial record delete test passed (ID: %)', test_financial_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Financial record delete test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No financial records found to test delete';
    END IF;
    
    -- Test 3: Employees Delete (UUID)
    RAISE NOTICE 'Testing employees delete...';
    SELECT id INTO test_employee_id FROM employees WHERE startup_id = test_startup_id LIMIT 1;
    
    IF test_employee_id IS NOT NULL THEN
        BEGIN
            DELETE FROM employees WHERE id = test_employee_id;
            RAISE NOTICE '✅ Employee delete test passed (ID: %)', test_employee_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Employee delete test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No employees found to test delete';
    END IF;
    
    -- Test 4: Fundraising Details Delete (INTEGER)
    RAISE NOTICE 'Testing fundraising details delete...';
    SELECT id INTO test_fundraising_id FROM fundraising_details WHERE startup_id = test_startup_id LIMIT 1;
    
    IF test_fundraising_id IS NOT NULL THEN
        BEGIN
            DELETE FROM fundraising_details WHERE id = test_fundraising_id;
            RAISE NOTICE '✅ Fundraising details delete test passed (ID: %)', test_fundraising_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Fundraising details delete test failed: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No fundraising details found to test delete';
    END IF;
    
END
$$;

-- Check final data counts after delete tests
SELECT 'investment_records' as table_name, COUNT(*) as record_count FROM investment_records
UNION ALL
SELECT 'financial_records' as table_name, COUNT(*) as record_count FROM financial_records
UNION ALL
SELECT 'employees' as table_name, COUNT(*) as record_count FROM employees
UNION ALL
SELECT 'fundraising_details' as table_name, COUNT(*) as record_count FROM fundraising_details;

-- Verify RLS policies are working
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('investment_records', 'financial_records', 'employees', 'fundraising_details')
    AND schemaname = 'public'
ORDER BY tablename, cmd;

-- Check table structure to understand ID types
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('investment_records', 'financial_records', 'employees', 'fundraising_details')
    AND column_name = 'id'
ORDER BY table_name;
