-- Test CS Approval Function Step by Step
-- This script tests the approval process manually

-- Step 1: Check current state of assignment requests
SELECT 'Current Assignment Requests' as step, COUNT(*) as count FROM cs_assignment_requests;

-- Step 2: Check pending requests
SELECT 'Pending Requests' as step, COUNT(*) as count FROM cs_assignment_requests WHERE status = 'pending';

-- Step 3: Get a sample pending request to test with
WITH sample_request AS (
  SELECT id, cs_code, startup_id, status 
  FROM cs_assignment_requests 
  WHERE status = 'pending' 
  LIMIT 1
)
SELECT 
  'Sample Request for Testing' as step,
  id as request_id,
  cs_code,
  startup_id,
  status
FROM sample_request;

-- Step 4: Test the approval function manually (replace X with actual request ID)
-- First, let's see what happens when we try to approve a request
DO $$
DECLARE
  test_request_id BIGINT;
  test_cs_code VARCHAR;
  result BOOLEAN;
BEGIN
  -- Get a sample request
  SELECT id, cs_code INTO test_request_id, test_cs_code
  FROM cs_assignment_requests 
  WHERE status = 'pending' 
  LIMIT 1;
  
  IF test_request_id IS NOT NULL THEN
    RAISE NOTICE 'Testing approval for request ID: %, CS code: %', test_request_id, test_cs_code;
    
    -- Test the approval function
    SELECT approve_cs_assignment_request(test_request_id, test_cs_code, 'Test approval') INTO result;
    
    RAISE NOTICE 'Approval result: %', result;
    
    -- Check if the request was updated
    IF EXISTS (SELECT 1 FROM cs_assignment_requests WHERE id = test_request_id AND status = 'approved') THEN
      RAISE NOTICE '✅ Request successfully approved!';
    ELSE
      RAISE NOTICE '❌ Request was not approved';
    END IF;
    
    -- Check if assignment was created
    IF EXISTS (SELECT 1 FROM cs_assignments WHERE cs_code = test_cs_code AND startup_id = (SELECT startup_id FROM cs_assignment_requests WHERE id = test_request_id)) THEN
      RAISE NOTICE '✅ Assignment successfully created!';
    ELSE
      RAISE NOTICE '❌ Assignment was not created';
    END IF;
    
  ELSE
    RAISE NOTICE '❌ No pending requests found to test with';
  END IF;
END $$;

-- Step 5: Check the results after testing
SELECT 
  'Results After Test' as step,
  COUNT(*) as total_requests,
  SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_requests,
  SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) as approved_requests,
  SUM(CASE WHEN status = 'rejected' THEN 1 ELSE 0 END) as rejected_requests
FROM cs_assignment_requests;

-- Step 6: Check assignments table
SELECT 
  'Assignments After Test' as step,
  COUNT(*) as total_assignments,
  SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_assignments,
  SUM(CASE WHEN status = 'inactive' THEN 1 ELSE 0 END) as inactive_assignments
FROM cs_assignments;
