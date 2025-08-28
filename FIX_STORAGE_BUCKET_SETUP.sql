-- =====================================================
-- FIX STORAGE BUCKET SETUP FOR COMPLIANCE DOCUMENTS
-- =====================================================
-- This script properly sets up the storage bucket for compliance documents
-- =====================================================

-- Step 1: Check if storage bucket exists
-- =====================================================

SELECT 
    'storage_bucket_check' as check_type,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'compliance-documents';

-- Step 2: Create storage bucket if it doesn't exist
-- =====================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'compliance-documents',
    'compliance-documents',
    true,
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Step 3: Drop existing storage policies
-- =====================================================

DROP POLICY IF EXISTS "Startups can upload their own compliance documents" ON storage.objects;
DROP POLICY IF EXISTS "Startups can view their own compliance documents" ON storage.objects;
DROP POLICY IF EXISTS "CA/CS users can view all compliance documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage all compliance documents" ON storage.objects;

-- Step 4: Create storage policies
-- =====================================================

-- Policy for startups to upload their own compliance documents
CREATE POLICY "Startups can upload their own compliance documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'compliance-documents' AND
        (auth.uid() IN (
            SELECT user_id FROM public.startups 
            WHERE id = CAST(SPLIT_PART(name, '/', 1) AS INTEGER)
        ))
    );

-- Policy for startups to view their own compliance documents
CREATE POLICY "Startups can view their own compliance documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'compliance-documents' AND
        (auth.uid() IN (
            SELECT user_id FROM public.startups 
            WHERE id = CAST(SPLIT_PART(name, '/', 1) AS INTEGER)
        ))
    );

-- Policy for CA/CS users to view all compliance documents
CREATE POLICY "CA/CS users can view all compliance documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'compliance-documents' AND
        (auth.jwt() ->> 'role' IN ('CA', 'CS', 'Admin'))
    );

-- Policy for admins to manage all compliance documents
CREATE POLICY "Admins can manage all compliance documents" ON storage.objects
    FOR ALL USING (
        bucket_id = 'compliance-documents' AND
        (auth.jwt() ->> 'role' = 'Admin')
    );

-- Step 5: Enable RLS on storage.objects if not already enabled
-- =====================================================

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Step 6: Test the storage bucket setup
-- =====================================================

DO $$
DECLARE
    bucket_exists BOOLEAN;
    policies_count INTEGER;
BEGIN
    -- Check if bucket exists
    SELECT EXISTS(
        SELECT 1 FROM storage.buckets WHERE id = 'compliance-documents'
    ) INTO bucket_exists;
    
    IF bucket_exists THEN
        RAISE NOTICE '✅ Storage bucket "compliance-documents" exists';
    ELSE
        RAISE NOTICE '❌ Storage bucket "compliance-documents" does not exist';
    END IF;
    
    -- Count policies
    SELECT COUNT(*) INTO policies_count
    FROM pg_policies 
    WHERE tablename = 'objects' 
    AND schemaname = 'storage'
    AND policyname LIKE '%compliance%';
    
    RAISE NOTICE 'Found % storage policies for compliance documents', policies_count;
    
END $$;

-- Step 7: Show current storage bucket configuration
-- =====================================================

SELECT 
    'final_storage_check' as check_type,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    created_at
FROM storage.buckets 
WHERE id = 'compliance-documents';

-- Step 8: Show storage policies
-- =====================================================

SELECT 
    'storage_policies_check' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
AND policyname LIKE '%compliance%'
ORDER BY policyname;

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'STORAGE BUCKET SETUP COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Storage bucket "compliance-documents" created/updated';
    RAISE NOTICE '✅ Storage policies created';
    RAISE NOTICE '✅ RLS enabled on storage.objects';
    RAISE NOTICE '✅ File uploads should now work';
    RAISE NOTICE '========================================';
END $$;

