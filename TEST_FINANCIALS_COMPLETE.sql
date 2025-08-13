-- =====================================================
-- COMPREHENSIVE FINANCIALS TEST SCRIPT
-- =====================================================

-- Test 1: Verify table structure
SELECT '=== TEST 1: TABLE STRUCTURE ===' as test_name;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'financial_records' 
ORDER BY ordinal_position;

-- Test 2: Verify functions exist
SELECT '=== TEST 2: FUNCTION VERIFICATION ===' as test_name;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name IN (
    'get_monthly_financial_data',
    'get_revenue_by_vertical', 
    'get_expenses_by_vertical',
    'get_startup_financial_summary'
)
AND routine_schema = 'public';

-- Test 3: Verify storage bucket
SELECT '=== TEST 3: STORAGE BUCKET ===' as test_name;
SELECT 
    id, 
    name, 
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'financial-attachments';

-- Test 4: Get startup ID for testing
SELECT '=== TEST 4: STARTUP ID FOR TESTING ===' as test_name;
SELECT 
    id as startup_id,
    name as startup_name,
    total_funding
FROM startups 
ORDER BY id 
LIMIT 1;

-- Test 5: Check existing financial records
SELECT '=== TEST 5: EXISTING FINANCIAL RECORDS ===' as test_name;
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN record_type = 'expense' THEN 1 END) as expense_count,
    COUNT(CASE WHEN record_type = 'revenue' THEN 1 END) as revenue_count
FROM financial_records;

-- Test 6: Test monthly financial data function
SELECT '=== TEST 6: MONTHLY FINANCIAL DATA ===' as test_name;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing monthly financial data for startup ID: %', test_startup_id;
        -- This will show the actual data
        PERFORM * FROM get_monthly_financial_data(test_startup_id, 2024);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

-- Test 7: Test revenue by vertical function
SELECT '=== TEST 7: REVENUE BY VERTICAL ===' as test_name;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing revenue by vertical for startup ID: %', test_startup_id;
        -- This will show the actual data
        PERFORM * FROM get_revenue_by_vertical(test_startup_id, 2024);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

-- Test 8: Test expenses by vertical function
SELECT '=== TEST 8: EXPENSES BY VERTICAL ===' as test_name;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing expenses by vertical for startup ID: %', test_startup_id;
        -- This will show the actual data
        PERFORM * FROM get_expenses_by_vertical(test_startup_id, 2024);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

-- Test 9: Test financial summary function
SELECT '=== TEST 9: FINANCIAL SUMMARY ===' as test_name;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing financial summary for startup ID: %', test_startup_id;
        -- This will show the actual data
        PERFORM * FROM get_startup_financial_summary(test_startup_id);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

-- Test 10: Verify RLS policies
SELECT '=== TEST 10: RLS POLICIES ===' as test_name;
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
WHERE tablename = 'financial_records';

-- Test 11: Test data insertion (if no data exists)
SELECT '=== TEST 11: DATA INSERTION TEST ===' as test_name;
DO $$
DECLARE
    test_startup_id INTEGER;
    record_count INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    SELECT COUNT(*) INTO record_count FROM financial_records WHERE startup_id = test_startup_id;
    
    IF test_startup_id IS NOT NULL AND record_count = 0 THEN
        RAISE NOTICE 'Inserting sample data for startup ID: %', test_startup_id;
        
        INSERT INTO financial_records (startup_id, record_type, date, entity, description, vertical, amount, funding_source, cogs, attachment_url) VALUES
        -- Sample expenses
        (test_startup_id, 'expense', '2024-01-15', 'Parent Company', 'AWS Services', 'Infrastructure', 2500.00, 'Series A', NULL, NULL),
        (test_startup_id, 'expense', '2024-01-20', 'Parent Company', 'Salaries - Engineering', 'Salary', 15000.00, 'Series A', NULL, NULL),
        (test_startup_id, 'expense', '2024-02-10', 'Parent Company', 'Marketing Campaign', 'Marketing', 5000.00, 'Series A', NULL, NULL),
        (test_startup_id, 'expense', '2024-02-15', 'Parent Company', 'Office Rent', 'Infrastructure', 3000.00, 'Series A', NULL, NULL),
        (test_startup_id, 'expense', '2024-03-05', 'Parent Company', 'Legal Services', 'Legal', 2000.00, 'Series A', NULL, NULL),
        (test_startup_id, 'expense', '2024-03-20', 'Parent Company', 'Salaries - Sales', 'Salary', 12000.00, 'Series A', NULL, NULL),
        
        -- Sample revenue
        (test_startup_id, 'revenue', '2024-01-25', 'Parent Company', 'SaaS Subscription Revenue', 'SaaS', 8000.00, NULL, 2000.00, NULL),
        (test_startup_id, 'revenue', '2024-02-28', 'Parent Company', 'Consulting Services', 'Consulting', 15000.00, NULL, 5000.00, NULL),
        (test_startup_id, 'revenue', '2024-03-15', 'Parent Company', 'API Revenue', 'API', 5000.00, NULL, 1000.00, NULL),
        (test_startup_id, 'revenue', '2024-03-30', 'Parent Company', 'SaaS Subscription Revenue', 'SaaS', 12000.00, NULL, 3000.00, NULL);
        
        RAISE NOTICE 'Sample data inserted successfully';
    ELSE
        RAISE NOTICE 'Data already exists or no startup found';
    END IF;
END $$;

-- Test 12: Final verification
SELECT '=== TEST 12: FINAL VERIFICATION ===' as test_name;
SELECT 
    'Financial Records Count' as metric,
    COUNT(*) as value
FROM financial_records
UNION ALL
SELECT 
    'Expenses Count',
    COUNT(CASE WHEN record_type = 'expense' THEN 1 END)
FROM financial_records
UNION ALL
SELECT 
    'Revenue Count',
    COUNT(CASE WHEN record_type = 'revenue' THEN 1 END)
FROM financial_records
UNION ALL
SELECT 
    'Total Expense Amount',
    COALESCE(SUM(CASE WHEN record_type = 'expense' THEN amount ELSE 0 END), 0)
FROM financial_records
UNION ALL
SELECT 
    'Total Revenue Amount',
    COALESCE(SUM(CASE WHEN record_type = 'revenue' THEN amount ELSE 0 END), 0)
FROM financial_records;

-- Test 13: Show sample data
SELECT '=== TEST 13: SAMPLE DATA ===' as test_name;
SELECT 
    id,
    startup_id,
    record_type,
    date,
    entity,
    description,
    vertical,
    amount,
    funding_source,
    cogs
FROM financial_records 
ORDER BY date, record_type
LIMIT 10;

SELECT '=== ALL TESTS COMPLETED ===' as status;
