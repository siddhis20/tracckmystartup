-- Check CS Table Structure
-- This script shows the actual column names in the CS tables

-- Check cs_assignment_requests table structure
SELECT 
  'cs_assignment_requests' as table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- Check cs_assignments table structure
SELECT 
  'cs_assignments' as table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'cs_assignments'
ORDER BY ordinal_position;

-- Show sample data from cs_assignment_requests
SELECT 
  'Sample cs_assignment_requests data' as info,
  COUNT(*) as total_records,
  COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_records,
  COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_records,
  COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_records
FROM cs_assignment_requests;

-- Show sample data from cs_assignments
SELECT 
  'Sample cs_assignments data' as info,
  COUNT(*) as total_records,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_records,
  COUNT(CASE WHEN status = 'inactive' THEN 1 END) as inactive_records
FROM cs_assignments;
