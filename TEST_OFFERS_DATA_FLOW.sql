-- Test script to verify the offers data flow from facilitator to startup
-- This will help debug why offers are not appearing in the startup dashboard

-- 1. Check if opportunity_applications table exists and has data
SELECT '1. Checking opportunity_applications table:' as test_step;
SELECT 
    COUNT(*) as total_applications,
    COUNT(DISTINCT startup_id) as unique_startups,
    COUNT(DISTINCT opportunity_id) as unique_opportunities,
    COUNT(CASE WHEN status = 'accepted' THEN 1 END) as accepted_applications,
    COUNT(CASE WHEN diligence_status = 'requested' THEN 1 END) as diligence_requested,
    COUNT(CASE WHEN diligence_status = 'approved' THEN 1 END) as diligence_approved
FROM opportunity_applications;

-- 2. Show sample applications with all details
SELECT '2. Sample applications with details:' as test_step;
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

-- 3. Check if there are any applications for specific startups
SELECT '3. Applications by startup:' as test_step;
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    COUNT(oa.id) as total_applications,
    COUNT(CASE WHEN oa.status = 'accepted' THEN 1 END) as accepted_applications,
    COUNT(CASE WHEN oa.diligence_status = 'requested' THEN 1 END) as diligence_requested,
    COUNT(CASE WHEN oa.diligence_status = 'approved' THEN 1 END) as diligence_approved
FROM startups s
LEFT JOIN opportunity_applications oa ON s.id = oa.startup_id
GROUP BY s.id, s.name
ORDER BY total_applications DESC;

-- 4. Check if the required columns exist
SELECT '4. Checking table structure:' as test_step;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications'
ORDER BY ordinal_position;

-- 5. Test the exact query that the frontend uses
SELECT '5. Testing frontend query structure:' as test_step;
-- This simulates what the frontend is trying to fetch
SELECT 
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    oa.agreement_url,
    oa.created_at,
    io.id as opportunity_id_inner,
    io.program_name,
    io.facilitator_id
FROM opportunity_applications oa
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
WHERE oa.startup_id = 1  -- Replace with actual startup ID
LIMIT 5;

-- 6. Check RLS policies for opportunity_applications
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
WHERE tablename = 'opportunity_applications'
ORDER BY policyname;

-- 7. Test if current user can access the data
SELECT '7. Testing current user access:' as test_step;
SELECT 
    'Current user can read opportunity_applications' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM opportunity_applications LIMIT 1
        ) THEN '✅ Can access'
        ELSE '❌ Cannot access'
    END as result;

-- Summary
SELECT 'DATA FLOW TEST COMPLETE' as summary;
SELECT 
    'If you see data in step 2, the backend is working correctly.' as status,
    'If step 2 shows no data, the facilitator needs to create applications first.' as action;
