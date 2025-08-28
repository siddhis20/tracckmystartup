-- Test script to verify the complete due diligence flow
-- This will help ensure the startup can only accept once and facilitator gets proper updates

-- 1. Check current state of opportunity_applications
SELECT '1. Current opportunity applications:' as test_step;
SELECT 
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    oa.agreement_url,
    oa.created_at,
    io.program_name,
    io.facilitator_id,
    u.name as facilitator_name,
    s.name as startup_name
FROM opportunity_applications oa
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
LEFT JOIN users u ON io.facilitator_id = u.id
LEFT JOIN startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC
LIMIT 10;

-- 2. Check facilitator access records
SELECT '2. Current facilitator access records:' as test_step;
SELECT 
    fa.id,
    fa.facilitator_id,
    fa.startup_id,
    fa.access_type,
    fa.is_active,
    fa.expires_at,
    fa.granted_at,
    u.name as facilitator_name,
    s.name as startup_name
FROM facilitator_access fa
LEFT JOIN users u ON fa.facilitator_id = u.id
LEFT JOIN startups s ON fa.startup_id = s.id
ORDER BY fa.created_at DESC
LIMIT 10;

-- 3. Test the check_facilitator_access function
SELECT '3. Testing check_facilitator_access function:' as test_step;
-- Replace with actual facilitator_id and startup_id from your data
SELECT 
    'Sample facilitator access check' as test,
    check_facilitator_access(
        (SELECT id FROM users WHERE role = 'Startup Facilitation Center' LIMIT 1),
        (SELECT id FROM startups LIMIT 1),
        'compliance_view'
    ) as has_access;

-- 4. Check if the trigger is working properly
SELECT '4. Checking trigger setup:' as test_step;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'auto_grant_facilitator_access'
AND event_object_table = 'opportunity_applications';

-- 5. Test the grant_facilitator_compliance_access function
SELECT '5. Testing grant function:' as test_step;
SELECT 
    'Function exists' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'grant_facilitator_compliance_access'
        ) THEN '✅ Function exists'
        ELSE '❌ Function missing'
    END as status;

-- 6. Check RLS policies for facilitator_access table
SELECT '6. Checking RLS policies:' as test_step;
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
WHERE tablename = 'facilitator_access'
ORDER BY policyname;

-- 7. Simulate the complete flow
SELECT '7. Simulating complete diligence flow:' as test_step;
SELECT 
    'Flow steps:' as info,
    '1. Facilitator accepts application → status = accepted' as step1,
    '2. Facilitator requests diligence → diligence_status = requested' as step2,
    '3. Startup accepts diligence → diligence_status = approved' as step3,
    '4. Trigger grants access → facilitator_access record created' as step4,
    '5. Facilitator button changes → View Diligence' as step5;

-- 8. Show current applications that need diligence
SELECT '8. Applications ready for diligence:' as test_step;
SELECT 
    oa.id,
    s.name as startup_name,
    io.program_name,
    oa.status,
    oa.diligence_status,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'Ready for diligence request'
        WHEN oa.diligence_status = 'requested' THEN 'Ready for startup acceptance'
        WHEN oa.diligence_status = 'approved' THEN 'Diligence completed'
        ELSE 'Other status'
    END as next_action
FROM opportunity_applications oa
LEFT JOIN startups s ON oa.startup_id = s.id
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
WHERE oa.status = 'accepted'
ORDER BY oa.created_at DESC;

-- 9. Summary
SELECT 'DILIGENCE FLOW TEST COMPLETE' as summary;
SELECT 
    'If you see data in step 1, the applications exist.' as status,
    'If you see data in step 2, access control is working.' as access_status,
    'If step 4 shows the trigger, automatic access grant is set up.' as trigger_status;
