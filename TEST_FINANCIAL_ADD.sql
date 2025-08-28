-- =====================================================
-- TEST ADDING FINANCIAL RECORD
-- =====================================================

-- Add a test expense record
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
    11,  -- Using the correct startup_id
    'expense',
    CURRENT_DATE,
    'Parent Company',
    'TEST EXPENSE - Frontend Debug',
    'Other Expenses',
    150.00,
    'Revenue',
    NOW(),
    NOW()
);

-- Verify the record was added
SELECT 
    'TEST RECORD ADDED' as check_type,
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
WHERE description = 'TEST EXPENSE - Frontend Debug'
ORDER BY created_at DESC
LIMIT 1;

-- Show all records for startup_id = 11
SELECT 
    'ALL RECORDS FOR STARTUP 11' as check_type,
    COUNT(*) as total_records
FROM financial_records 
WHERE startup_id = 11;

