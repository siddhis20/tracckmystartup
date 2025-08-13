-- =====================================================
-- TEST PROFILE FUNCTION DIRECTLY
-- =====================================================

-- First, let's see what's actually in the database for subsidiary 27
SELECT 'Current subsidiary 27 in database:' as info;
SELECT id, startup_id, country, company_type, registration_date, updated_at 
FROM subsidiaries 
WHERE id = 27;

-- Test what the function returns
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    profile_data JSONB;
    subsidiaries_data JSONB;
BEGIN
    RAISE NOTICE 'Testing get_startup_profile_simple for startup ID: %', test_startup_id;
    
    -- Call the function
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data;
    
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

-- Compare with direct SQL query for the same data
SELECT 'Direct SQL query for subsidiaries of startup 11:' as info;
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

-- Test if there's a transaction isolation issue
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    profile_data1 JSONB;
    profile_data2 JSONB;
BEGIN
    RAISE NOTICE 'Testing for transaction isolation...';
    
    -- Call function twice with a small delay
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data1;
    PERFORM pg_sleep(0.1); -- Small delay
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data2;
    
    IF profile_data1 = profile_data2 THEN
        RAISE NOTICE 'Function results are identical';
    ELSE
        RAISE NOTICE 'Function results are different';
    END IF;
    
    RAISE NOTICE 'First call subsidiaries: %', profile_data1->'subsidiaries';
    RAISE NOTICE 'Second call subsidiaries: %', profile_data2->'subsidiaries';
    
END $$;

-- Check if the function is using a different transaction
SELECT 'Function definition to check for transaction issues:' as info;
SELECT pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'get_startup_profile_simple' 
AND pronargs = 1;
