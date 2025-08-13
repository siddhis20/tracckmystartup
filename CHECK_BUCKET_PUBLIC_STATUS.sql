-- =====================================================
-- CHECK BUCKET PUBLIC STATUS
-- =====================================================

-- Check if the bucket is public (this is crucial for direct URL access)
SELECT 'Checking bucket public status...' as status;
SELECT 
    id, 
    name, 
    public,
    file_size_limit,
    CASE 
        WHEN public = true THEN '✅ PUBLIC - Files can be accessed via direct URLs'
        ELSE '❌ PRIVATE - Files cannot be accessed via direct URLs'
    END as access_status
FROM storage.buckets 
WHERE id = 'financial-attachments';

-- Check if there are any files in the bucket
SELECT 'Checking files in bucket...' as status;
SELECT 
    name,
    bucket_id,
    created_at,
    updated_at
FROM storage.objects 
WHERE bucket_id = 'financial-attachments'
ORDER BY created_at DESC;

-- =====================================================
-- SOLUTION
-- =====================================================

-- If the bucket is NOT public, you need to make it public:

-- 1. Go to Supabase Dashboard → Storage → Buckets
-- 2. Find 'financial-attachments' bucket
-- 3. Click the Settings icon (gear) next to the bucket
-- 4. Check the "Public bucket" checkbox
-- 5. Save the changes

-- This will allow direct URL access to files like:
-- https://your-project.supabase.co/storage/v1/object/public/financial-attachments/11/filename.pdf
