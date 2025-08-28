-- Step by Step CS Check
-- Run each section separately to see what exists

-- SECTION 1: Check if tables exist
SELECT 
  'Table Check' as info,
  'cs_assignment_requests' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'cs_assignment_requests') as exists
UNION ALL
SELECT 
  'Table Check' as info,
  'cs_assignments' as table_name,
  EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'cs_assignments') as exists;

-- SECTION 2: Check public.users table structure
SELECT 
  'public.users columns' as info,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- SECTION 3: Check if cs_code column exists in public.users
SELECT 
  'cs_code column check' as info,
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'cs_code'
    ) THEN 'EXISTS'
    ELSE 'MISSING'
  END as cs_code_status;

-- SECTION 4: Count CS users
SELECT 
  'CS Users' as info,
  COUNT(*) as total_cs_users
FROM public.users 
WHERE role = 'CS';

-- SECTION 5: Show CS user sample
SELECT 
  'CS User Sample' as info,
  id,
  email,
  role,
  name
FROM public.users 
WHERE role = 'CS'
LIMIT 1;

-- SECTION 6: Check cs_assignment_requests structure (if table exists)
SELECT 
  'cs_assignment_requests columns' as info,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- SECTION 7: Check cs_assignments structure (if table exists)
SELECT 
  'cs_assignments columns' as info,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_name = 'cs_assignments'
ORDER BY ordinal_position;

