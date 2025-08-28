-- Test the connection between startup recognition requests and facilitator dashboard
-- Run this in your Supabase SQL editor to see what's happening

-- Check if there are any recognition records in the database
SELECT '=== CHECKING RECOGNITION RECORDS ===' as info;
SELECT COUNT(*) as total_records FROM recognition_records;

-- Show all recognition records
SELECT '=== ALL RECOGNITION RECORDS ===' as info;
SELECT 
    id,
    startup_id,
    program_name,
    facilitator_name,
    facilitator_code,
    status,
    date_added
FROM recognition_records
ORDER BY date_added DESC;

-- Check if there are any facilitators with codes
SELECT '=== CHECKING FACILITATORS ===' as info;
SELECT 
    id,
    name,
    facilitator_code,
    role
FROM users 
WHERE role = 'Startup Facilitation Center'
AND facilitator_code IS NOT NULL;

-- Test the exact query that the facilitator dashboard uses
SELECT '=== TESTING FACILITATOR DASHBOARD QUERY ===' as info;
-- Replace 'FAC-0EFCD9' with an actual facilitator code from above
SELECT 
    r.id,
    r.startup_id,
    r.program_name,
    r.facilitator_name,
    r.facilitator_code,
    r.status,
    r.date_added,
    s.name as startup_name,
    s.sector as startup_sector
FROM recognition_records r
LEFT JOIN startups s ON r.startup_id = s.id
WHERE r.facilitator_code = 'FAC-0EFCD9'  -- Replace with actual facilitator code
ORDER BY r.date_added DESC;

-- Check if there are any pending recognition requests
SELECT '=== PENDING RECOGNITION REQUESTS ===' as info;
SELECT 
    r.id,
    r.startup_id,
    r.program_name,
    r.facilitator_code,
    r.status,
    s.name as startup_name
FROM recognition_records r
LEFT JOIN startups s ON r.startup_id = s.id
WHERE r.status = 'pending'
ORDER BY r.date_added DESC;
