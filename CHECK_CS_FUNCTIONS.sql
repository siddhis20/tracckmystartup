-- Check existing CS functions to see what's already there
SELECT 
  'Existing Functions' as info,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname LIKE '%cs_assignment%'
ORDER BY p.proname;

-- Drop all existing CS assignment request functions to avoid conflicts
DROP FUNCTION IF EXISTS create_cs_assignment_request(BIGINT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_cs_assignment_request(BIGINT, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_cs_assignment_request(TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS create_cs_assignment_request(TEXT, TEXT, TEXT);

-- Show what functions remain
SELECT 
  'Remaining Functions' as info,
  p.proname as function_name,
  pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
  AND p.proname LIKE '%cs_assignment%'
ORDER BY p.proname;
