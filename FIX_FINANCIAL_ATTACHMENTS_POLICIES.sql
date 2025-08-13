-- =====================================================
-- FIX FINANCIAL ATTACHMENTS STORAGE POLICIES
-- =====================================================

-- First, let's check if the bucket exists and its current settings
SELECT 'Checking financial-attachments bucket...' as status;
SELECT 
    id, 
    name, 
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'financial-attachments';

-- Make sure the bucket is public (this is crucial for downloads)
UPDATE storage.buckets 
SET public = true 
WHERE id = 'financial-attachments';

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies for financial-attachments to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to upload financial attachments" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to financial attachments" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update financial attachments" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete financial attachments" ON storage.objects;

-- Create simple, permissive policies for financial-attachments bucket
CREATE POLICY "Allow authenticated users to upload financial attachments" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'financial-attachments' AND
    auth.role() = 'authenticated'
);

-- Allow public access to download files (this is the key for downloads)
CREATE POLICY "Allow public access to financial attachments" ON storage.objects
FOR SELECT USING (
    bucket_id = 'financial-attachments'
);

-- Allow authenticated users to update files
CREATE POLICY "Allow authenticated users to update financial attachments" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'financial-attachments' AND
    auth.role() = 'authenticated'
);

-- Allow authenticated users to delete files
CREATE POLICY "Allow authenticated users to delete financial attachments" ON storage.objects
FOR DELETE USING (
    bucket_id = 'financial-attachments' AND
    auth.role() = 'authenticated'
);

-- Verify the policies were created
SELECT 'Verifying storage policies...' as status;
SELECT 
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%financial%'
ORDER BY policyname;

-- Test if we can access the files
SELECT 'Testing file access...' as status;
SELECT 
    name,
    bucket_id,
    created_at
FROM storage.objects 
WHERE bucket_id = 'financial-attachments'
ORDER BY created_at DESC;

SELECT 'Financial attachments policies fixed!' as status;
