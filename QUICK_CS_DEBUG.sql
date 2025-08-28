-- Quick CS Debug - Check Current State
-- Run this to see what's actually in the database

-- 1. Check if there are any CS assignment requests at all
SELECT 'All CS Assignment Requests' as check_type, COUNT(*) as count FROM cs_assignment_requests;

-- 2. Check pending requests specifically
SELECT 'Pending Requests' as check_type, COUNT(*) as count FROM cs_assignment_requests WHERE status = 'pending';

-- 3. Show all requests with details
SELECT 
  id,
  cs_code,
  startup_id,
  status,
  notes,
  created_at
FROM cs_assignment_requests 
ORDER BY created_at DESC;

-- 4. Check the actual table structure
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- 5. Check if the CS user exists and has the right code
SELECT 
  id,
  email,
  role,
  cs_code
FROM auth.users 
WHERE email = 'network@startupnationindia.com';

-- 6. Test the function manually with actual data
DO $$
DECLARE
  test_request_id BIGINT;
  test_cs_code VARCHAR;
  result BOOLEAN;
BEGIN
  -- Get the first pending request
  SELECT id, cs_code INTO test_request_id, test_cs_code
  FROM cs_assignment_requests 
  WHERE status = 'pending' 
  LIMIT 1;
  
  IF test_request_id IS NOT NULL THEN
    RAISE NOTICE 'Found request ID: %, CS code: %', test_request_id, test_cs_code;
    
    -- Test the approval function
    SELECT approve_cs_assignment_request(test_request_id, test_cs_code, 'Test approval') INTO result;
    
    RAISE NOTICE 'Approval result: %', result;
    
    -- Check if it worked
    IF EXISTS (SELECT 1 FROM cs_assignment_requests WHERE id = test_request_id AND status = 'approved') THEN
      RAISE NOTICE '✅ Request was approved!';
    ELSE
      RAISE NOTICE '❌ Request was NOT approved';
    END IF;
    
  ELSE
    RAISE NOTICE '❌ No pending requests found!';
  END IF;
END $$;
