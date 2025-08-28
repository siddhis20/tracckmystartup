-- Simple CS Check - See what actually exists
-- This script checks what tables and columns actually exist without assumptions

-- 1. List all tables in the database
SELECT 
  'All Tables' as info,
  schemaname,
  tablename
FROM pg_tables 
WHERE schemaname IN ('public', 'auth')
ORDER BY schemaname, tablename;

-- 2. Find CS-related tables
SELECT 
  'CS Related Tables' as info,
  schemaname,
  tablename
FROM pg_tables 
WHERE schemaname IN ('public', 'auth')
  AND (tablename LIKE '%cs%' OR tablename LIKE '%assignment%' OR tablename LIKE '%request%')
ORDER BY schemaname, tablename;

-- 3. Check cs_assignment_requests table structure (if it exists)
SELECT 
  'cs_assignment_requests columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- 4. Check cs_assignments table structure (if it exists)
SELECT 
  'cs_assignments columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cs_assignments'
ORDER BY ordinal_position;

-- 5. Check public.users table structure
SELECT 
  'public.users columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 6. Check auth.users table structure
SELECT 
  'auth.users columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 7. Count records in cs_assignment_requests (if table exists)
SELECT 
  'cs_assignment_requests count' as info,
  COUNT(*) as total_records
FROM cs_assignment_requests;

-- 8. Count records in cs_assignments (if table exists)
SELECT 
  'cs_assignments count' as info,
  COUNT(*) as total_records
FROM cs_assignments;

-- 9. Show CS users from public.users
SELECT 
  'CS Users from public.users' as info,
  id,
  email,
  role,
  name
FROM public.users 
WHERE role = 'CS'
LIMIT 5;

-- 10. Show CS users from auth.users
SELECT 
  'CS Users from auth.users' as info,
  id,
  email,
  role
FROM auth.users 
WHERE role = 'CS'
LIMIT 5;

-- 11. List CS-related functions
SELECT 
  'CS Functions' as info,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND (p.proname LIKE '%cs%' OR p.proname LIKE '%assignment%')
ORDER BY p.proname;

