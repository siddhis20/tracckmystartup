-- =====================================================
-- VERIFY COMPLIANCE SETUP
-- =====================================================
-- Run this to check if everything was set up correctly
-- =====================================================

-- Check if tables exist
SELECT 
    'compliance_checks' as table_name,
    EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'compliance_checks'
    ) as exists
UNION ALL
SELECT 
    'compliance_uploads' as table_name,
    EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'compliance_uploads'
    ) as exists;

-- Check if storage bucket exists
SELECT 
    'compliance-documents' as bucket_name,
    EXISTS (
        SELECT 1 FROM storage.buckets 
        WHERE id = 'compliance-documents'
    ) as exists;

-- Check if functions exist
SELECT 
    'create_compliance_tasks' as function_name,
    EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name = 'create_compliance_tasks'
    ) as exists
UNION ALL
SELECT 
    'update_subsidiary_compliance_tasks' as function_name,
    EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name = 'update_subsidiary_compliance_tasks'
    ) as exists;

-- Check if triggers exist
SELECT 
    'trigger_create_compliance_tasks' as trigger_name,
    EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_schema = 'public' 
        AND trigger_name = 'trigger_create_compliance_tasks'
    ) as exists
UNION ALL
SELECT 
    'trigger_update_subsidiary_compliance_tasks' as trigger_name,
    EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_schema = 'public' 
        AND trigger_name = 'trigger_update_subsidiary_compliance_tasks'
    ) as exists;

-- Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('compliance_checks', 'compliance_uploads')
ORDER BY tablename, policyname;

-- Test query to compliance_checks table
SELECT 
    'compliance_checks_query_test' as test_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.compliance_checks LIMIT 1
        ) THEN 'SUCCESS - Table is accessible'
        ELSE 'SUCCESS - Table exists but is empty'
    END as result;

-- Test query to compliance_uploads table
SELECT 
    'compliance_uploads_query_test' as test_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.compliance_uploads LIMIT 1
        ) THEN 'SUCCESS - Table is accessible'
        ELSE 'SUCCESS - Table exists but is empty'
    END as result;

-- Summary
DO $$
DECLARE
    tables_exist BOOLEAN;
    bucket_exists BOOLEAN;
    functions_exist BOOLEAN;
    triggers_exist BOOLEAN;
BEGIN
    -- Check tables
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('compliance_checks', 'compliance_uploads')
    ) INTO tables_exist;
    
    -- Check bucket
    SELECT EXISTS (
        SELECT 1 FROM storage.buckets 
        WHERE id = 'compliance-documents'
    ) INTO bucket_exists;
    
    -- Check functions
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name IN ('create_compliance_tasks', 'update_subsidiary_compliance_tasks')
    ) INTO functions_exist;
    
    -- Check triggers
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_schema = 'public' 
        AND trigger_name IN ('trigger_create_compliance_tasks', 'trigger_update_subsidiary_compliance_tasks')
    ) INTO triggers_exist;
    
    -- Report results
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COMPLIANCE SETUP VERIFICATION RESULTS';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables: %', CASE WHEN tables_exist THEN '✅ EXIST' ELSE '❌ MISSING' END;
    RAISE NOTICE 'Storage Bucket: %', CASE WHEN bucket_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
    RAISE NOTICE 'Functions: %', CASE WHEN functions_exist THEN '✅ EXIST' ELSE '❌ MISSING' END;
    RAISE NOTICE 'Triggers: %', CASE WHEN triggers_exist THEN '✅ EXIST' ELSE '❌ MISSING' END;
    RAISE NOTICE '========================================';
    
    IF tables_exist AND bucket_exists AND functions_exist AND triggers_exist THEN
        RAISE NOTICE '🎉 ALL COMPONENTS ARE SET UP CORRECTLY!';
        RAISE NOTICE 'You can now refresh your application and test the compliance system.';
    ELSE
        RAISE NOTICE '⚠️ Some components are missing. Please check the results above.';
    END IF;
END $$;

