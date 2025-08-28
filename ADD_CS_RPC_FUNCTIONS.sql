-- Add missing CS RPC functions to match CA functionality

-- Function to assign CS to startup
CREATE OR REPLACE FUNCTION assign_cs_to_startup(
  cs_code_param VARCHAR,
  startup_id_param BIGINT,
  notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  -- Check if assignment already exists
  IF EXISTS (
    SELECT 1 FROM cs_assignments 
    WHERE cs_code = cs_code_param AND startup_id = startup_id_param
  ) THEN
    RETURN FALSE;
  END IF;

  -- Create new assignment
  INSERT INTO cs_assignments (cs_code, startup_id, status, notes, assignment_date)
  VALUES (cs_code_param, startup_id_param, 'active', notes_param, NOW());

  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove CS assignment
CREATE OR REPLACE FUNCTION remove_cs_assignment(
  cs_code_param VARCHAR,
  startup_id_param BIGINT
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE cs_assignments 
  SET status = 'inactive', updated_at = NOW()
  WHERE cs_code = cs_code_param AND startup_id = startup_id_param;
  
  RETURN FOUND;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION assign_cs_to_startup(VARCHAR, BIGINT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_cs_assignment(VARCHAR, BIGINT) TO authenticated;
