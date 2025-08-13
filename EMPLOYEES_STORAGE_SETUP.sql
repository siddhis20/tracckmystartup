-- =====================================================
-- EMPLOYEES STORAGE SETUP
-- =====================================================

-- Check if employee-contracts bucket exists
SELECT 'Checking if employee-contracts bucket exists...' as status;

SELECT 
    id, 
    name, 
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'employee-contracts';

-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'employee-contracts',
    'employee-contracts',
    true, -- Public bucket for easier access
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
) ON CONFLICT (id) DO NOTHING;

-- Verify bucket was created
SELECT 'Verifying bucket creation...' as status;
SELECT 
    id, 
    name, 
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'employee-contracts';

-- =====================================================
-- CREATE BASIC STORAGE POLICIES
-- =====================================================

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies for employee-contracts to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to upload employee contracts" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to employee contracts" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update employee contracts" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete employee contracts" ON storage.objects;

-- Create simple, permissive policies for employee-contracts bucket
CREATE POLICY "Allow authenticated users to upload employee contracts" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'employee-contracts' AND
    auth.role() = 'authenticated'
);

-- Allow public access to download files (this is the key for downloads)
CREATE POLICY "Allow public access to employee contracts" ON storage.objects
FOR SELECT USING (
    bucket_id = 'employee-contracts'
);

-- Allow authenticated users to update files
CREATE POLICY "Allow authenticated users to update employee contracts" ON storage.objects
FOR UPDATE USING (
    bucket_id = 'employee-contracts' AND
    auth.role() = 'authenticated'
);

-- Allow authenticated users to delete files
CREATE POLICY "Allow authenticated users to delete employee contracts" ON storage.objects
FOR DELETE USING (
    bucket_id = 'employee-contracts' AND
    auth.role() = 'authenticated'
);

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify the policies were created
SELECT 'Verifying storage policies...' as status;
SELECT 
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%employee%'
ORDER BY policyname;

-- Test if we can access the bucket
SELECT 'Testing bucket access...' as status;
SELECT 
    name,
    bucket_id,
    created_at
FROM storage.objects 
WHERE bucket_id = 'employee-contracts'
ORDER BY created_at DESC;

SELECT 'Employee contracts storage setup complete!' as status;
