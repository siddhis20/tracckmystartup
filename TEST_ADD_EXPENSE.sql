-- =====================================================
-- TEST ADD EXPENSE FUNCTIONALITY
-- =====================================================

-- 1. Check current count before adding
SELECT 
    'BEFORE ADD' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN record_type = 'expense' THEN 1 END) as expense_count
FROM financial_records 
WHERE startup_id = 11;

-- 2. Add a test expense manually
INSERT INTO financial_records (
    startup_id,
    record_type,
    date,
    entity,
    description,
    vertical,
    amount,
    funding_source,
    created_at,
    updated_at
) VALUES (
    11,
    'expense',
    '2025-01-15',
    'Parent Company',
    'MANUAL TEST EXPENSE',
    'Other Expenses',
    250.00,
    'Revenue',
    NOW(),
    NOW()
);

-- 3. Check if the record was added
SELECT 
    'AFTER ADD' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN record_type = 'expense' THEN 1 END) as expense_count
FROM financial_records 
WHERE startup_id = 11;

-- 4. Show the newly added record
SELECT 
    'NEW RECORD' as check_type,
    id,
    record_type,
    date,
    entity,
    description,
    vertical,
    amount,
    funding_source,
    startup_id,
    created_at
FROM financial_records 
WHERE description = 'MANUAL TEST EXPENSE'
ORDER BY created_at DESC
LIMIT 1;

-- 5. Check RLS policies for financial_records
SELECT 
    'RLS CHECK' as check_type,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'financial_records';

