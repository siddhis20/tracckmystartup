-- TEST_VALIDATION_REQUESTS.sql
-- Test script to check validation requests

-- 1. Check if validation_requests table exists and has data
SELECT 
    'validation_requests table exists' as check_type,
    COUNT(*) as count
FROM information_schema.tables 
WHERE table_name = 'validation_requests';

-- 2. Check all validation requests
SELECT 
    id,
    startup_id,
    startup_name,
    status,
    created_at,
    updated_at
FROM validation_requests
ORDER BY created_at DESC;

-- 3. Check startups with validation status
SELECT 
    id,
    name,
    startup_nation_validated,
    validation_date
FROM startups
WHERE startup_nation_validated IS NOT NULL
ORDER BY id;

-- 4. Check fundraising details with validation requested
SELECT 
    fd.id,
    fd.startup_id,
    fd.validation_requested,
    fd.active,
    s.name as startup_name
FROM fundraising_details fd
JOIN startups s ON fd.startup_id = s.id
WHERE fd.validation_requested = true
ORDER BY fd.created_at DESC;

-- 5. Test creating a validation request manually (uncomment to test)
-- INSERT INTO validation_requests (startup_id, startup_name, status)
-- VALUES (11, 'Test Startup', 'pending')
-- ON CONFLICT DO NOTHING;

-- 6. Check RLS policies on validation_requests
SELECT 
    policyname,
    cmd AS command,
    roles,
    qual AS "using",
    with_check
FROM pg_policies
WHERE tablename = 'validation_requests';
