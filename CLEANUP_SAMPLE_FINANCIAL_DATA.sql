-- =====================================================
-- CLEANUP SAMPLE FINANCIAL DATA
-- =====================================================

-- First, let's see what sample data exists
SELECT 'Sample data to be removed:' as status;
SELECT 
    id,
    startup_id,
    record_type,
    description,
    amount,
    created_at
FROM financial_records 
WHERE description IN (
    'AWS Services', 
    'Salaries - Engineering', 
    'Marketing Campaign', 
    'Office Rent', 
    'Legal Services',
    'Product Sales',
    'Consulting Services',
    'Subscription Revenue'
)
   OR description LIKE '%Sample%'
   OR description LIKE '%Test%'
   OR description LIKE '%Mock%'
ORDER BY created_at DESC;

-- Count how many sample records exist
SELECT 'Sample data count:' as status;
SELECT 
    COUNT(*) as total_sample_records,
    COUNT(CASE WHEN record_type = 'expense' THEN 1 END) as sample_expenses,
    COUNT(CASE WHEN record_type = 'revenue' THEN 1 END) as sample_revenues,
    SUM(CASE WHEN record_type = 'expense' THEN amount ELSE 0 END) as total_sample_expenses,
    SUM(CASE WHEN record_type = 'revenue' THEN amount ELSE 0 END) as total_sample_revenues
FROM financial_records 
WHERE description IN (
    'AWS Services', 
    'Salaries - Engineering', 
    'Marketing Campaign', 
    'Office Rent', 
    'Legal Services',
    'Product Sales',
    'Consulting Services',
    'Subscription Revenue'
)
   OR description LIKE '%Sample%'
   OR description LIKE '%Test%'
   OR description LIKE '%Mock%';

-- Remove sample data (uncomment the DELETE statement below after reviewing)
-- DELETE FROM financial_records 
-- WHERE description IN (
--     'AWS Services', 
--     'Salaries - Engineering', 
--     'Marketing Campaign', 
--     'Office Rent', 
--     'Legal Services',
--     'Product Sales',
--     'Consulting Services',
--     'Subscription Revenue'
-- )
--    OR description LIKE '%Sample%'
--    OR description LIKE '%Test%'
--    OR description LIKE '%Mock%';

-- After cleanup, check the remaining data
SELECT 'Remaining financial records after cleanup:' as status;
SELECT 
    startup_id,
    COUNT(*) as total_records,
    COUNT(CASE WHEN record_type = 'expense' THEN 1 END) as expense_count,
    COUNT(CASE WHEN record_type = 'revenue' THEN 1 END) as revenue_count,
    SUM(CASE WHEN record_type = 'expense' THEN amount ELSE 0 END) as total_expenses,
    SUM(CASE WHEN record_type = 'revenue' THEN amount ELSE 0 END) as total_revenue
FROM financial_records 
GROUP BY startup_id;

-- Test the financial summary function after cleanup
SELECT 'Testing financial summary after cleanup:' as status;
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    SELECT id INTO test_startup_id FROM startups ORDER BY id LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        RAISE NOTICE 'Testing financial summary for startup ID: %', test_startup_id;
        PERFORM * FROM get_startup_financial_summary(test_startup_id);
    ELSE
        RAISE NOTICE 'No startup found for testing';
    END IF;
END $$;
