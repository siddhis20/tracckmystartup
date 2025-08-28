-- =====================================================
-- TEST INCUBATION PROGRAMS BACKEND SETUP
-- =====================================================
-- This script tests the incubation programs functionality

-- Check if the table exists
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'incubation_programs'
ORDER BY ordinal_position;

-- Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'incubation_programs';

-- Check RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'incubation_programs'
ORDER BY cmd;

-- Check if functions exist
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%incubation%'
ORDER BY routine_name;

-- Test the get_incubation_programs function
-- Replace 1 with an actual startup_id from your database
SELECT * FROM get_incubation_programs(1);

-- Check current data
SELECT COUNT(*) as total_programs FROM incubation_programs;

-- Show sample data if any exists
SELECT * FROM incubation_programs LIMIT 5;
