-- Delete the specific corrupted record causing the $2.3 billion issue
-- This will remove the record with amount 2315612302.00

-- 1. First, let's see what we're about to delete
SELECT 
    'Corrupted record to be deleted:' as info,
    id,
    record_type,
    description,
    amount,
    created_at
FROM financial_records 
WHERE id = '0096c33d-c917-456a-ba19-08b22133f047';

-- 2. Delete the corrupted record
DELETE FROM financial_records 
WHERE id = '0096c33d-c917-456a-ba19-08b22133f047';

-- 3. Show remaining records
SELECT 
    'Remaining records:' as info,
    COUNT(*) as count,
    SUM(CASE WHEN record_type = 'revenue' THEN amount ELSE 0 END) as total_revenue,
    SUM(CASE WHEN record_type = 'expense' THEN amount ELSE 0 END) as total_expenses
FROM financial_records 
WHERE startup_id = 11;

-- 4. Check the summary again
SELECT * FROM get_startup_financial_summary(11);
