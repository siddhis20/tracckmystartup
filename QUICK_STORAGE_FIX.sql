-- =====================================================
-- QUICK STORAGE FIX - ONLY FOR FILE UPLOADS
-- =====================================================
-- This script ONLY fixes the storage bucket for file uploads
-- Does NOT touch any compliance functions or triggers
-- =====================================================

-- Step 1: Create storage bucket for compliance documents
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

-- Step 2: Create simple storage policy
-- =====================================================

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Public Access" ON storage.objects;

-- Create simple public access policy
CREATE POLICY "Public Access" ON storage.objects
    FOR ALL USING (bucket_id = 'compliance-documents');

-- Step 3: Verify the fix
-- =====================================================

SELECT 
    'storage_fix_check' as check_type,
    id,
    name,
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'compliance-documents';

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'STORAGE FIX COMPLETE!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Storage bucket created/updated';
    RAISE NOTICE '✅ File uploads should now work';
    RAISE NOTICE '✅ Compliance tasks remain unchanged';
    RAISE NOTICE '========================================';
END $$;


