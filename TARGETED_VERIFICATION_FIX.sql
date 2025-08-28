-- Targeted Fix - Only for verification-documents bucket
-- This won't affect any other working buckets or policies

-- 1. First, let's see what verification-documents policies currently exist
SELECT 
  'Current Verification Policies' as info,
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

-- 2. Remove any existing verification-documents policies that might be conflicting
DROP POLICY IF EXISTS "Open verification documents access" ON storage.objects;
DROP POLICY IF EXISTS "Allow verification document uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow verification document viewing" ON storage.objects;
DROP POLICY IF EXISTS "Allow verification document updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow verification document deletion" ON storage.objects;

-- 3. Create ONE super permissive policy ONLY for verification-documents bucket
CREATE POLICY "verification-documents-super-permissive" ON storage.objects
FOR ALL USING (bucket_id = 'verification-documents');

-- 4. Verify the new policy is created
SELECT 
  'New Verification Policy' as info,
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

-- 5. Count total policies to confirm we didn't change anything else
SELECT 
  'Total Storage Policies' as info,
  COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage';
