-- Debug CS Approval Issue
-- This script helps identify why the approval is failing

-- 1. Check if there are any pending CS assignment requests
SELECT 
  'Pending CS Assignment Requests' as check_type,
  COUNT(*) as count
FROM cs_assignment_requests 
WHERE status = 'pending';

-- 2. Show details of pending requests (using correct column names)
SELECT 
  id,
  cs_code,
  startup_id,
  status,
  created_at,
  notes
FROM cs_assignment_requests 
WHERE status = 'pending'
ORDER BY created_at DESC;

-- 3. Check if the CS user has a valid CS code
SELECT 
  'CS User Check' as check_type,
  u.id,
  u.email,
  u.cs_code,
  u.role
FROM auth.users u
WHERE u.role = 'CS'
LIMIT 5;

-- 4. Test the approve function manually (replace with actual values)
-- First, get a sample request ID and CS code
SELECT 
  'Sample Request for Testing' as test_info,
  car.id as request_id,
  car.cs_code,
  car.startup_id,
  car.status
FROM cs_assignment_requests car
WHERE car.status = 'pending'
LIMIT 1;

-- 5. Check if cs_assignments table exists and has correct structure
SELECT 
  'CS Assignments Table Structure' as check_type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cs_assignments'
ORDER BY ordinal_position;

-- 6. Check if cs_assignment_requests table exists and has correct structure
SELECT 
  'CS Assignment Requests Table Structure' as check_type,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'cs_assignment_requests'
ORDER BY ordinal_position;

-- 7. Check RLS policies on cs_assignment_requests
SELECT 
  'RLS Policies on cs_assignment_requests' as check_type,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'cs_assignment_requests';

-- 8. Check RLS policies on cs_assignments
SELECT 
  'RLS Policies on cs_assignments' as check_type,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'cs_assignments';
