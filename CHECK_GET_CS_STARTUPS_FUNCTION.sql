-- Check the get_cs_startups function definition
SELECT 'Function definition for get_cs_startups:' as info;
SELECT 
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname = 'get_cs_startups';

-- Check what the function actually returns
SELECT 'Raw get_cs_startups output:' as info;
SELECT * FROM get_cs_startups('CS-841854');

-- Check if the function should filter by status
SELECT 'Direct query to cs_assignments table:' as info;
SELECT 
  startup_id,
  cs_code,
  status,
  created_at,
  updated_at
FROM cs_assignments 
WHERE cs_code = 'CS-841854';

-- Check if we need to update the function to only return active assignments
SELECT 'Testing with status filter:' as info;
SELECT 
  startup_id,
  cs_code,
  status
FROM cs_assignments 
WHERE cs_code = 'CS-841854' 
  AND status = 'active';

-- If the function is returning inactive assignments, we need to fix it
-- Here's the corrected function:
CREATE OR REPLACE FUNCTION get_cs_startups(cs_code_param varchar)
RETURNS TABLE (
  startup_id bigint,
  startup_name text,
  assignment_date timestamp with time zone,
  status varchar,
  notes text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ca.startup_id,
    s.name as startup_name,
    ca.created_at as assignment_date,
    ca.status,
    ca.notes
  FROM cs_assignments ca
  LEFT JOIN startups s ON ca.startup_id = s.id
  WHERE ca.cs_code = cs_code_param
    AND ca.status = 'active'  -- Only return active assignments
  ORDER BY ca.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_cs_startups(varchar) TO authenticated;

-- Test the updated function
SELECT 'Updated get_cs_startups output:' as info;
SELECT * FROM get_cs_startups('CS-841854');
