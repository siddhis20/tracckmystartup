-- =====================================================
-- DEBUG PROFILE FUNCTIONS - COMPREHENSIVE CHECK
-- =====================================================

-- Step 1: Check if startups table exists and has data
SELECT '=== STEP 1: CHECK STARTUPS TABLE ===' as debug_step;
SELECT COUNT(*) as total_startups FROM startups;

-- Step 2: Check if profile columns were added to startups table
SELECT '=== STEP 2: CHECK PROFILE COLUMNS ===' as debug_step;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND table_schema = 'public'
AND column_name IN ('country_of_registration', 'company_type', 'ca_service_code', 'cs_service_code', 'profile_updated_at', 'user_id')
ORDER BY column_name;

-- Step 3: Check if profile functions exist
SELECT '=== STEP 3: CHECK PROFILE FUNCTIONS ===' as debug_step;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'get_startup_profile',
    'update_startup_profile',
    'add_subsidiary',
    'update_subsidiary',
    'delete_subsidiary',
    'add_international_op',
    'update_international_op',
    'delete_international_op'
)
ORDER BY routine_name;

-- Step 4: Check if profile tables exist
SELECT '=== STEP 4: CHECK PROFILE TABLES ===' as debug_step;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'profile_audit_log',
    'profile_notifications',
    'profile_templates'
)
ORDER BY table_name;

-- Step 5: Check if subsidiaries and international_ops tables exist
SELECT '=== STEP 5: CHECK SUBSIDIARIES AND INTERNATIONAL OPS ===' as debug_step;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'subsidiaries',
    'international_ops'
)
ORDER BY table_name;

-- Step 6: Check if RLS policies exist
SELECT '=== STEP 6: CHECK RLS POLICIES ===' as debug_step;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN (
    'profile_audit_log',
    'profile_notifications',
    'profile_templates'
)
ORDER BY tablename, policyname;

-- Step 7: Check if triggers exist
SELECT '=== STEP 7: CHECK TRIGGERS ===' as debug_step;
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND trigger_name LIKE '%profile%'
ORDER BY trigger_name;

-- Step 8: Test with a specific startup (if any exist)
SELECT '=== STEP 8: TEST WITH EXISTING STARTUP ===' as debug_step;
DO $$
DECLARE
    startup_id_val INTEGER;
    test_result JSONB;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup ID: %', startup_id_val;
        
        -- Test get_startup_profile function
        BEGIN
            SELECT get_startup_profile(startup_id_val) INTO test_result;
            RAISE NOTICE 'get_startup_profile result: %', test_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'get_startup_profile failed: %', SQLERRM;
        END;
        
        -- Test update_startup_profile function
        BEGIN
            PERFORM update_startup_profile(startup_id_val, 'USA', 'C-Corporation', 'CA-TEST', 'CS-TEST');
            RAISE NOTICE 'update_startup_profile completed successfully';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'update_startup_profile failed: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE 'No startups found in database';
    END IF;
END $$;

-- Step 9: Check for any errors in recent logs
SELECT '=== STEP 9: CHECK FOR ERRORS ===' as debug_step;
SELECT 
    'No specific error checking available in this environment' as note;

-- Step 10: Summary
SELECT '=== STEP 10: SUMMARY ===' as debug_step;
SELECT 
    'Debug check completed. Review results above.' as summary,
    'If functions are missing, re-run the PROFILE_SECTION_DYNAMIC_TABLES.sql script' as recommendation;
