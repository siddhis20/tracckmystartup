-- Fix CS Request Creation Issue
-- This script ensures the create_cs_assignment_request function works correctly

-- 1. Drop all existing versions of the function
DROP FUNCTION IF EXISTS create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT);
DROP FUNCTION IF EXISTS create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT);
DROP FUNCTION IF EXISTS public.create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT, TEXT);

-- 2. Create the correct function with proper signature
CREATE OR REPLACE FUNCTION create_cs_assignment_request(
    startup_id_param BIGINT,
    startup_name_param TEXT,
    cs_code_param VARCHAR(20),
    notes_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    cs_exists BOOLEAN;
    request_exists BOOLEAN;
BEGIN
    -- Debug logging
    RAISE NOTICE 'Creating CS assignment request: startup_id=%, startup_name=%, cs_code=%, notes=%', 
        startup_id_param, startup_name_param, cs_code_param, notes_param;
    
    -- Check if CS code exists
    SELECT EXISTS(SELECT 1 FROM public.users WHERE cs_code = cs_code_param AND role = 'CS') INTO cs_exists;
    IF NOT cs_exists THEN
        RAISE NOTICE 'CS code % not found or user is not a CS', cs_code_param;
        RETURN FALSE;
    END IF;
    
    -- Check if request already exists
    SELECT EXISTS(
        SELECT 1 FROM public.cs_assignment_requests 
        WHERE startup_id = startup_id_param 
        AND cs_code = cs_code_param 
        AND status = 'pending'
    ) INTO request_exists;
    
    IF request_exists THEN
        RAISE NOTICE 'Request already exists for startup % and CS %', startup_id_param, cs_code_param;
        RETURN FALSE;
    END IF;
    
    -- Create the request
    INSERT INTO public.cs_assignment_requests (
        startup_id, startup_name, cs_code, notes
    ) VALUES (
        startup_id_param, startup_name_param, cs_code_param, notes_param
    );
    
    RAISE NOTICE 'CS assignment request created successfully';
    RETURN TRUE;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error creating CS assignment request: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Grant execute permissions
GRANT EXECUTE ON FUNCTION create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT) TO authenticated;

-- 4. Test the function
DO $$
DECLARE
    test_startup_id BIGINT;
    test_cs_code VARCHAR;
    result BOOLEAN;
BEGIN
    RAISE NOTICE '=== Testing Fixed CS Request Creation ===';
    
    -- Get a startup ID
    SELECT id INTO test_startup_id FROM startups LIMIT 1;
    
    -- Get the CS code
    SELECT cs_code INTO test_cs_code FROM auth.users WHERE email = 'network@startupnationindia.com';
    
    IF test_startup_id IS NOT NULL AND test_cs_code IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup ID: %, CS code: %', test_startup_id, test_cs_code;
        
        -- Test the function
        SELECT create_cs_assignment_request(test_startup_id, 'Test Startup', test_cs_code, 'Test request from script') INTO result;
        
        RAISE NOTICE 'Request creation result: %', result;
        
        -- Check if request was created
        IF EXISTS (SELECT 1 FROM cs_assignment_requests WHERE startup_id = test_startup_id AND cs_code = test_cs_code) THEN
            RAISE NOTICE '✅ Request successfully created!';
        ELSE
            RAISE NOTICE '❌ Request was not created';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ Missing startup ID or CS code for testing';
    END IF;
    
    RAISE NOTICE '=== Test Complete ===';
END $$;

-- 5. Show the function signature
SELECT 
    'Function Signature' as check_type,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
    AND p.proname = 'create_cs_assignment_request';
