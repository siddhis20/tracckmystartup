-- Check Existing CS Tables and Structure
-- This script finds all existing tables and their structure

-- 1. List all tables in the database
SELECT 
  'All Tables' as info,
  schemaname,
  tablename
FROM pg_tables 
WHERE schemaname IN ('public', 'auth')
ORDER BY schemaname, tablename;

-- 2. Find tables that might be CS-related
SELECT 
  'CS Related Tables' as info,
  schemaname,
  tablename
FROM pg_tables 
WHERE schemaname IN ('public', 'auth')
  AND (tablename LIKE '%cs%' OR tablename LIKE '%assignment%' OR tablename LIKE '%request%')
ORDER BY schemaname, tablename;

-- 3. Check if cs_assignment_requests table exists and its structure
SELECT 
  'cs_assignment_requests structure' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- 4. Check if cs_assignments table exists and its structure
SELECT 
  'cs_assignments structure' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'cs_assignments'
ORDER BY ordinal_position;

-- 5. Check auth.users table structure (what columns actually exist)
SELECT 
  'auth.users structure' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'auth' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 6. Check if there are any existing CS assignment requests
SELECT 
  'Existing CS Assignment Requests' as info,
  COUNT(*) as total_requests,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests,
  COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_requests,
  COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_requests
FROM cs_assignment_requests;

-- 7. Check if there are any existing CS assignments
SELECT 
  'Existing CS Assignments' as info,
  COUNT(*) as total_assignments,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_assignments,
  COUNT(CASE WHEN status = 'inactive' THEN 1 END) as inactive_assignments
FROM cs_assignments;

-- 8. Show sample data from cs_assignment_requests (if any)
SELECT 
  'Sample CS Assignment Requests' as info,
  id,
  startup_id,
  startup_name,
  cs_code,
  status,
  notes,
  created_at
FROM cs_assignment_requests 
LIMIT 5;

-- 9. Show sample data from cs_assignments (if any)
SELECT 
  'Sample CS Assignments' as info,
  id,
  cs_code,
  startup_id,
  status,
  notes,
  created_at
FROM cs_assignments 
LIMIT 5;

-- 10. Check what CS-related functions exist
SELECT 
  'CS Functions' as info,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND (p.proname LIKE '%cs%' OR p.proname LIKE '%assignment%')
ORDER BY p.proname;

