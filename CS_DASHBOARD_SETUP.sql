-- CS Dashboard Setup - Missing RPC Functions
-- This script adds the missing RPC functions needed for CS dashboard to work like CA dashboard

-- Function to assign CS to a startup
CREATE OR REPLACE FUNCTION assign_cs_to_startup(
  cs_code_param VARCHAR,
  startup_id_param BIGINT,
  notes_param TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  -- Check if CS is already assigned to this startup
  IF EXISTS (
    SELECT 1 FROM cs_assignments 
    WHERE cs_code = cs_code_param 
    AND startup_id = startup_id_param 
    AND status = 'active'
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
  SET status = 'inactive', 
      removal_date = NOW()
  WHERE cs_code = cs_code_param 
    AND startup_id = startup_id_param 
    AND status = 'active';

  RETURN FOUND;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION assign_cs_to_startup(VARCHAR, BIGINT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_cs_assignment(VARCHAR, BIGINT) TO authenticated;

-- Verify functions exist
SELECT 
  'assign_cs_to_startup' as function_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.proname = 'assign_cs_to_startup'
  ) THEN 'EXISTS' ELSE 'MISSING' END as status
UNION ALL
SELECT 
  'remove_cs_assignment' as function_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM pg_proc p 
    JOIN pg_namespace n ON p.pronamespace = n.oid 
    WHERE n.nspname = 'public' AND p.proname = 'remove_cs_assignment'
  ) THEN 'EXISTS' ELSE 'MISSING' END as status;
