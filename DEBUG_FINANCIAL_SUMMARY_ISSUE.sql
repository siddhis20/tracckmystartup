-- Debug Financial Summary Issue
-- This script will help identify why the financial summary is showing incorrect values

-- 1. Check all financial records
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
    created_at,
    updated_at
FROM financial_records 
WHERE startup_id = 11
ORDER BY created_at DESC;

-- 2. Check summary calculations
SELECT 
    record_type,
    COUNT(*) as record_count,
    SUM(amount) as total_amount,
    MIN(amount) as min_amount,
    MAX(amount) as max_amount,
    AVG(amount) as avg_amount
FROM financial_records 
WHERE startup_id = 11
GROUP BY record_type;

-- 3. Check for any extremely large amounts
SELECT 
    id,
    record_type,
    description,
    amount,
    created_at
FROM financial_records 
WHERE startup_id = 11 
AND (amount > 1000000 OR amount < -1000000)
ORDER BY ABS(amount) DESC;

-- 4. Check the RPC function result
SELECT * FROM get_startup_financial_summary(11);

-- 5. Check if there are any records with wrong startup_id
SELECT 
    startup_id,
    COUNT(*) as record_count,
    SUM(CASE WHEN record_type = 'revenue' THEN amount ELSE 0 END) as total_revenue,
    SUM(CASE WHEN record_type = 'expense' THEN amount ELSE 0 END) as total_expenses
FROM financial_records 
GROUP BY startup_id
ORDER BY startup_id;

-- 6. Check for any data type issues
SELECT 
    id,
    record_type,
    amount,
    pg_typeof(amount) as amount_type,
    CASE 
        WHEN amount::text ~ '^[0-9]+\.?[0-9]*$' THEN 'Valid Number'
        ELSE 'Invalid Number'
    END as number_validity
FROM financial_records 
WHERE startup_id = 11
ORDER BY created_at DESC;
