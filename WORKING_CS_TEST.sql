-- Working CS Test - Using correct column names
-- Now that we know the table structures, let's test properly

-- 1. Show available CS users
SELECT 
  'Available CS Users' as info,
  id,
  email,
  role,
  name
FROM public.users 
WHERE role = 'CS';

-- 2. Show available startups (using correct column names)
SELECT 
  'Available Startups' as info,
  id,
  user_id
FROM startups 
LIMIT 5;

-- 3. Test create_cs_assignment_request function
-- Using the correct column names we know exist:
-- startup_id, startup_name, cs_code, request_message
SELECT 
  'Testing create_cs_assignment_request' as info,
  create_cs_assignment_request(
    1,  -- startup_id_param (replace with actual startup ID)
    'Test Startup Name',  -- startup_name_param
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

