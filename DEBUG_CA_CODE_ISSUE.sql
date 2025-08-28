-- =====================================================
-- DEBUG CA CODE ISSUE
-- =====================================================
-- This script helps debug why CA codes aren't triggering assignment requests
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: CHECK STARTUPS TABLE STRUCTURE
-- =====================================================

-- Check what columns exist in startups table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name LIKE '%ca%'
ORDER BY ordinal_position;

-- Check if ca_service_code column exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'startups' AND column_name = 'ca_service_code'
        ) THEN '✅ ca_service_code column EXISTS'
        ELSE '❌ ca_service_code column MISSING'
    END as ca_service_code_status;

-- =====================================================
-- STEP 2: CHECK TRIGGER STATUS
-- =====================================================

-- Check if the trigger exists
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_ca_code_assignment';

-- Check if the function exists
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'handle_ca_code_assignment';

-- =====================================================
-- STEP 3: CHECK CA ASSIGNMENT REQUESTS TABLE
-- =====================================================

-- Check if ca_assignment_requests table exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'ca_assignment_requests'
        ) THEN '✅ ca_assignment_requests table EXISTS'
        ELSE '❌ ca_assignment_requests table MISSING'
    END as ca_assignment_requests_status;

-- Check table structure if it exists
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'ca_assignment_requests'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 4: CHECK CA ASSIGNMENTS TABLE
-- =====================================================

-- Check if ca_assignments table exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'ca_assignments'
        ) THEN '✅ ca_assignments table EXISTS'
        ELSE '❌ ca_assignments table MISSING'
    END as ca_assignments_status;

-- Check table structure if it exists
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'ca_assignments'
ORDER BY ordinal_position;

-- =====================================================
-- STEP 5: CHECK CURRENT DATA
-- =====================================================

-- Check current startups with CA codes
SELECT 
    id,
    name,
    ca_service_code,
    cs_service_code
FROM public.startups 
WHERE ca_service_code IS NOT NULL OR cs_service_code IS NOT NULL
LIMIT 10;

-- Check if any CA assignment requests exist
SELECT 
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
    COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_requests,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_requests
FROM ca_assignment_requests;

-- Check if any CA assignments exist
SELECT 
    COUNT(*) as total_assignments,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_assignments,
    COUNT(CASE WHEN status = 'inactive' THEN 1 END) as inactive_assignments
FROM ca_assignments;

-- =====================================================
-- STEP 6: TEST TRIGGER MANUALLY
-- =====================================================

-- Test the trigger function manually
SELECT 'Testing trigger function...' as test_step;

-- Try to create a test assignment request
SELECT create_ca_assignment_request(1, 'CA-TEST01', 'Test assignment request') as test_result;

-- =====================================================
-- STEP 7: VERIFICATION SUMMARY
-- =====================================================

SELECT '🔍 CA Code System Debug Complete!' as status;
