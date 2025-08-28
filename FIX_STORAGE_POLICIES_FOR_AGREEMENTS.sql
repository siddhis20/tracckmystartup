-- Fix storage policies for agreement uploads by facilitators
-- This allows facilitators to upload agreement PDFs to the startup-documents bucket

-- First, let's check if the bucket exists
SELECT 'Checking if startup-documents bucket exists:' as info;
SELECT id, name, public, file_size_limit, allowed_mime_types 
FROM storage.buckets 
WHERE id = 'startup-documents';

-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'startup-documents',
    'startup-documents',
    true,
    10485760, -- 10MB limit
    ARRAY['application/pdf', 'image/*']
) ON CONFLICT (id) DO NOTHING;

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Allow facilitators to upload agreements" ON storage.objects;
DROP POLICY IF EXISTS "Allow facilitators to view agreements" ON storage.objects;
DROP POLICY IF EXISTS "Allow startup owners to upload pitch materials" ON storage.objects;
DROP POLICY IF EXISTS "Allow startup owners to view their materials" ON storage.objects;

-- Create comprehensive policies for the startup-documents bucket
-- Policy 1: Allow facilitators to upload agreement files
CREATE POLICY "Allow facilitators to upload agreements" ON storage.objects
FOR INSERT TO AUTHENTICATED
WITH CHECK (
    bucket_id = 'startup-documents' 
    AND (storage.foldername(name))[1] = 'agreements'
    AND (storage.foldername(name))[2] IS NOT NULL
);

-- Policy 2: Allow facilitators to view agreement files they uploaded
CREATE POLICY "Allow facilitators to view agreements" ON storage.objects
FOR SELECT TO AUTHENTICATED
USING (
    bucket_id = 'startup-documents' 
    AND (storage.foldername(name))[1] = 'agreements'
);

-- Policy 3: Allow startup owners to upload pitch materials
CREATE POLICY "Allow startup owners to upload pitch materials" ON storage.objects
FOR INSERT TO AUTHENTICATED
WITH CHECK (
    bucket_id = 'startup-documents' 
    AND (storage.foldername(name))[1] = 'pitch-decks'
    AND (storage.foldername(name))[2] = auth.uid()::text
);

-- Policy 4: Allow startup owners to view their own pitch materials
CREATE POLICY "Allow startup owners to view their materials" ON storage.objects
FOR SELECT TO AUTHENTICATED
USING (
    bucket_id = 'startup-documents' 
    AND (
        (storage.foldername(name))[1] = 'pitch-decks' 
        AND (storage.foldername(name))[2] = auth.uid()::text
    )
    OR (storage.foldername(name))[1] = 'agreements'
);

-- Policy 5: Allow public read access to agreements (so startups can download them)
CREATE POLICY "Allow public read access to agreements" ON storage.objects
FOR SELECT TO PUBLIC
USING (
    bucket_id = 'startup-documents' 
    AND (storage.foldername(name))[1] = 'agreements'
);

-- Verify the policies were created
SELECT 'Storage policies created successfully. Verifying:' as info;
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

-- Test the bucket structure
SELECT 'Testing bucket structure:' as info;
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'startup-documents';

-- Show current objects in the bucket (if any)
SELECT 'Current objects in startup-documents bucket:' as info;
SELECT 
    name,
    bucket_id,
    owner,
    created_at,
    updated_at,
    last_accessed_at,
    metadata
FROM storage.objects 
WHERE bucket_id = 'startup-documents'
ORDER BY created_at DESC
LIMIT 10;

SELECT 'Storage policies for agreements have been fixed successfully!' as status;
