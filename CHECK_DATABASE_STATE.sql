-- =====================================================
-- DATABASE STATE CHECK
-- =====================================================
-- Run this first to understand your current database state

-- Check if user_id column already exists
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'startups' AND column_name = 'user_id';

-- Check how many startups exist
SELECT COUNT(*) as total_startups FROM public.startups;

-- Check how many users exist
SELECT COUNT(*) as total_users FROM public.users;

-- Check user roles
SELECT role, COUNT(*) as count 
FROM public.users 
GROUP BY role 
ORDER BY count DESC;

-- Check if any startups exist
SELECT id, name, created_at FROM public.startups LIMIT 5;

-- Check if RLS is enabled on startups table
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'startups' 
AND schemaname = 'public';

-- Check existing policies on startups table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'startups' 
AND schemaname = 'public'
ORDER BY policyname;
