-- =====================================================
-- TEST POOJA UTILIZATION SPECIFICALLY
-- =====================================================
-- This script tests the specific pooja investor utilization issue

-- 1. Check pooja investor details
SELECT 
    'POOJA INVESTOR' as check_type,
    investor_name,
    amount as investment_amount,
    investor_type,
    created_at
FROM investment_records 
WHERE investor_name ILIKE '%pooja%';

-- 2. Check if the expense with pooja funding source exists
SELECT 
    'POOJA EXPENSE' as check_type,
    record_type,
    funding_source,
    amount as expense_amount,
    description,
    date,
    created_at
FROM financial_records 
WHERE funding_source ILIKE '%pooja%';

-- 3. Check the exact string matching
SELECT 
    'STRING MATCHING TEST' as check_type,
    ir.investor_name,
    ir.investor_type,
    CONCAT(ir.investor_name, ' (', ir.investor_type, ')') as expected_funding_source,
    fr.funding_source as actual_funding_source,
    CASE 
        WHEN fr.funding_source = CONCAT(ir.investor_name, ' (', ir.investor_type, ')') THEN 'EXACT MATCH'
        WHEN LOWER(fr.funding_source) = LOWER(CONCAT(ir.investor_name, ' (', ir.investor_type, ')')) THEN 'CASE INSENSITIVE MATCH'
        ELSE 'NO MATCH'
    END as match_status,
    fr.amount as expense_amount
FROM investment_records ir
LEFT JOIN financial_records fr ON 
    fr.record_type = 'expense'
    AND (fr.funding_source ILIKE '%pooja%' OR ir.investor_name ILIKE '%pooja%')
WHERE ir.investor_name ILIKE '%pooja%';

-- 4. Check all recent financial records to see what's being stored
SELECT 
    'RECENT FINANCIAL RECORDS' as check_type,
    id,
    record_type,
    funding_source,
    amount,
    description,
    date,
    created_at
FROM financial_records 
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- 5. Test the utilization calculation manually
WITH pooja_utilization AS (
    SELECT 
        ir.investor_name,
        ir.amount as investment_amount,
        COALESCE(SUM(fr.amount), 0) as utilized_amount
    FROM investment_records ir
    LEFT JOIN financial_records fr ON 
        fr.funding_source ILIKE CONCAT('%', ir.investor_name, '%')
        AND fr.record_type = 'expense'
    WHERE ir.investor_name ILIKE '%pooja%'
    GROUP BY ir.investor_name, ir.amount
)
SELECT 
    'MANUAL UTILIZATION CALC' as check_type,
    investor_name,
    investment_amount,
    utilized_amount,
    ROUND((utilized_amount / investment_amount) * 100, 2) as utilization_percentage
FROM pooja_utilization;
