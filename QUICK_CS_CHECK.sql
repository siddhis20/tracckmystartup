-- Quick CS Check - See actual table structures
-- This will show us what we're working with

-- 1. Check if cs_assignment_requests table exists and its structure
SELECT 
  'cs_assignment_requests exists' as info,
  EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'cs_assignment_requests'
  ) as table_exists;

-- 2. If table exists, show its actual columns
SELECT 
  'cs_assignment_requests columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- 3. Check if cs_assignments table exists and its structure
SELECT 
  'cs_assignments exists' as info,
  EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'cs_assignments'
  ) as table_exists;

-- 4. If table exists, show its actual columns
SELECT 
  'cs_assignments columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cs_assignments'
ORDER BY ordinal_position;

-- 5. Check public.users table for cs_code column
SELECT 
  'public.users cs_code column' as info,
  EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'users' 
      AND column_name = 'cs_code'
  ) as cs_code_exists;

-- 6. Show all columns in public.users
SELECT 
  'public.users all columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 7. Check if there are any CS users
SELECT 
  'CS Users count' as info,
  COUNT(*) as total_cs_users
FROM public.users 
WHERE role = 'CS';

-- 8. Show sample CS user data
SELECT 
  'Sample CS User' as info,
  id,
  email,
  role,
  name
FROM public.users 
WHERE role = 'CS'
LIMIT 1;

-- 9. Check if cs_assignment_requests has any data
SELECT 
  'cs_assignment_requests data count' as info,
  COUNT(*) as total_records
FROM cs_assignment_requests;

-- 10. Check if cs_assignments has any data
SELECT 
  'cs_assignments data count' as info,
  COUNT(*) as total_records
FROM cs_assignments;

