-- Remove Conflicting Storage Policies
-- This script removes the old, restrictive policies that are blocking file uploads during registration

-- 1. Remove the old, conflicting policies
DROP POLICY IF EXISTS "verification-documents-delete 1lpbgjq_0" ON storage.objects;
DROP POLICY IF EXISTS "verification-documents-update 1lpbgjq_0" ON storage.objects;
DROP POLICY IF EXISTS "verification-documents-upload 1lpbgjq_0" ON storage.objects;
DROP POLICY IF EXISTS "verification-documents-view 1lpbgjq_0" ON storage.objects;

-- 2. Verify the old policies are removed
SELECT 
  'Remaining Storage Policies' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%verification%';

-- 3. Test: Check if new policies are working
SELECT 
  'Final Policy Check' as info,
  COUNT(*) as total_verification_policies
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%verification%';

-- 4. Summary of what should remain:
-- - "Allow verification document uploads" (INSERT)
-- - "Allow verification document viewing" (SELECT)  
-- - "Allow verification document updates" (UPDATE)
-- - "Allow verification document deletion" (DELETE)
