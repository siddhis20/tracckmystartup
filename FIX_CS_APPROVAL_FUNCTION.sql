-- Fix CS Approval Function with Correct Column Names
-- This script updates the approval function to use the actual column names

-- Drop the existing function
DROP FUNCTION IF EXISTS approve_cs_assignment_request(BIGINT, VARCHAR, TEXT);

-- Recreate approve function with correct column names
CREATE OR REPLACE FUNCTION approve_cs_assignment_request(
  request_id_param BIGINT,
  cs_code_param VARCHAR,
  response_notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  -- Update the assignment request status
  UPDATE cs_assignment_requests 
  SET status = 'approved',
      updated_at = NOW(),
      response_notes = response_notes_param
  WHERE id = request_id_param 
    AND cs_code = cs_code_param
    AND status = 'pending';

  -- If request was updated, create an active assignment
  IF FOUND THEN
    INSERT INTO cs_assignments (cs_code, startup_id, status, notes, created_at)
    SELECT cs_code, startup_id, 'active', response_notes_param, NOW()
    FROM cs_assignment_requests
    WHERE id = request_id_param;
    
    RETURN TRUE;
  END IF;

  RETURN FALSE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error in approve_cs_assignment_request: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop the existing reject function
DROP FUNCTION IF EXISTS reject_cs_assignment_request(BIGINT, VARCHAR, TEXT);

-- Recreate reject function with correct column names
CREATE OR REPLACE FUNCTION reject_cs_assignment_request(
  request_id_param BIGINT,
  cs_code_param VARCHAR,
  response_notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  -- Update the assignment request status
  UPDATE cs_assignment_requests 
  SET status = 'rejected',
      updated_at = NOW(),
      response_notes = response_notes_param
  WHERE id = request_id_param 
    AND cs_code = cs_code_param
    AND status = 'pending';

  RETURN FOUND;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error in reject_cs_assignment_request: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION approve_cs_assignment_request(BIGINT, VARCHAR, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_cs_assignment_request(BIGINT, VARCHAR, TEXT) TO authenticated;

-- Test the function
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
  ELSE
    RAISE NOTICE 'No pending requests found to test with';
  END IF;
END $$;
