-- Test script to debug recognition data flow
-- This will help us understand why recognition records are not showing up

-- 1. Check if recognition_records table exists and has data
SELECT '=== RECOGNITION RECORDS TABLE ===' as info;
SELECT 
    id,
    startup_id,
    program_name,
    facilitator_code,
    status,
    created_at,
    date_added
FROM public.recognition_records 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. Check if users table has facilitator codes
SELECT '=== USERS WITH FACILITATOR CODES ===' as info;
SELECT 
    id,
    email,
    role,
    facilitator_code,
    created_at
FROM public.users 
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at DESC;

-- 3. Check if startups table has data
SELECT '=== STARTUPS TABLE ===' as info;
SELECT 
    id,
    name,
    sector,
    user_id,
    created_at
FROM public.startups 
ORDER BY created_at DESC 
LIMIT 10;

-- 4. Test the join query that should work
SELECT '=== TEST JOIN QUERY ===' as info;
SELECT 
    rr.id,
    rr.program_name,
    rr.facilitator_code,
    rr.status,
    s.name as startup_name,
    s.sector as startup_sector
FROM public.recognition_records rr
JOIN public.startups s ON rr.startup_id = s.id
ORDER BY rr.created_at DESC 
LIMIT 5;

-- 5. Check if there are any recognition records with specific facilitator codes
SELECT '=== RECOGNITION RECORDS BY FACILITATOR CODE ===' as info;
SELECT 
    facilitator_code,
    COUNT(*) as record_count,
    MIN(created_at) as earliest_record,
    MAX(created_at) as latest_record
FROM public.recognition_records 
GROUP BY facilitator_code
ORDER BY record_count DESC;

-- 6. Check if the status column was added correctly
SELECT '=== STATUS COLUMN CHECK ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'recognition_records' 
AND column_name = 'status';
