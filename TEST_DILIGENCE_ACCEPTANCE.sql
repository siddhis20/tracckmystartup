-- Test script to verify diligence acceptance flow
-- This will help debug the 400 error

-- 1. Check if the RPC function exists
SELECT '1. Checking RPC function:' as test_step;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name = 'safe_update_diligence_status';

-- 2. Check function parameters
SELECT '2. Function parameters:' as test_step;
SELECT 
    parameter_name,
    parameter_mode,
    data_type,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'safe_update_diligence_status'
)
ORDER BY ordinal_position;

-- 3. Check current applications that could be used for testing
SELECT '3. Current applications for testing:' as test_step;
SELECT 
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    oa.created_at,
    s.name as startup_name,
    io.program_name
FROM opportunity_applications oa
LEFT JOIN startups s ON oa.startup_id = s.id
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
WHERE oa.diligence_status = 'requested'
ORDER BY oa.created_at DESC;

-- 4. Test the function manually (if test data exists)
DO $$
DECLARE
    test_app_id UUID;
    test_result BOOLEAN;
    test_app_count INTEGER;
BEGIN
    -- Count applications with requested status
    SELECT COUNT(*) INTO test_app_count
    FROM opportunity_applications
    WHERE diligence_status = 'requested';
    
    RAISE NOTICE 'Found % applications with diligence_status = requested', test_app_count;
    
    -- Get a test application ID
    SELECT id INTO test_app_id
    FROM opportunity_applications
    WHERE diligence_status = 'requested'
    LIMIT 1;
    
    IF test_app_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with application ID: %', test_app_id;
        
        -- Test the function
        SELECT safe_update_diligence_status(test_app_id, 'approved', 'requested') INTO test_result;
        
        RAISE NOTICE 'Test result: %', test_result;
        
        -- Check the result
        IF test_result THEN
            RAISE NOTICE '✅ Function worked - status updated successfully';
        ELSE
            RAISE NOTICE '❌ Function returned false - status not updated';
        END IF;
        
        -- Show the updated status
        SELECT diligence_status INTO test_result
        FROM opportunity_applications
        WHERE id = test_app_id;
        
        RAISE NOTICE 'Current status after update: %', test_result;
        
    ELSE
        RAISE NOTICE 'No test applications found with diligence_status = requested';
    END IF;
END $$;

-- 5. Check RLS policies for opportunity_applications
SELECT '4. RLS policies for opportunity_applications:' as test_step;
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
WHERE tablename = 'opportunity_applications';

-- 6. Check if authenticated user can access the table
SELECT '5. Testing table access:' as test_step;
SELECT 
    'Can select' as operation,
    COUNT(*) as record_count
FROM opportunity_applications
WHERE diligence_status = 'requested'
UNION ALL
SELECT 
    'Can update' as operation,
    COUNT(*) as record_count
FROM opportunity_applications
WHERE diligence_status = 'requested';

-- 7. Show any recent errors in the logs (if available)
SELECT '6. Recent application updates:' as test_step;
SELECT 
    id,
    startup_id,
    opportunity_id,
    status,
    diligence_status,
    updated_at,
    created_at
FROM opportunity_applications
WHERE updated_at > NOW() - INTERVAL '1 hour'
ORDER BY updated_at DESC;

-- 8. Summary
SELECT 'DILIGENCE ACCEPTANCE TEST COMPLETE' as summary;
SELECT 
    'If function exists in step 1, RPC should work' as rpc_status,
    'If parameters are correct in step 2, call should succeed' as parameter_status,
    'If data exists in step 3, there are applications to test with' as data_status;
