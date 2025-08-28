-- =====================================================
-- DIAGNOSE PROFILE UPDATE ISSUE
-- =====================================================
-- This script helps identify why profile updates are failing
-- =====================================================

-- Step 1: Check if functions exist and their signatures
-- =====================================================

SELECT 
    'function_existence_check' as check_type,
    routine_name,
    routine_type,
    data_type as return_type,
    CASE 
        WHEN routine_name = 'update_startup_profile' THEN '✅ Exists'
        WHEN routine_name = 'update_startup_profile_simple' THEN '✅ Exists'
        ELSE '❌ Missing'
    END as status
FROM information_schema.routines 
WHERE routine_name IN ('update_startup_profile', 'update_startup_profile_simple')
AND routine_schema = 'public';

-- Step 2: Check function parameters
-- =====================================================

SELECT 
    'function_parameters' as check_type,
    p.specific_name as routine_name,
    p.parameter_name,
    p.data_type,
    p.parameter_mode,
    p.ordinal_position
FROM information_schema.parameters p
WHERE p.specific_name IN ('update_startup_profile', 'update_startup_profile_simple')
AND p.specific_schema = 'public'
ORDER BY p.specific_name, p.ordinal_position;

-- Step 3: Check startups table structure
-- =====================================================

SELECT 
    'startups_table_structure' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 4: Check sample startup data
-- =====================================================

SELECT 
    'sample_startup_data' as check_type,
    id,
    name,
    user_id,
    country_of_registration,
    company_type,
    registration_date,
    ca_service_code,
    cs_service_code,
    updated_at
FROM public.startups 
ORDER BY id 
LIMIT 3;

-- Step 5: Test function with detailed logging
-- =====================================================

DO $$
DECLARE
    startup_id_val INTEGER;
    update_result BOOLEAN;
    test_count INTEGER;
    current_data RECORD;
BEGIN
    -- Count startups
    SELECT COUNT(*) INTO test_count FROM public.startups;
    RAISE NOTICE 'Found % startups in database', test_count;
    
    -- Get first startup with detailed info
    SELECT * INTO current_data FROM public.startups ORDER BY id LIMIT 1;
    
    IF current_data.id IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup: ID=%, Name=%, User_ID=%, Country=%, Company_Type=%', 
            current_data.id, current_data.name, current_data.user_id, 
            current_data.country_of_registration, current_data.company_type;
        
        -- Test the simple function first
        RAISE NOTICE 'Testing update_startup_profile_simple...';
        SELECT update_startup_profile_simple(
            current_data.id,
            'Diagnostic Test Country',
            'Diagnostic Test Type',
            '2025-01-25',
            'DIAG-CA-001',
            'DIAG-CS-001'
        ) INTO update_result;
        
        RAISE NOTICE 'Simple function result: %', update_result;
        
        -- Test the full function
        RAISE NOTICE 'Testing update_startup_profile...';
        SELECT update_startup_profile(
            current_data.id,
            'Diagnostic Test Country 2',
            'Diagnostic Test Type 2',
            '2025-01-26',
            'DIAG-CA-002',
            'DIAG-CS-002'
        ) INTO update_result;
        
        RAISE NOTICE 'Full function result: %', update_result;
        
        -- Check the updated data
        SELECT * INTO current_data FROM public.startups WHERE id = current_data.id;
        RAISE NOTICE 'Updated startup data: Country=%, Company_Type=%, CA_Code=%, CS_Code=%', 
            current_data.country_of_registration, current_data.company_type,
            current_data.ca_service_code, current_data.cs_service_code;
        
    ELSE
        RAISE NOTICE 'No startups found for testing';
    END IF;
END $$;

-- Step 6: Check RLS policies
-- =====================================================

SELECT 
    'rls_policies_check' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'startups'
ORDER BY policyname;

-- Step 7: Check function permissions
-- =====================================================

SELECT 
    'function_permissions_check' as check_type,
    routine_name,
    routine_schema,
    security_type,
    CASE 
        WHEN security_type = 'SECURITY DEFINER' THEN '✅ SECURITY DEFINER'
        ELSE '⚠️ SECURITY INVOKER'
    END as security_status
FROM information_schema.routines 
WHERE routine_name IN ('update_startup_profile', 'update_startup_profile_simple')
AND routine_schema = 'public'
ORDER BY routine_name;

-- Step 8: Test direct table update
-- =====================================================

DO $$
DECLARE
    startup_id_val INTEGER;
    rows_affected INTEGER;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM public.startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing direct table update on startup ID: %', startup_id_val;
        
        -- Try direct update
        UPDATE public.startups 
        SET 
            country_of_registration = 'Direct Test Country',
            company_type = 'Direct Test Type',
            updated_at = NOW()
        WHERE id = startup_id_val;
        
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Direct update affected % rows', rows_affected;
        
        IF rows_affected > 0 THEN
            RAISE NOTICE '✅ Direct table update works!';
        ELSE
            RAISE NOTICE '❌ Direct table update failed!';
        END IF;
        
    ELSE
        RAISE NOTICE 'No startups found for direct update test';
    END IF;
END $$;

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PROFILE UPDATE DIAGNOSTIC COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Check the results above to identify the issue.';
    RAISE NOTICE 'Common issues:';
    RAISE NOTICE '- Function signature mismatch';
    RAISE NOTICE '- Permission issues';
    RAISE NOTICE '- RLS policy conflicts';
    RAISE NOTICE '- Data type mismatches';
    RAISE NOTICE '========================================';
END $$;
