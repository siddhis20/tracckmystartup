-- Test with Real CS Code
-- This will use the actual CS code that exists in your database

-- 1. First, let's see what CS code we have
SELECT 
  'Available CS Code' as info,
  cs_code
FROM public.users 
WHERE role = 'CS' 
  AND cs_code IS NOT NULL
LIMIT 1;

-- 2. Now test the assignment request with the real CS code
-- (Replace 'CS-XXXXXX' with the actual code from step 1)
SELECT 
  'Testing with real CS code' as info,
  create_cs_assignment_request(
    12,  -- startup_id_param (using the actual startup ID from your data)
    'munmun',  -- startup_name_param (using the actual name from your data)
    (SELECT cs_code FROM public.users WHERE role = 'CS' AND cs_code IS NOT NULL LIMIT 1),  -- cs_code_param (using the real CS code)
    'Please assign me to this startup'  -- request_message_param
  ) as result;

-- 3. Check if the request was created
SELECT 
  'Check if request was created' as info,
  COUNT(*) as total_requests
FROM cs_assignment_requests;

-- 4. Show the created request
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

