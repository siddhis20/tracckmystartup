-- Test CS Assignment Request Creation
-- This will help us see what's happening

-- 1. First, let's see what CS users we have
SELECT 
  'Available CS Users' as info,
  id,
  email,
  role,
  name
FROM public.users 
WHERE role = 'CS';

-- 2. Let's see what startups we have
SELECT 
  'Available Startups' as info,
  id,
  startup_name,
  user_id
FROM startups 
LIMIT 5;

-- 3. Let's test the create_cs_assignment_request function manually
-- (Replace the values with actual IDs from your database)
SELECT 
  'Testing create_cs_assignment_request' as info,
  create_cs_assignment_request(
    1,  -- startup_id_param (replace with actual startup ID)
    'Test Startup',  -- startup_name_param
    'CS-TEST01',  -- cs_code_param (replace with actual CS code)
    'Please assign me to this startup'  -- request_message_param
  ) as result;

-- 4. Check if the request was created
SELECT 
  'Check if request was created' as info,
  COUNT(*) as total_requests
FROM cs_assignment_requests;

-- 5. Show the created request
SELECT 
  'Created Request Details' as info,
  id,
  startup_id,
  startup_name,
  cs_code,
  status,
  request_message,
  created_at
FROM cs_assignment_requests 
ORDER BY created_at DESC 
LIMIT 1;

