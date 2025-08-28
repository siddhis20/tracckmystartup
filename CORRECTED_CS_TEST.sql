-- Corrected CS Test - Check actual table structure first
-- This will work with whatever columns actually exist

-- 1. First, let's see what columns cs_assignment_requests actually has
SELECT 
  'cs_assignment_requests actual columns' as info,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- 2. Let's see what CS users we have
SELECT 
  'Available CS Users' as info,
  id,
  email,
  role,
  name
FROM public.users 
WHERE role = 'CS';

-- 3. Let's see what startups we have
SELECT 
  'Available Startups' as info,
  id,
  startup_name,
  user_id
FROM startups 
LIMIT 5;

-- 4. Now let's test with the correct column names
-- (We'll see what columns exist first, then use them)
SELECT 
  'Testing create_cs_assignment_request' as info,
  'Note: Check column names above first' as instruction;

