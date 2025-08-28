-- QUICK_RECOGNITION_TEST.sql
-- Quick test to verify recognition backend is working

-- 1. Check if table exists
SELECT '=== TABLE EXISTS ===' as info;
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'recognition_records'
) as table_exists;

-- 2. Check if there are any existing facilitator codes
SELECT '=== FACILITATOR CODES ===' as info;
SELECT 
    id,
    email,
    facilitator_code,
    role
FROM users 
WHERE role = 'Startup Facilitation Center' 
AND facilitator_code IS NOT NULL
LIMIT 3;

-- 3. Check if there are any existing startups
SELECT '=== STARTUPS ===' as info;
SELECT 
    id,
    name,
    sector
FROM startups 
LIMIT 3;

-- 4. Test inserting a recognition record (if startup exists)
SELECT '=== TEST INSERT ===' as info;

-- Find first available startup
WITH first_startup AS (
    SELECT id, name FROM startups LIMIT 1
)
SELECT 
    'Available startup for testing:' as info,
    id as startup_id,
    name as startup_name
FROM first_startup;

-- 5. Check RLS policies
SELECT '=== RLS POLICIES ===' as info;
SELECT 
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'recognition_records';

-- 6. Check table structure
SELECT '=== TABLE STRUCTURE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'recognition_records'
ORDER BY ordinal_position;
