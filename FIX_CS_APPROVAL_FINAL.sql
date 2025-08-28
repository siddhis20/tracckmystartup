-- Fix CS Approval Function - Final Version
-- This script creates a robust approval function with proper debugging

-- Drop existing functions
DROP FUNCTION IF EXISTS approve_cs_assignment_request(BIGINT, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS reject_cs_assignment_request(BIGINT, VARCHAR, TEXT);

-- Create robust approve function with debugging
CREATE OR REPLACE FUNCTION approve_cs_assignment_request(
  request_id_param BIGINT,
  cs_code_param VARCHAR,
  response_notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  request_exists BOOLEAN;
  update_count INTEGER;
BEGIN
  -- Debug: Check if request exists
  SELECT EXISTS(
    SELECT 1 FROM cs_assignment_requests 
    WHERE id = request_id_param 
      AND cs_code = cs_code_param 
      AND status = 'pending'
  ) INTO request_exists;
  
  RAISE NOTICE 'Request exists check: %', request_exists;
  
  IF NOT request_exists THEN
    RAISE NOTICE 'Request not found or not pending for CS code: %', cs_code_param;
    RETURN FALSE;
  END IF;

  -- Update the assignment request status
  UPDATE cs_assignment_requests 
  SET status = 'approved',
      response_notes = response_notes_param
  WHERE id = request_id_param 
    AND cs_code = cs_code_param
    AND status = 'pending';
    
  GET DIAGNOSTICS update_count = ROW_COUNT;
  RAISE NOTICE 'Rows updated: %', update_count;

  -- If request was updated, create an active assignment
  IF update_count > 0 THEN
    RAISE NOTICE 'Creating assignment for request ID: %', request_id_param;
    
    INSERT INTO cs_assignments (cs_code, startup_id, status, notes)
    SELECT cs_code, startup_id, 'active', response_notes_param
    FROM cs_assignment_requests
    WHERE id = request_id_param;
    
    RAISE NOTICE 'Assignment created successfully';
    RETURN TRUE;
  END IF;

  RETURN FALSE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error in approve_cs_assignment_request: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create robust reject function
CREATE OR REPLACE FUNCTION reject_cs_assignment_request(
  request_id_param BIGINT,
  cs_code_param VARCHAR,
  response_notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  update_count INTEGER;
BEGIN
  -- Update the assignment request status
  UPDATE cs_assignment_requests 
  SET status = 'rejected',
      response_notes = response_notes_param
  WHERE id = request_id_param 
    AND cs_code = cs_code_param
    AND status = 'pending';
    
  GET DIAGNOSTICS update_count = ROW_COUNT;
  RAISE NOTICE 'Reject rows updated: %', update_count;

  RETURN update_count > 0;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error in reject_cs_assignment_request: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION approve_cs_assignment_request(BIGINT, VARCHAR, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_cs_assignment_request(BIGINT, VARCHAR, TEXT) TO authenticated;

-- Test the function with detailed output
DO $$
DECLARE
  test_request_id BIGINT;
  test_cs_code VARCHAR;
  result BOOLEAN;
BEGIN
  RAISE NOTICE '=== Testing CS Approval Function ===';
  
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
