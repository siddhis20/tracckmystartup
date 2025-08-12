-- =====================================================
-- SUPABASE STORAGE POLICIES SETUP
-- =====================================================
-- Run this in your Supabase SQL Editor to enable file uploads

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLICY 1: Allow authenticated users to upload files
-- =====================================================

CREATE POLICY "Allow authenticated users to upload files" ON storage.objects
FOR INSERT WITH CHECK (
  auth.role() = 'authenticated' AND
  bucket_id IN (
    'verification-documents',
    'startup-documents', 
    'pitch-decks',
    'pitch-videos',
    'financial-documents',
    'employee-contracts'
  )
);

-- =====================================================
-- POLICY 2: Allow public access to download files
-- =====================================================

CREATE POLICY "Allow public access to download files" ON storage.objects
FOR SELECT USING (
  bucket_id IN (
    'verification-documents',
    'startup-documents',
    'pitch-decks', 
    'pitch-videos',
    'financial-documents',
    'employee-contracts'
  )
);

-- =====================================================
-- POLICY 3: Allow authenticated users to update their files
-- =====================================================

CREATE POLICY "Allow authenticated users to update files" ON storage.objects
FOR UPDATE USING (
  auth.role() = 'authenticated' AND
  bucket_id IN (
    'verification-documents',
    'startup-documents',
    'pitch-decks',
    'pitch-videos', 
    'financial-documents',
    'employee-contracts'
  )
);

-- =====================================================
-- POLICY 4: Allow authenticated users to delete their files
-- =====================================================

CREATE POLICY "Allow authenticated users to delete files" ON storage.objects
FOR DELETE USING (
  auth.role() = 'authenticated' AND
  bucket_id IN (
    'verification-documents',
    'startup-documents',
    'pitch-decks',
    'pitch-videos',
    'financial-documents', 
    'employee-contracts'
  )
);

-- =====================================================
-- POLICY 5: Allow authenticated users to list files
-- =====================================================

CREATE POLICY "Allow authenticated users to list files" ON storage.objects
FOR SELECT USING (
  auth.role() = 'authenticated' AND
  bucket_id IN (
    'verification-documents',
    'startup-documents',
    'pitch-decks',
    'pitch-videos',
    'financial-documents',
    'employee-contracts'
  )
);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if policies were created successfully
SELECT 
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

-- Check RLS status
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- =====================================================
-- ALTERNATIVE: SIMPLER POLICIES (if above don't work)
-- =====================================================

-- If the above policies don't work, try these simpler ones:

-- Allow all operations for authenticated users on all buckets
-- CREATE POLICY "Allow all operations for authenticated users" ON storage.objects
-- FOR ALL USING (auth.role() = 'authenticated');

-- Allow public read access to all buckets  
-- CREATE POLICY "Allow public read access" ON storage.objects
-- FOR SELECT USING (true);

-- =====================================================
-- BUCKET-SPECIFIC POLICIES (Alternative approach)
-- =====================================================

-- For verification-documents bucket specifically
-- CREATE POLICY "verification-documents-policy" ON storage.objects
-- FOR ALL USING (
--   bucket_id = 'verification-documents' AND
--   (auth.role() = 'authenticated' OR bucket_id = 'verification-documents')
-- );

-- For startup-documents bucket specifically  
-- CREATE POLICY "startup-documents-policy" ON storage.objects
-- FOR ALL USING (
--   bucket_id = 'startup-documents' AND
--   (auth.role() = 'authenticated' OR bucket_id = 'startup-documents')
-- );

-- =====================================================
-- NOTES
-- =====================================================

-- After running this script:
-- 1. Try uploading files again in your app
-- 2. Check browser console for any policy-related errors
-- 3. If still having issues, try the alternative policies above
-- 4. Make sure you're logged in when testing uploads

-- Common issues:
-- - If you get "permission denied", the policies aren't working
-- - If you get "bucket not found", check bucket names are exact
-- - If uploads timeout, it might be a network issue, not policy issue
