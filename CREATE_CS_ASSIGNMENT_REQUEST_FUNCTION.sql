-- Create the missing CS assignment request function
-- This function will create a CS assignment request in the cs_assignment_requests table

CREATE OR REPLACE FUNCTION create_cs_assignment_request(
  startup_id_param BIGINT,
  startup_name_param TEXT,
  cs_code_param TEXT,
  notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  cs_user_exists BOOLEAN;
BEGIN
  -- Check if the CS code exists in the users table
  SELECT EXISTS(
    SELECT 1 FROM public.users 
    WHERE cs_code = cs_code_param 
    AND role = 'CS'
  ) INTO cs_user_exists;
  
  -- If CS user doesn't exist, return false
  IF NOT cs_user_exists THEN
    RAISE EXCEPTION 'CS code % does not exist or is not assigned to a CS user', cs_code_param;
  END IF;
  
  -- Check if a request already exists for this startup and CS
  IF EXISTS(
    SELECT 1 FROM cs_assignment_requests 
    WHERE startup_id = startup_id_param 
    AND cs_code = cs_code_param
    AND status IN ('pending', 'approved')
  ) THEN
    RAISE EXCEPTION 'A request already exists for startup % and CS %', startup_id_param, cs_code_param;
  END IF;
  
  -- Insert the assignment request
  INSERT INTO cs_assignment_requests (
    startup_id,
    startup_name,
    cs_code,
    status,
    request_message,
    created_at
  ) VALUES (
    startup_id_param,
    startup_name_param,
    cs_code_param,
    'pending',
    COALESCE(notes_param, 'Assignment request from startup'),
    NOW()
  );
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_cs_assignment_request TO authenticated;

-- Test the function
SELECT 'Function created successfully' as status;
