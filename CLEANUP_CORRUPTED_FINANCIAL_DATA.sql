-- Cleanup Corrupted Financial Data
-- This script will remove any corrupted or incorrect financial records

-- 1. First, let's see what we're about to delete
SELECT 
    'Records to be deleted:' as info,
    COUNT(*) as count,
    SUM(amount) as total_amount
FROM financial_records 
WHERE startup_id = 11 
AND (amount > 1000000 OR amount < -1000000);

-- 2. Delete any records with extremely large amounts (likely corrupted)
DELETE FROM financial_records 
WHERE startup_id = 11 
AND (amount > 1000000 OR amount < -1000000);

-- 3. Delete any records with negative amounts (expenses should be positive)
DELETE FROM financial_records 
WHERE startup_id = 11 
AND record_type = 'expense' 
AND amount < 0;

-- 4. Delete any records with zero amounts (likely test data)
DELETE FROM financial_records 
WHERE startup_id = 11 
AND amount = 0;

-- 5. Show remaining records
SELECT 
    'Remaining records:' as info,
    COUNT(*) as count,
    SUM(CASE WHEN record_type = 'revenue' THEN amount ELSE 0 END) as total_revenue,
    SUM(CASE WHEN record_type = 'expense' THEN amount ELSE 0 END) as total_expenses
FROM financial_records 
WHERE startup_id = 11;

-- 6. Check the summary again
SELECT * FROM get_startup_financial_summary(11);
