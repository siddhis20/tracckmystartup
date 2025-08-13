-- =====================================================
-- TEST SUBSIDIARY DATE RETURN
-- =====================================================

-- First, let's see what's actually in the database for subsidiary 27
SELECT 'Current subsidiary 27 in database:' as info;
SELECT id, startup_id, country, company_type, registration_date, updated_at 
FROM subsidiaries 
WHERE id = 27;

-- Test what the function returns for this specific subsidiary
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    profile_data JSONB;
    subsidiaries_data JSONB;
    subsidiary_27_data JSONB;
BEGIN
    RAISE NOTICE 'Testing get_startup_profile_simple for startup ID: %', test_startup_id;
    
    -- Call the function
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data;
    
    -- Extract subsidiaries specifically
    IF profile_data IS NOT NULL AND profile_data ? 'subsidiaries' THEN
        subsidiaries_data := profile_data->'subsidiaries';
        RAISE NOTICE 'All subsidiaries from function: %', subsidiaries_data;
        
        -- Look for subsidiary 27 specifically
        FOR i IN 0..jsonb_array_length(subsidiaries_data)-1 LOOP
            subsidiary_27_data := subsidiaries_data->i;
            IF (subsidiary_27_data->>'id')::INTEGER = 27 THEN
                RAISE NOTICE 'Found subsidiary 27 in function result: %', subsidiary_27_data;
                RAISE NOTICE 'Subsidiary 27 registration_date: %', subsidiary_27_data->>'registration_date';
                EXIT;
            END IF;
        END LOOP;
    ELSE
        RAISE NOTICE 'No subsidiaries found in function result';
    END IF;
    
END $$;

-- Also test the direct subsidiaries function
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    subsidiaries_data JSONB;
    subsidiary_27_data JSONB;
BEGIN
    RAISE NOTICE 'Testing get_subsidiaries_direct function...';
    
    SELECT get_subsidiaries_direct(test_startup_id) INTO subsidiaries_data;
    
    RAISE NOTICE 'Direct subsidiaries result: %', subsidiaries_data;
    
    -- Look for subsidiary 27 specifically
    FOR i IN 0..jsonb_array_length(subsidiaries_data)-1 LOOP
        subsidiary_27_data := subsidiaries_data->i;
        IF (subsidiary_27_data->>'id')::INTEGER = 27 THEN
            RAISE NOTICE 'Found subsidiary 27 in direct function: %', subsidiary_27_data;
            RAISE NOTICE 'Subsidiary 27 registration_date: %', subsidiary_27_data->>'registration_date';
            EXIT;
        END IF;
    END LOOP;
    
END $$;

-- Test a direct SQL query to compare
SELECT 'Direct SQL query for subsidiary 27:' as info;
SELECT 
    id,
    startup_id,
    country,
    company_type,
    registration_date,
    updated_at
FROM subsidiaries 
WHERE id = 27;
