-- =====================================================
-- DEBUG FINANCIAL SUMMARY
-- =====================================================

-- Check what's in the startups table
SELECT 'Startup data:' as status;
SELECT 
    id,
    name,
    total_funding,
    total_revenue
FROM startups 
ORDER BY id;

-- Check all financial records
SELECT 'All financial records:' as status;
SELECT 
    id,
    startup_id,
    record_type,
    date,
    description,
    amount,
    created_at
FROM financial_records 
ORDER BY created_at DESC;

-- Check total expenses and revenue by startup
SELECT 'Financial totals by startup:' as status;
SELECT 
    startup_id,
    COUNT(*) as total_records,
    COUNT(CASE WHEN record_type = 'expense' THEN 1 END) as expense_count,
    COUNT(CASE WHEN record_type = 'revenue' THEN 1 END) as revenue_count,
    SUM(CASE WHEN record_type = 'expense' THEN amount ELSE 0 END) as total_expenses,
    SUM(CASE WHEN record_type = 'revenue' THEN amount ELSE 0 END) as total_revenue
FROM financial_records 
GROUP BY startup_id;

-- Test the get_startup_financial_summary function
SELECT 'Testing financial summary function:' as status;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing financial summary for startup ID: %', test_startup_id;
        -- This will show the actual data returned by the function
        PERFORM * FROM get_startup_financial_summary(test_startup_id);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;

-- Check if there are any sample data records that should be deleted
SELECT 'Sample data check:' as status;
SELECT 
    id,
    startup_id,
    record_type,
    description,
    amount,
    created_at
FROM financial_records 
WHERE description IN ('AWS Services', 'Salaries - Engineering', 'Marketing Campaign', 'Office Rent', 'Legal Services')
   OR description LIKE '%Sample%'
   OR description LIKE '%Test%'
ORDER BY created_at DESC;
