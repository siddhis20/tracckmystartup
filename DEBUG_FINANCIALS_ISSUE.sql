-- =====================================================
-- DEBUG FINANCIALS ISSUE
-- =====================================================
-- This script helps debug why new expenses aren't showing up

-- 1. Check if financial_records table exists and has data
SELECT 
    'TABLE INFO' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN record_type = 'expense' THEN 1 END) as expense_count,
    COUNT(CASE WHEN record_type = 'revenue' THEN 1 END) as revenue_count
FROM financial_records;

-- 2. Check recent financial records (last 24 hours)
SELECT 
    'RECENT RECORDS' as check_type,
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
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- 3. Check all financial records for debugging
SELECT 
    'ALL RECORDS' as check_type,
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
ORDER BY created_at DESC
LIMIT 20;

-- 4. Check if there are any RLS policy issues
SELECT 
    'RLS POLICIES' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'financial_records';

-- 5. Check table structure
SELECT 
    'TABLE STRUCTURE' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'financial_records'
ORDER BY ordinal_position;

-- 6. Check for any startup_id issues
SELECT 
    'STARTUP IDS' as check_type,
    startup_id,
    COUNT(*) as record_count,
    MIN(created_at) as first_record,
    MAX(created_at) as last_record
FROM financial_records 
GROUP BY startup_id
ORDER BY startup_id;
