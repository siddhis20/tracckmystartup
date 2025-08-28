-- Debug CS Request Creation Issue
-- This script helps identify why CS assignment requests are not being created

-- 1. Check if the create_cs_assignment_request function exists and its signature
SELECT 
  'Function Check' as check_type,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'create_cs_assignment_request';

-- 2. Check if cs_assignment_requests table exists and has correct structure
SELECT 
  'Table Structure' as check_type,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- 3. Check if there are any existing requests
SELECT 
  'Existing Requests' as check_type,
  COUNT(*) as total_requests,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests
FROM cs_assignment_requests;

-- 4. Check if the CS user exists with the correct code
SELECT 
  'CS User Check' as check_type,
  id,
  email,
  role,
  cs_code
FROM auth.users 
WHERE email = 'network@startupnationindia.com';

-- 5. Check if there are any startups that might have requested CS
SELECT 
  'Startup Check' as check_type,
  id,
  name,
  user_id,
  cs_service_code
FROM startups 
WHERE cs_service_code IS NOT NULL;

-- 6. Test the create_cs_assignment_request function manually
DO $$
DECLARE
  test_startup_id BIGINT;
  test_cs_code VARCHAR;
  result BOOLEAN;
BEGIN
  RAISE NOTICE '=== Testing CS Request Creation ===';
  
  -- Get a startup ID
  SELECT id INTO test_startup_id FROM startups LIMIT 1;
  
  -- Get the CS code
  SELECT cs_code INTO test_cs_code FROM auth.users WHERE email = 'network@startupnationindia.com';
  
  IF test_startup_id IS NOT NULL AND test_cs_code IS NOT NULL THEN
    RAISE NOTICE 'Testing with startup ID: %, CS code: %', test_startup_id, test_cs_code;
    
    -- Test the function
    SELECT create_cs_assignment_request(test_startup_id, 'Test Startup', test_cs_code, 'Test request') INTO result;
    
    RAISE NOTICE 'Request creation result: %', result;
    
    -- Check if request was created
    IF EXISTS (SELECT 1 FROM cs_assignment_requests WHERE startup_id = test_startup_id AND cs_code = test_cs_code) THEN
      RAISE NOTICE '✅ Request successfully created!';
    ELSE
      RAISE NOTICE '❌ Request was not created';
    END IF;
    
  ELSE
    RAISE NOTICE '❌ Missing startup ID or CS code for testing';
  END IF;
  
  RAISE NOTICE '=== Test Complete ===';
END $$;

-- 7. Check RLS policies on cs_assignment_requests
SELECT 
  'RLS Policies' as check_type,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'cs_assignment_requests';
