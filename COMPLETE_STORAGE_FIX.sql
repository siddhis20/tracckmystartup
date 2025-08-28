-- Complete Storage Policy Fix
-- This script completely removes all problematic policies and creates working ones

-- 1. First, let's see ALL storage policies that might be interfering
SELECT 
  'ALL Storage Policies' as info,
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
ORDER BY policyname;

-- 2. Drop ALL verification-documents related policies (including any we might have missed)
DROP POLICY IF EXISTS "Allow verification document uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow verification document viewing" ON storage.objects;
DROP POLICY IF EXISTS "Allow verification document updates" ON storage.objects;
DROP POLICY IF EXISTS "Allow verification document deletion" ON storage.objects;

-- Also drop any other policies that might exist
DROP POLICY IF EXISTS "verification-documents-delete 1lpbgjq_0" ON storage.objects;
DROP POLICY IF EXISTS "verification-documents-update 1lpbgjq_0" ON storage.objects;
DROP POLICY IF EXISTS "verification-documents-upload 1lpbgjq_0" ON storage.objects;
DROP POLICY IF EXISTS "verification-documents-view 1lpbgjq_0" ON storage.objects;

-- 3. Create a completely open policy for verification-documents bucket (for testing)
CREATE POLICY "Open verification documents access" ON storage.objects
FOR ALL USING (bucket_id = 'verification-documents');

-- 4. Alternative: Create more specific policies if you prefer
-- CREATE POLICY "Allow all verification document operations" ON storage.objects
-- FOR ALL USING (
--   bucket_id = 'verification-documents' AND
--   auth.role() = 'authenticated'
-- );

-- 5. Verify the new policy is created
SELECT 
  'New Policy Check' as info,
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

-- 6. Check if RLS is enabled on storage.objects
SELECT 
  'RLS Status Check' as info,
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE schemaname = 'storage' 
  AND tablename = 'objects';

-- 7. If RLS is enabled and still causing issues, we can temporarily disable it
-- ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- 8. Final verification - count total policies
SELECT 
  'Final Policy Count' as info,
  COUNT(*) as total_storage_policies
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage';
