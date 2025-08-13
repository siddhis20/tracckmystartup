-- =====================================================
-- TEST GET STARTUP PROFILE FUNCTION
-- =====================================================

-- First, let's see the current state of subsidiaries
SELECT 'Current subsidiaries:' as info;
SELECT id, startup_id, country, company_type, registration_date, updated_at 
FROM subsidiaries 
ORDER BY id;

-- Test the get_startup_profile_simple function
DO $$
DECLARE
    test_startup_id INTEGER := 11; -- Use the startup ID from the logs
    profile_data JSONB;
BEGIN
    RAISE NOTICE 'Testing get_startup_profile_simple for startup ID: %', test_startup_id;
    
    -- Call the function
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data;
    
    RAISE NOTICE 'Function result: %', profile_data;
    
    -- Show the subsidiaries part specifically
    IF profile_data IS NOT NULL AND profile_data ? 'subsidiaries' THEN
        RAISE NOTICE 'Subsidiaries from function: %', profile_data->'subsidiaries';
    ELSE
        RAISE NOTICE 'No subsidiaries found in function result';
    END IF;
    
END $$;

-- Also test with direct SQL to compare
SELECT 'Direct SQL query for startup 11:' as info;
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.country_of_registration,
    s.company_type,
    s.registration_date,
    json_agg(
        json_build_object(
            'id', sub.id,
            'country', sub.country,
            'companyType', sub.company_type,
            'registrationDate', sub.registration_date,
            'updated_at', sub.updated_at
        )
    ) as subsidiaries
FROM startups s
LEFT JOIN subsidiaries sub ON s.id = sub.startup_id
WHERE s.id = 11
GROUP BY s.id, s.name, s.country_of_registration, s.company_type, s.registration_date;

-- Check if there are any caching issues by looking at the function definition
SELECT 'Function definition:' as info;
SELECT pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'get_startup_profile_simple' 
AND pronargs = 1;
