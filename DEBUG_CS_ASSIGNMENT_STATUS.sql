-- Debug CS assignment status and approval issues
SELECT 'Current CS Assignment Status:' as info;
SELECT 
  startup_id,
  cs_code,
  status,
  created_at,
  updated_at
FROM cs_assignments 
WHERE cs_code = 'CS-841854' 
ORDER BY startup_id DESC;

SELECT 'Current CS Assignment Requests:' as info;
SELECT 
  id,
  startup_id,
  startup_name,
  cs_code,
  status
FROM cs_assignment_requests 
WHERE cs_code = 'CS-841854' 
ORDER BY id DESC;

SELECT 'RPC get_cs_startups result:' as info;
SELECT * FROM get_cs_startups('CS-841854');

-- Check if there are any pending requests that can be approved
SELECT 'Pending requests that can be approved:' as info;
SELECT 
  id,
  startup_id,
  startup_name,
  cs_code,
  status
FROM cs_assignment_requests 
WHERE cs_code = 'CS-841854' 
  AND status = 'pending'
ORDER BY id DESC;

-- Test the approval function manually
SELECT 'Testing approval function with latest pending request:' as info;
WITH latest_pending AS (
  SELECT id 
  FROM cs_assignment_requests 
  WHERE cs_code = 'CS-841854' 
    AND status = 'pending'
  ORDER BY id DESC 
  LIMIT 1
)
SELECT 
  'Latest pending request ID: ' || id as info
FROM latest_pending;

-- If there's a pending request, test approval
SELECT 'Manual approval test:' as info;
SELECT approve_cs_assignment_request(
  (SELECT id FROM cs_assignment_requests WHERE cs_code = 'CS-841854' AND status = 'pending' ORDER BY id DESC LIMIT 1),
  'CS-841854',
  'Approved via manual test'
) AS approval_result;

-- Check results after approval attempt
SELECT 'Assignment status after approval attempt:' as info;
SELECT 
  startup_id,
  cs_code,
  status
FROM cs_assignments 
WHERE cs_code = 'CS-841854' 
ORDER BY startup_id DESC;

SELECT 'Request status after approval attempt:' as info;
SELECT 
  id,
  startup_id,
  startup_name,
  cs_code,
  status
FROM cs_assignment_requests 
WHERE cs_code = 'CS-841854' 
ORDER BY id DESC;
