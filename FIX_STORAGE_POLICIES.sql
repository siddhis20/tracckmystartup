-- Fix Storage Policies for Verification Documents
-- This script fixes the RLS policies that are blocking file uploads during registration

-- 1. First, let's check current storage policies
SELECT 
  'Current Storage Policies' as info,
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
  AND tablename LIKE '%verification%' OR policyname LIKE '%verification%';

-- 2. Drop existing problematic policies (if they exist)
DROP POLICY IF EXISTS "Users can upload their own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own verification documents" ON storage.objects;

-- 3. Create new, more permissive policies for verification-documents bucket

-- Allow ANY authenticated user to upload to verification-documents bucket
CREATE POLICY "Allow verification document uploads" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

-- Allow ANY authenticated user to view verification documents
CREATE POLICY "Allow verification document viewing" ON storage.objects
FOR SELECT USING (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

-- Allow users to update their own verification documents
CREATE POLICY "Allow verification document updates" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

-- Allow users to delete their own verification documents
CREATE POLICY "Allow verification document deletion" ON storage.objects
FOR DELETE USING (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

-- 4. Alternative: Create a completely open policy for testing (remove this in production)
-- CREATE POLICY "Open verification documents access" ON storage.objects
-- FOR ALL USING (bucket_id = 'verification-documents');

-- 5. Verify the new policies
SELECT 
  'New Storage Policies' as info,
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

-- 6. Test: Check if bucket is accessible
SELECT 
  'Storage Bucket Status' as info,
  name as bucket_name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE name = 'verification-documents';
