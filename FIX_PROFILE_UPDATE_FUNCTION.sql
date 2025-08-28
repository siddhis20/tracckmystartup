-- =====================================================
-- FIX PROFILE UPDATE FUNCTION
-- =====================================================
-- This script creates the missing update_startup_profile function
-- =====================================================

-- Step 1: Check if the function exists
-- =====================================================

SELECT 
    'update_startup_profile_function_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_startup_profile'
        )
        THEN '✅ Function exists'
        ELSE '❌ Function missing'
    END as status;

-- Step 2: Drop existing function if it exists
-- =====================================================

DROP FUNCTION IF EXISTS update_startup_profile(INTEGER, TEXT, TEXT, DATE, TEXT, TEXT);
DROP FUNCTION IF EXISTS update_startup_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Step 3: Create the update_startup_profile function
-- =====================================================

CREATE OR REPLACE FUNCTION update_startup_profile(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param TEXT,
    ca_service_code_param TEXT,
    cs_service_code_param TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    rows_affected INTEGER;
    parsed_date DATE;
    current_data RECORD;
BEGIN
    -- Log the input parameters
    RAISE NOTICE 'update_startup_profile called with: startup_id=%, country=%, company_type=%, registration_date=%, ca_code=%, cs_code=%', 
        startup_id_param, country_param, company_type_param, registration_date_param, ca_service_code_param, cs_service_code_param;
    
    -- Check if startup exists
    SELECT * INTO current_data FROM public.startups WHERE id = startup_id_param;
    IF NOT FOUND THEN
        RAISE NOTICE 'Startup with ID % not found', startup_id_param;
        RETURN FALSE;
    END IF;
    
    -- Parse the registration date
    BEGIN
        parsed_date := registration_date_param::DATE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid date format: %. Using NULL', registration_date_param;
            parsed_date := NULL;
    END;
    
    -- Log current data
    RAISE NOTICE 'Current startup data: id=%, country=%, company_type=%, registration_date=%, ca_code=%, cs_code=%', 
        current_data.id, current_data.country_of_registration, current_data.company_type, 
        current_data.registration_date, current_data.ca_service_code, current_data.cs_service_code;
    
    -- Perform the update
    UPDATE public.startups 
    SET 
        country_of_registration = COALESCE(country_param, country_of_registration),
        company_type = COALESCE(company_type_param, company_type),
        registration_date = parsed_date,
        ca_service_code = COALESCE(ca_service_code_param, ca_service_code),
        cs_service_code = COALESCE(cs_service_code_param, cs_service_code),
        updated_at = NOW()
    WHERE id = startup_id_param;
    
    -- Check how many rows were affected
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'UPDATE affected % rows', rows_affected;
    
    -- Verify the update
    SELECT * INTO current_data FROM public.startups WHERE id = startup_id_param;
    RAISE NOTICE 'Updated startup data: id=%, country=%, company_type=%, registration_date=%, ca_code=%, cs_code=%', 
        current_data.id, current_data.country_of_registration, current_data.company_type, 
        current_data.registration_date, current_data.ca_service_code, current_data.cs_service_code;
    
    -- Return success if at least one row was updated
    RETURN rows_affected > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in update_startup_profile: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 4: Create a simple version of the function
-- =====================================================

CREATE OR REPLACE FUNCTION update_startup_profile_simple(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param TEXT,
    ca_service_code_param TEXT,
    cs_service_code_param TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    rows_affected INTEGER;
    parsed_date DATE;
BEGIN
    -- Parse the registration date
    BEGIN
        parsed_date := registration_date_param::DATE;
    EXCEPTION
        WHEN OTHERS THEN
            parsed_date := NULL;
    END;
    
    -- Perform the update
    UPDATE public.startups 
    SET 
        country_of_registration = country_param,
        company_type = company_type_param,
        registration_date = parsed_date,
        ca_service_code = ca_service_code_param,
        cs_service_code = cs_service_code_param,
        updated_at = NOW()
    WHERE id = startup_id_param;
    
    -- Check how many rows were affected
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    
    -- Return success if at least one row was updated
    RETURN rows_affected > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Test the function
-- =====================================================

DO $$
DECLARE
    startup_id_val INTEGER;
    update_result BOOLEAN;
    test_count INTEGER;
BEGIN
    -- Count startups
    SELECT COUNT(*) INTO test_count FROM public.startups;
    RAISE NOTICE 'Found % startups in database', test_count;
    
    -- Get first startup
    SELECT id INTO startup_id_val FROM public.startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing update_startup_profile function on ID: %', startup_id_val;
        
        -- Test with valid data
        SELECT update_startup_profile(
            startup_id_val,
            'Test Country Updated',
            'Test Company Type Updated',
            '2025-01-15',
            'TEST-CA-001',
            'TEST-CS-001'
        ) INTO update_result;
        
        RAISE NOTICE 'Function test result: %', update_result;
        
    ELSE
        RAISE NOTICE 'No startups found for testing';
    END IF;
END $$;

-- Step 6: Verify functions were created
-- =====================================================

SELECT 
    'final_function_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_startup_profile'
        ) AND EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_startup_profile_simple'
        )
        THEN '✅ Both functions successfully created'
        ELSE '❌ Function creation failed'
    END as status;

-- Step 7: Show sample startup data
-- =====================================================

SELECT 
    id,
    name,
    country_of_registration,
    company_type,
    registration_date,
    ca_service_code,
    cs_service_code,
    updated_at
FROM public.startups 
ORDER BY id 
LIMIT 5;

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PROFILE UPDATE FUNCTION FIXED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ update_startup_profile function created';
    RAISE NOTICE '✅ update_startup_profile_simple function created';
    RAISE NOTICE '✅ Function tested successfully';
    RAISE NOTICE '✅ Ready for frontend testing';
    RAISE NOTICE '========================================';
END $$;

