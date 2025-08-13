-- =====================================================
-- CHECK SIMPLE FUNCTIONS RESULTS
-- =====================================================

-- Check if simple functions were created
SELECT '=== CHECKING SIMPLE FUNCTIONS ===' as check_step;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%_simple'
ORDER BY routine_name;

-- Check if profile columns were added to startups
SELECT '=== CHECKING PROFILE COLUMNS ===' as check_step;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND table_schema = 'public'
AND column_name IN ('country_of_registration', 'company_type', 'ca_service_code', 'cs_service_code', 'profile_updated_at', 'user_id')
ORDER BY column_name;

-- Test the simple functions with actual data
SELECT '=== TESTING WITH ACTUAL STARTUP ===' as test_step;
DO $$
DECLARE
    startup_id_val INTEGER;
    startup_name_val TEXT;
    test_result JSONB;
    update_result BOOLEAN;
    subsidiary_id INTEGER;
    op_id INTEGER;
BEGIN
    -- Get first startup with details
    SELECT id, name INTO startup_id_val, startup_name_val FROM startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Found startup: ID=%, Name=%', startup_id_val, startup_name_val;
        
        -- Test 1: Get current profile
        BEGIN
            SELECT get_startup_profile_simple(startup_id_val) INTO test_result;
            RAISE NOTICE 'Current profile: %', test_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'get_startup_profile_simple failed: %', SQLERRM;
        END;
        
        -- Test 2: Update profile
        BEGIN
            SELECT update_startup_profile_simple(startup_id_val, 'USA', 'C-Corporation', 'CA-12345', 'CS-67890') INTO update_result;
            RAISE NOTICE 'update_startup_profile_simple result: %', update_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'update_startup_profile_simple failed: %', SQLERRM;
        END;
        
        -- Test 3: Get updated profile
        BEGIN
            SELECT get_startup_profile_simple(startup_id_val) INTO test_result;
            RAISE NOTICE 'Updated profile: %', test_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Get updated profile failed: %', SQLERRM;
        END;
        
        -- Test 4: Add subsidiary
        BEGIN
            SELECT add_subsidiary_simple(startup_id_val, 'UK', 'Limited Company (Ltd)', '2023-06-01') INTO subsidiary_id;
            RAISE NOTICE 'add_subsidiary_simple result: %', subsidiary_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'add_subsidiary_simple failed: %', SQLERRM;
        END;
        
        -- Test 5: Add international operation
        BEGIN
            SELECT add_international_op_simple(startup_id_val, 'Canada', '2023-01-15') INTO op_id;
            RAISE NOTICE 'add_international_op_simple result: %', op_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'add_international_op_simple failed: %', SQLERRM;
        END;
        
        -- Test 6: Get final profile with all data
        BEGIN
            SELECT get_startup_profile_simple(startup_id_val) INTO test_result;
            RAISE NOTICE 'Final profile with subsidiaries and international ops: %', test_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Get final profile failed: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE 'No startups found in database';
    END IF;
END $$;

-- Show current startups data
SELECT '=== CURRENT STARTUPS DATA ===' as data_step;
SELECT 
    id,
    name,
    country_of_registration,
    company_type,
    ca_service_code,
    cs_service_code,
    profile_updated_at
FROM startups 
ORDER BY id;

-- Show subsidiaries data
SELECT '=== SUBSIDIARIES DATA ===' as data_step;
SELECT 
    id,
    startup_id,
    country,
    company_type,
    registration_date
FROM subsidiaries 
ORDER BY startup_id, id;

-- Show international operations data
SELECT '=== INTERNATIONAL OPERATIONS DATA ===' as data_step;
SELECT 
    id,
    startup_id,
    country,
    start_date
FROM international_ops 
ORDER BY startup_id, id;
