-- Check facilitator_startups table structure
-- Run this in your Supabase SQL editor

-- Check if table exists
SELECT '=== CHECKING TABLE EXISTENCE ===' as info;
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'facilitator_startups'
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
AND table_name = 'facilitator_startups'
ORDER BY ordinal_position;

-- Check if there are any records
SELECT '=== CHECKING EXISTING DATA ===' as info;
SELECT COUNT(*) as total_records FROM facilitator_startups;

-- Show sample data if any exists
SELECT '=== SAMPLE DATA ===' as info;
SELECT * FROM facilitator_startups LIMIT 5;

-- Check foreign key constraints
SELECT '=== FOREIGN KEY CONSTRAINTS ===' as info;
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'facilitator_startups';
