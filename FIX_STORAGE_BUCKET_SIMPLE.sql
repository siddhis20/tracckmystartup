-- =====================================================
-- FIX STORAGE BUCKET - SIMPLE VERSION
-- =====================================================
-- This script creates the storage bucket without modifying storage.objects directly
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

-- Step 3: Create simple storage policies (without complex RLS)
-- =====================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public Access" ON storage.objects;

-- Create a simple public access policy for the compliance-documents bucket
CREATE POLICY "Public Access" ON storage.objects
    FOR ALL USING (bucket_id = 'compliance-documents');

-- Step 4: Test the storage bucket setup
-- =====================================================

DO $$
DECLARE
    bucket_exists BOOLEAN;
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
    
END $$;

-- Step 5: Show current storage bucket configuration
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

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'STORAGE BUCKET SETUP COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Storage bucket "compliance-documents" created/updated';
    RAISE NOTICE '✅ Simple public access policy created';
    RAISE NOTICE '✅ File uploads should now work';
    RAISE NOTICE '========================================';
END $$;


