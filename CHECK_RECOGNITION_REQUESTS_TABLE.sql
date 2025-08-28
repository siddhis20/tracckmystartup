-- Check if recognition_requests table exists and has correct structure
-- Run this in your Supabase SQL editor to diagnose the issue

-- Check if table exists
SELECT '=== CHECKING TABLE EXISTENCE ===' as info;
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'recognition_requests'
) as table_exists;

-- If table exists, show its structure
SELECT '=== TABLE STRUCTURE ===' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'recognition_requests'
ORDER BY ordinal_position;

-- Check if there are any facilitators in the users table
SELECT '=== CHECKING FACILITATORS ===' as info;
SELECT 
    id,
    name,
    facilitator_code,
    role
FROM users 
WHERE role = 'Startup Facilitation Center'
LIMIT 5;

-- Check if there are any startups
SELECT '=== CHECKING STARTUPS ===' as info;
SELECT 
    id,
    name,
    sector
FROM startups 
LIMIT 5;

-- Check if recognition_requests table has any data
SELECT '=== CHECKING EXISTING DATA ===' as info;
SELECT COUNT(*) as total_records FROM recognition_requests;

-- Show sample data if any exists
SELECT '=== SAMPLE DATA ===' as info;
SELECT * FROM recognition_requests LIMIT 3;
