-- Check for conflicts in users table that might cause 409 errors
SELECT 'Checking users table structure:' as info;
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check for duplicate entries or conflicts
SELECT 'Checking for potential conflicts in users table:' as info;
SELECT 
  email,
  COUNT(*) as count,
  array_agg(id) as user_ids
FROM users 
GROUP BY email 
HAVING COUNT(*) > 1;

-- Check the specific user that's causing issues
SELECT 'Checking user with CS code CS-841854:' as info;
SELECT 
  id,
  email,
  role,
  cs_code,
  ca_code,
  created_at,
  updated_at
FROM users 
WHERE cs_code = 'CS-841854' 
   OR email = 'network@startupnationindia.com';

-- Check for any constraint violations
SELECT 'Checking for any unique constraint violations:' as info;
SELECT 
  'cs_code' as constraint_type,
  cs_code,
  COUNT(*) as count
FROM users 
WHERE cs_code IS NOT NULL
GROUP BY cs_code 
HAVING COUNT(*) > 1

UNION ALL

SELECT 
  'ca_code' as constraint_type,
  ca_code,
  COUNT(*) as count
FROM users 
WHERE ca_code IS NOT NULL
GROUP BY ca_code 
HAVING COUNT(*) > 1;

-- Check RLS policies on users table
SELECT 'Checking RLS policies on users table:' as info;
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';
