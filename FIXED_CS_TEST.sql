-- Fixed CS Test - Using correct column names from startups table
-- Now we know: startups.name (not startup_name) and startups.cs_service_code

-- 1. Show available CS users
SELECT 
  'Available CS Users' as info,
  id,
  email,
  role,
  name
FROM public.users 
WHERE role = 'CS';

-- 2. Show available startups with correct column names
SELECT 
  'Available Startups' as info,
  id,
  name,  -- This is the correct column name
  user_id,
  cs_service_code  -- This is where CS codes are stored
FROM startups 
LIMIT 5;

-- 3. Test create_cs_assignment_request function
-- Using the correct column names we now know exist:
-- startup_id, startup_name (from startups.name), cs_code, request_message
SELECT 
  'Testing create_cs_assignment_request' as info,
  create_cs_assignment_request(
    12,  -- startup_id_param (using the actual startup ID from your data)
    'munmun',  -- startup_name_param (using the actual name from your data)
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

