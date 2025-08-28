-- =====================================================
-- TEST UTILIZATION FEATURE
-- =====================================================
-- This script tests the utilization tracking functionality

-- Check financial records and their funding sources
SELECT 
    record_type,
    funding_source,
    amount,
    date,
    description
FROM financial_records 
WHERE funding_source IS NOT NULL
ORDER BY date DESC
LIMIT 10;

-- Check total expenses by funding source
SELECT 
    funding_source,
    COUNT(*) as expense_count,
    SUM(amount) as total_utilized,
    AVG(amount) as avg_expense
FROM financial_records 
WHERE record_type = 'expense' 
    AND funding_source IS NOT NULL
GROUP BY funding_source
ORDER BY total_utilized DESC;

-- Check investment records to compare with utilization
SELECT 
    investor_name,
    amount as investment_amount,
    investor_type
FROM investment_records
ORDER BY amount DESC;

-- Calculate utilization manually for verification
WITH investor_utilization AS (
    SELECT 
        ir.investor_name,
        ir.amount as investment_amount,
        COALESCE(SUM(fr.amount), 0) as utilized_amount
    FROM investment_records ir
    LEFT JOIN financial_records fr ON 
        fr.funding_source = CONCAT(ir.investor_name, ' (', ir.investor_type, ')')
        AND fr.record_type = 'expense'
    GROUP BY ir.investor_name, ir.amount
)
SELECT 
    investor_name,
    investment_amount,
    utilized_amount,
    ROUND((utilized_amount / investment_amount) * 100, 2) as utilization_percentage
FROM investor_utilization
ORDER BY utilization_percentage DESC;

-- Check for any funding sources that don't match investor names
SELECT DISTINCT funding_source
FROM financial_records 
WHERE funding_source IS NOT NULL
    AND funding_source NOT LIKE '%(Equity)%'
    AND funding_source != 'Revenue';
