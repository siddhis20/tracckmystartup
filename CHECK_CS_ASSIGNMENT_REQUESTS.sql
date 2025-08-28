-- Check cs_assignment_requests table structure
-- This will show us what columns actually exist

SELECT 
  'cs_assignment_requests columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- Check if there are any existing requests
SELECT 
  'Existing requests count' as info,
  COUNT(*) as total_requests
FROM cs_assignment_requests;

-- Show sample data if any exists
SELECT 
  'Sample data' as info,
  *
FROM cs_assignment_requests 
LIMIT 1;

