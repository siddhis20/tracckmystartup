-- =====================================================
-- TEST DATABASE CONNECTION
-- =====================================================
-- This script tests basic database connectivity and table access

-- 1. Test basic connection
SELECT '1. Testing basic connection:' as step;
SELECT NOW() as current_time, version() as postgres_version;

-- 2. Test if we can access the opportunity_applications table
SELECT '2. Testing table access:' as step;
SELECT 
    'Can select from opportunity_applications' as test,
    COUNT(*) as record_count
FROM opportunity_applications;

-- 3. Check if the table has the required columns
SELECT '3. Checking table structure:' as step;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications'
AND column_name IN ('id', 'startup_id', 'opportunity_id', 'status', 'diligence_status', 'updated_at')
ORDER BY column_name;

-- 4. Check current data in the table
SELECT '4. Current data sample:' as step;
SELECT 
    id,
    startup_id,
    opportunity_id,
    status,
    diligence_status,
    created_at,
    updated_at
FROM opportunity_applications
LIMIT 5;

-- 5. Check if RPC functions are accessible
SELECT '5. Testing RPC access:' as step;
SELECT 
    'Can access RPC functions' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_type = 'FUNCTION'
        ) THEN '✅ YES'
        ELSE '❌ NO'
    END as status;

-- 6. Summary
SELECT 'CONNECTION TEST COMPLETE' as summary;
SELECT 
    'Database connection' as test,
    CASE 
        WHEN COUNT(*) > 0 FROM opportunity_applications THEN '✅ SUCCESS'
        ELSE '❌ FAILED'
    END as status;
