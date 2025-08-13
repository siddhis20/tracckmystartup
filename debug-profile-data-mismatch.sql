-- =====================================================
-- DEBUG PROFILE DATA MISMATCH
-- =====================================================

-- First, let's see what's actually in the database
SELECT 'Current subsidiaries in database:' as info;
SELECT id, startup_id, country, company_type, registration_date, updated_at 
FROM subsidiaries 
WHERE startup_id = 11
ORDER BY id;

-- Test the get_startup_profile_simple function
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    profile_data JSONB;
    subsidiaries_data JSONB;
BEGIN
    RAISE NOTICE 'Testing get_startup_profile_simple for startup ID: %', test_startup_id;
    
    -- Call the function
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data;
    
    RAISE NOTICE 'Full function result: %', profile_data;
    
    -- Extract subsidiaries specifically
    IF profile_data IS NOT NULL AND profile_data ? 'subsidiaries' THEN
        subsidiaries_data := profile_data->'subsidiaries';
        RAISE NOTICE 'Subsidiaries from function: %', subsidiaries_data;
        
        -- Check each subsidiary
        FOR i IN 0..jsonb_array_length(subsidiaries_data)-1 LOOP
            RAISE NOTICE 'Subsidiary %: %', i, subsidiaries_data->i;
        END LOOP;
    ELSE
        RAISE NOTICE 'No subsidiaries found in function result';
    END IF;
    
END $$;

-- Compare with direct SQL query
SELECT 'Direct SQL query for subsidiaries:' as info;
SELECT 
    sub.id,
    sub.startup_id,
    sub.country,
    sub.company_type,
    sub.registration_date,
    sub.updated_at
FROM subsidiaries sub
WHERE sub.startup_id = 11
ORDER BY sub.id;

-- Test if the function is using cached data by forcing a refresh
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    profile_data1 JSONB;
    profile_data2 JSONB;
BEGIN
    RAISE NOTICE 'Testing for caching issues...';
    
    -- Call function twice
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data1;
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data2;
    
    IF profile_data1 = profile_data2 THEN
        RAISE NOTICE 'Function results are identical (no caching issue)';
    ELSE
        RAISE NOTICE 'Function results are different (possible caching issue)';
    END IF;
    
    RAISE NOTICE 'First call: %', profile_data1->'subsidiaries';
    RAISE NOTICE 'Second call: %', profile_data2->'subsidiaries';
    
END $$;

-- Check if there are any triggers that might be interfering
SELECT 'Checking for triggers on subsidiaries table:' as info;
SELECT trigger_name, event_manipulation, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'subsidiaries';
