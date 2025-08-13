-- =====================================================
-- CREATE FINANCIAL DOCUMENTS BUCKET
-- =====================================================

-- Check if financial-documents bucket exists
SELECT 'Checking if financial-documents bucket exists...' as status;

SELECT 
    id, 
    name, 
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'financial-documents';

-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'financial-documents',
    'financial-documents',
    true, -- Public bucket for easier access
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
) ON CONFLICT (id) DO NOTHING;

-- Verify bucket was created
SELECT 'Verifying bucket creation...' as status;
SELECT 
    id, 
    name, 
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'financial-documents';

-- =====================================================
-- CREATE BASIC STORAGE POLICIES
-- =====================================================

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow authenticated users to upload financial documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to financial documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update financial documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete financial documents" ON storage.objects;

-- Policy: Allow authenticated users to upload files to financial-documents
CREATE POLICY "Allow authenticated users to upload financial documents" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'financial-documents' AND
    auth.role() = 'authenticated'
);

-- Policy: Allow public access to download files from financial-documents
CREATE POLICY "Allow public access to financial documents" ON storage.objects
FOR SELECT USING (
    bucket_id = 'financial-documents'
);

-- Policy: Allow authenticated users to update files in financial-documents
CREATE POLICY "Allow authenticated users to update financial documents" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'financial-documents' AND
    auth.role() = 'authenticated'
);

-- Policy: Allow authenticated users to delete files from financial-documents
CREATE POLICY "Allow authenticated users to delete financial documents" ON storage.objects
FOR DELETE USING (
    bucket_id = 'financial-documents' AND
    auth.role() = 'authenticated'
);

-- =====================================================
-- VERIFICATION
-- =====================================================

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

SELECT 'Financial documents bucket and policies setup complete!' as status;
