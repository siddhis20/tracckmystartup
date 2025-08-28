-- Test CS Assignment Request Creation
-- Using the actual data from the logs

-- 1. Check the startup data
SELECT 
  'Startup Data' as info,
  id,
  name,
  user_id
FROM startups 
WHERE name = 'Mulsetu Agrotech';

-- 2. Check the CS user data
SELECT 
  'CS User Data' as info,
  id,
  email,
  name,
  role,
  cs_code
FROM users 
WHERE cs_code = 'CS-841854';

-- 3. Test the assignment request creation manually
SELECT 
  'Testing CS Assignment Request' as info,
  create_cs_assignment_request(
    11,  -- startup_id_param (Mulsetu Agrotech)
    'Mulsetu Agrotech',  -- startup_name_param
    'CS-841854',  -- cs_code_param (Radha Sharma)
    'Assignment request from Mulsetu Agrotech'  -- notes_param
  ) as result;

-- 4. Check if the request was created
SELECT 
  'Check Created Request' as info,
  COUNT(*) as total_requests
FROM cs_assignment_requests;

-- 5. Show the created request details
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
