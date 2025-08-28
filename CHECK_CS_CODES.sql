-- Check what CS codes actually exist in users table
-- This will show us what we can use for testing

-- 1. Check if users table has cs_code column
SELECT 
  'users table cs_code column' as info,
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'cs_code'
    ) THEN 'EXISTS'
    ELSE 'MISSING'
  END as cs_code_status;

-- 2. Show all columns in users table
SELECT 
  'users table all columns' as info,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 3. Show CS users and their codes (if cs_code column exists)
SELECT 
  'CS Users with codes' as info,
  id,
  email,
  role,
  name,
  cs_code
FROM public.users 
WHERE role = 'CS';

-- 4. Show all users with their codes (if cs_code column exists)
SELECT 
  'All users with codes' as info,
  id,
  email,
  role,
  name,
  cs_code
FROM public.users 
ORDER BY role, name;

-- 5. Check if there are any CS codes at all
SELECT 
  'CS codes count' as info,
  COUNT(*) as total_cs_codes
FROM public.users 
WHERE role = 'CS' 
  AND cs_code IS NOT NULL;

