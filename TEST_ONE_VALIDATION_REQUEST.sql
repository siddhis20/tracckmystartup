-- TEST_ONE_VALIDATION_REQUEST.sql
-- Test script to verify one validation request per startup

-- 1. Check current validation requests
SELECT 
    'Current validation requests' as check_type,
    COUNT(*) as total_requests,
    COUNT(DISTINCT startup_id) as unique_startups
FROM validation_requests;

-- 2. Check for any startups with multiple validation requests
SELECT 
    startup_id,
    startup_name,
    COUNT(*) as request_count
FROM validation_requests
GROUP BY startup_id, startup_name
HAVING COUNT(*) > 1
ORDER BY request_count DESC;

-- 3. Show all validation requests with details
SELECT 
    id,
    startup_id,
    startup_name,
    status,
    admin_notes,
    created_at,
    updated_at
FROM validation_requests
ORDER BY startup_id, created_at DESC;

-- 4. Check fundraising details with validation status
SELECT 
    fd.id,
    fd.startup_id,
    fd.validation_requested,
    fd.active,
    s.name as startup_name,
    vr.status as validation_status
FROM fundraising_details fd
JOIN startups s ON fd.startup_id = s.id
LEFT JOIN validation_requests vr ON fd.startup_id = vr.startup_id
WHERE fd.validation_requested = true
ORDER BY fd.created_at DESC;

-- 5. Clean up duplicate validation requests (if any exist)
-- This will keep only the most recent validation request per startup
WITH ranked_requests AS (
    SELECT 
        id,
        startup_id,
        startup_name,
        status,
        admin_notes,
        created_at,
        updated_at,
        ROW_NUMBER() OVER (PARTITION BY startup_id ORDER BY created_at DESC) as rn
    FROM validation_requests
)
DELETE FROM validation_requests 
WHERE id IN (
    SELECT id FROM ranked_requests WHERE rn > 1
);

-- 6. Verify cleanup (should show 0 duplicates)
SELECT 
    'After cleanup - validation requests' as check_type,
    COUNT(*) as total_requests,
    COUNT(DISTINCT startup_id) as unique_startups
FROM validation_requests;

-- 7. Test creating a validation request (uncomment to test)
-- INSERT INTO validation_requests (startup_id, startup_name, status)
-- VALUES (11, 'Test Startup', 'pending')
-- ON CONFLICT (startup_id) DO UPDATE SET
--     startup_name = EXCLUDED.startup_name,
--     status = EXCLUDED.status,
--     admin_notes = NULL,
--     updated_at = NOW();
