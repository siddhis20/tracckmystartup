-- Fix CS approval function and add missing remove function
-- First, let's check what's in the cs_assignment_requests table
SELECT 'Current CS Assignment Requests:' as info;
SELECT * FROM cs_assignment_requests WHERE cs_code = 'CS-841854' ORDER BY id DESC;

-- Drop and recreate the approval function with better error handling
DROP FUNCTION IF EXISTS approve_cs_assignment_request(bigint, varchar, text);
DROP FUNCTION IF EXISTS approve_cs_assignment_request(bigint, varchar);

CREATE OR REPLACE FUNCTION approve_cs_assignment_request(
  request_id_param bigint,
  cs_code_param varchar,
  response_notes_param text DEFAULT NULL
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  req RECORD;
  assignment_exists boolean;
BEGIN
  -- Debug: Log the parameters
  RAISE NOTICE 'Approving request ID: %, CS Code: %', request_id_param, cs_code_param;
  
  -- Lock and fetch the request
  SELECT *
  INTO req
  FROM cs_assignment_requests
  WHERE id = request_id_param
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE NOTICE 'Request not found: %', request_id_param;
    RETURN FALSE;
  END IF;

  -- Check CS code match
  IF TRIM(req.cs_code) <> TRIM(cs_code_param) THEN
    RAISE NOTICE 'CS code mismatch: expected %, got %', cs_code_param, req.cs_code;
    RETURN FALSE;
  END IF;

  -- Check status
  IF req.status <> 'pending' THEN
    RAISE NOTICE 'Request not pending: %', req.status;
    RETURN FALSE;
  END IF;

  -- Update request status
  UPDATE cs_assignment_requests
  SET status = 'approved',
      response_notes = response_notes_param
  WHERE id = req.id;

  -- Check if assignment already exists
  SELECT EXISTS(
    SELECT 1 FROM cs_assignments
    WHERE startup_id = req.startup_id
      AND cs_code = cs_code_param
  ) INTO assignment_exists;

  -- Create or update assignment
  IF assignment_exists THEN
    UPDATE cs_assignments
    SET status = 'active'
    WHERE startup_id = req.startup_id
      AND cs_code = cs_code_param;
    RAISE NOTICE 'Updated existing assignment';
  ELSE
    INSERT INTO cs_assignments (startup_id, cs_code, status)
    VALUES (req.startup_id, cs_code_param, 'active');
    RAISE NOTICE 'Created new assignment';
  END IF;

  RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error in approval: %', SQLERRM;
  RETURN FALSE;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION approve_cs_assignment_request(bigint, varchar, text) TO authenticated;

-- Create the missing remove_cs_assignment function
CREATE OR REPLACE FUNCTION remove_cs_assignment(
  cs_code_param varchar,
  startup_id_param bigint
) RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update assignment status to inactive
  UPDATE cs_assignments
  SET status = 'inactive'
  WHERE cs_code = cs_code_param
    AND startup_id = startup_id_param;

  -- Return true if any rows were affected
  RETURN FOUND;
EXCEPTION WHEN OTHERS THEN
  RETURN FALSE;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION remove_cs_assignment(varchar, bigint) TO authenticated;

-- Test the approval function with the actual request
SELECT 'Testing approval function:' as info;
SELECT approve_cs_assignment_request(5, 'CS-841854', 'Approved via CS') AS approved;

-- Verify the results
SELECT 'Assignment requests after approval:' as info;
SELECT * FROM cs_assignment_requests WHERE cs_code = 'CS-841854' ORDER BY id DESC;

SELECT 'CS assignments after approval:' as info;
SELECT * FROM cs_assignments WHERE cs_code = 'CS-841854' ORDER BY startup_id DESC;

SELECT 'Test get_cs_startups function:' as info;
SELECT * FROM get_cs_startups('CS-841854');
