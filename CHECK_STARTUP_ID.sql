-- =====================================================
-- CHECK STARTUP ID ISSUE
-- =====================================================

-- 1. Check all startups in the system
SELECT 
    'ALL STARTUPS' as check_type,
    id,
    name,
    created_at
FROM startups
ORDER BY id;

-- 2. Check which startup_id is being used in financial_records
SELECT 
    'FINANCIAL RECORDS STARTUP' as check_type,
    startup_id,
    COUNT(*) as record_count
FROM financial_records
GROUP BY startup_id;

-- 3. Check if there are any records with startup_id = 1
SELECT 
    'CHECK STARTUP ID 1' as check_type,
    COUNT(*) as records_with_id_1
FROM financial_records
WHERE startup_id = 1;

-- 4. Check if there are any records with startup_id = 11
SELECT 
    'CHECK STARTUP ID 11' as check_type,
    COUNT(*) as records_with_id_11
FROM financial_records
WHERE startup_id = 11;

-- 5. Show the actual financial records
SELECT 
    'ACTUAL RECORDS' as check_type,
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
ORDER BY created_at DESC;

