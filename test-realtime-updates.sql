-- =====================================================
-- TEST REAL-TIME UPDATES
-- =====================================================

-- First, let's check what startups we have
SELECT '=== CURRENT STARTUPS ===' as test_step;
SELECT id, name, country_of_registration, company_type FROM startups ORDER BY id LIMIT 3;

-- Test 1: Update a startup profile
SELECT '=== TEST 1: UPDATE STARTUP PROFILE ===' as test_step;
DO $$
DECLARE
    startup_id_val INTEGER;
    update_result BOOLEAN;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing profile update for startup ID: %', startup_id_val;
        
        -- Update the profile
        SELECT update_startup_profile_simple(startup_id_val, 'Canada', 'Corporation', 'CA-TEST-123', 'CS-TEST-456') INTO update_result;
        
        IF update_result THEN
            RAISE NOTICE '✅ Profile update successful';
        ELSE
            RAISE NOTICE '❌ Profile update failed';
        END IF;
        
        -- Show the updated data
        PERFORM 
            id, 
            name, 
            country_of_registration, 
            company_type, 
            ca_service_code, 
            cs_service_code,
            profile_updated_at
        FROM startups 
        WHERE id = startup_id_val;
        
    ELSE
        RAISE NOTICE 'No startups found';
    END IF;
END $$;

-- Test 2: Add a subsidiary
SELECT '=== TEST 2: ADD SUBSIDIARY ===' as test_step;
DO $$
DECLARE
    startup_id_val INTEGER;
    subsidiary_id INTEGER;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing subsidiary addition for startup ID: %', startup_id_val;
        
        -- Add a subsidiary
        SELECT add_subsidiary_simple(startup_id_val, 'UK', 'Limited Company (Ltd)', '2024-01-15') INTO subsidiary_id;
        
        IF subsidiary_id IS NOT NULL THEN
            RAISE NOTICE '✅ Subsidiary added successfully with ID: %', subsidiary_id;
        ELSE
            RAISE NOTICE '❌ Subsidiary addition failed';
        END IF;
        
        -- Show current subsidiaries
        PERFORM 
            id, 
            startup_id, 
            country, 
            company_type, 
            registration_date
        FROM subsidiaries 
        WHERE startup_id = startup_id_val;
        
    ELSE
        RAISE NOTICE 'No startups found';
    END IF;
END $$;

-- Test 3: Add an international operation
SELECT '=== TEST 3: ADD INTERNATIONAL OPERATION ===' as test_step;
DO $$
DECLARE
    startup_id_val INTEGER;
    op_id INTEGER;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing international operation addition for startup ID: %', startup_id_val;
        
        -- Add an international operation
        SELECT add_international_op_simple(startup_id_val, 'Germany', '2024-02-01') INTO op_id;
        
        IF op_id IS NOT NULL THEN
            RAISE NOTICE '✅ International operation added successfully with ID: %', op_id;
        ELSE
            RAISE NOTICE '❌ International operation addition failed';
        END IF;
        
        -- Show current international operations
        PERFORM 
            id, 
            startup_id, 
            country, 
            start_date
        FROM international_ops 
        WHERE startup_id = startup_id_val;
        
    ELSE
        RAISE NOTICE 'No startups found';
    END IF;
END $$;

-- Test 4: Get complete profile
SELECT '=== TEST 4: GET COMPLETE PROFILE ===' as test_step;
DO $$
DECLARE
    startup_id_val INTEGER;
    profile_data JSONB;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing complete profile retrieval for startup ID: %', startup_id_val;
        
        -- Get the complete profile
        SELECT get_startup_profile_simple(startup_id_val) INTO profile_data;
        
        IF profile_data IS NOT NULL THEN
            RAISE NOTICE '✅ Complete profile retrieved successfully';
            RAISE NOTICE 'Profile data: %', profile_data;
        ELSE
            RAISE NOTICE '❌ Profile retrieval failed';
        END IF;
        
    ELSE
        RAISE NOTICE 'No startups found';
    END IF;
END $$;

-- Show final state
SELECT '=== FINAL STATE ===' as test_step;
SELECT 
    'Startups' as table_name,
    COUNT(*) as record_count
FROM startups
UNION ALL
SELECT 
    'Subsidiaries' as table_name,
    COUNT(*) as record_count
FROM subsidiaries
UNION ALL
SELECT 
    'International Operations' as table_name,
    COUNT(*) as record_count
FROM international_ops;

SELECT 'Real-time update tests completed. Check the NOTICE messages above.' as summary;
