-- =====================================================
-- DEBUG UTILIZATION ISSUE FOR POOJA INVESTOR
-- =====================================================
-- This script helps debug why utilization isn't working

-- 1. Check if pooja investor exists
SELECT 
    id,
    investor_name,
    amount,
    investor_type,
    created_at
FROM investment_records 
WHERE investor_name ILIKE '%pooja%'
ORDER BY created_at DESC;

-- 2. Check if there are any financial records with pooja funding source
SELECT 
    id,
    record_type,
    funding_source,
    amount,
    date,
    description,
    created_at
FROM financial_records 
WHERE funding_source ILIKE '%pooja%'
ORDER BY created_at DESC;

-- 3. Check all funding sources in financial records
SELECT DISTINCT funding_source
FROM financial_records 
WHERE funding_source IS NOT NULL
ORDER BY funding_source;

-- 4. Check the exact format of pooja's funding source
SELECT 
    ir.investor_name,
    ir.investor_type,
    CONCAT(ir.investor_name, ' (', ir.investor_type, ')') as expected_funding_source,
    fr.funding_source as actual_funding_source,
    fr.amount,
    fr.record_type
FROM investment_records ir
LEFT JOIN financial_records fr ON 
    fr.funding_source = CONCAT(ir.investor_name, ' (', ir.investor_type, ')')
    AND fr.record_type = 'expense'
WHERE ir.investor_name ILIKE '%pooja%';

-- 5. Check if there are any case sensitivity issues
SELECT 
    ir.investor_name,
    ir.investor_type,
    fr.funding_source,
    CASE 
        WHEN fr.funding_source = CONCAT(ir.investor_name, ' (', ir.investor_type, ')') THEN 'EXACT MATCH'
        WHEN LOWER(fr.funding_source) = LOWER(CONCAT(ir.investor_name, ' (', ir.investor_type, ')')) THEN 'CASE INSENSITIVE MATCH'
        ELSE 'NO MATCH'
    END as match_status
FROM investment_records ir
LEFT JOIN financial_records fr ON 
    fr.record_type = 'expense'
WHERE ir.investor_name ILIKE '%pooja%';

-- 6. Check recent financial records to see what's being stored
SELECT 
    id,
    record_type,
    funding_source,
    amount,
    date,
    description,
    startup_id,
    created_at
FROM financial_records 
WHERE created_at >= NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 10;
