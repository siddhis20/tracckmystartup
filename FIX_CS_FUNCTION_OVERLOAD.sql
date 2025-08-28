-- Fix CS Function Overload Issue
-- This script drops the conflicting functions and recreates them with consistent parameter names

-- Drop existing conflicting functions
DROP FUNCTION IF EXISTS approve_cs_assignment_request(bigint, character varying, text);
DROP FUNCTION IF EXISTS approve_cs_assignment_request(integer, character varying, text);
DROP FUNCTION IF EXISTS reject_cs_assignment_request(bigint, character varying, text);
DROP FUNCTION IF EXISTS reject_cs_assignment_request(integer, character varying, text);

-- Recreate approve function with consistent parameters
CREATE OR REPLACE FUNCTION approve_cs_assignment_request(
  request_id_param BIGINT,
  cs_code_param VARCHAR,
  response_notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  -- Update the assignment request status
  UPDATE cs_assignment_requests 
  SET status = 'approved',
      response_date = NOW(),
      response_notes = response_notes_param
  WHERE id = request_id_param 
    AND cs_code = cs_code_param
    AND status = 'pending';

  -- If request was updated, create an active assignment
  IF FOUND THEN
    INSERT INTO cs_assignments (cs_code, startup_id, status, notes, assignment_date)
    SELECT cs_code, startup_id, 'active', response_notes_param, NOW()
    FROM cs_assignment_requests
    WHERE id = request_id_param;
    
    RETURN TRUE;
  END IF;

  RETURN FALSE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate reject function with consistent parameters
CREATE OR REPLACE FUNCTION reject_cs_assignment_request(
  request_id_param BIGINT,
  cs_code_param VARCHAR,
  response_notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  -- Update the assignment request status
  UPDATE cs_assignment_requests 
  SET status = 'rejected',
      response_date = NOW(),
      response_notes = response_notes_param
  WHERE id = request_id_param 
    AND cs_code = cs_code_param
    AND status = 'pending';

  RETURN FOUND;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION approve_cs_assignment_request(BIGINT, VARCHAR, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION reject_cs_assignment_request(BIGINT, VARCHAR, TEXT) TO authenticated;

-- Verify functions are created correctly
SELECT 
  'approve_cs_assignment_request' as function_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.proname = 'approve_cs_assignment_request'
  ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
SELECT 
  'reject_cs_assignment_request' as function_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.proname = 'reject_cs_assignment_request'
  ) THEN 'EXISTS' ELSE 'MISSING' END as status;
