-- Check CS Assignment Requests Status
-- This script shows the current state of all CS-related data

-- 1. Check all CS assignment requests
SELECT 
  'All CS Assignment Requests' as check_type,
  COUNT(*) as total_count,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count,
  COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_count,
  COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_count
FROM cs_assignment_requests;

-- 2. Show detailed pending requests
SELECT 
  'Pending Requests Details' as check_type,
  id,
  cs_code,
  startup_id,
  status,
  notes,
  created_at
FROM cs_assignment_requests 
WHERE status = 'pending'
ORDER BY created_at DESC;

-- 3. Check CS assignments table
SELECT 
  'CS Assignments' as check_type,
  COUNT(*) as total_assignments,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_assignments,
  COUNT(CASE WHEN status = 'inactive' THEN 1 END) as inactive_assignments
FROM cs_assignments;

-- 4. Show all assignments
SELECT 
  'All Assignments Details' as check_type,
  cs_code,
  startup_id,
  status,
  notes,
  created_at
FROM cs_assignments 
ORDER BY created_at DESC;

-- 5. Check if the specific CS user exists
SELECT 
  'CS User Check' as check_type,
  id,
  email,
  role,
  cs_code
FROM auth.users 
WHERE email = 'network@startupnationindia.com';

-- 6. Check startup that might have requested CS
SELECT 
  'Startup with CS Code' as check_type,
  id,
  name,
  cs_service_code,
  ca_service_code
FROM startups 
WHERE cs_service_code IS NOT NULL;

-- 7. Test the approval function with actual data
DO $$
DECLARE
  test_request_id BIGINT;
  test_cs_code VARCHAR;
  result BOOLEAN;
BEGIN
  RAISE NOTICE '=== Testing CS Approval with Real Data ===';
  
  -- Get the first pending request
  SELECT id, cs_code INTO test_request_id, test_cs_code
  FROM cs_assignment_requests 
  WHERE status = 'pending' 
  LIMIT 1;
  
  IF test_request_id IS NOT NULL THEN
    RAISE NOTICE 'Found pending request: ID=%, CS Code=%', test_request_id, test_cs_code;
    
    -- Test the approval function
    SELECT approve_cs_assignment_request(test_request_id, test_cs_code, 'Test approval from script') INTO result;
    
    RAISE NOTICE 'Approval result: %', result;
    
    -- Check final state
    IF EXISTS (SELECT 1 FROM cs_assignment_requests WHERE id = test_request_id AND status = 'approved') THEN
      RAISE NOTICE '✅ Request successfully approved!';
    ELSE
      RAISE NOTICE '❌ Request was not approved';
    END IF;
    
    IF EXISTS (SELECT 1 FROM cs_assignments WHERE cs_code = test_cs_code AND startup_id = (SELECT startup_id FROM cs_assignment_requests WHERE id = test_request_id)) THEN
      RAISE NOTICE '✅ Assignment successfully created!';
    ELSE
      RAISE NOTICE '❌ Assignment was not created';
    END IF;
    
  ELSE
    RAISE NOTICE '❌ No pending requests found to test with';
  END IF;
  
  RAISE NOTICE '=== Test Complete ===';
END $$;
