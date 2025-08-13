-- =====================================================
-- QUICK DOWNLOAD FIX - NO POLICY CHANGES
-- =====================================================

-- Check current bucket status
SELECT 'Current bucket status:' as status;
SELECT 
    id, 
    name, 
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'financial-attachments';

-- Check what files exist
SELECT 'Files in bucket:' as status;
SELECT 
    name,
    bucket_id,
    created_at
FROM storage.objects 
WHERE bucket_id = 'financial-attachments'
ORDER BY created_at DESC;

-- Check what URLs are stored in database
SELECT 'URLs stored in database:' as status;
SELECT 
    id,
    record_type,
    description,
    attachment_url,
    CASE 
        WHEN attachment_url LIKE '%financial-documents%' THEN 'WRONG BUCKET'
        WHEN attachment_url LIKE '%financial-attachments%' THEN 'CORRECT BUCKET'
        ELSE 'UNKNOWN BUCKET'
    END as bucket_check
FROM financial_records 
WHERE attachment_url IS NOT NULL 
AND attachment_url != '';

-- =====================================================
-- MANUAL STEPS REQUIRED
-- =====================================================

-- Since we can't modify policies via SQL, you need to:

-- 1. Go to Supabase Dashboard → Storage → Policies
-- 2. Find 'financial-attachments' bucket
-- 3. Create these policies manually:

-- Policy 1: "Allow public access to financial attachments"
-- Operation: SELECT
-- Definition: (bucket_id = 'financial-attachments')

-- Policy 2: "Allow authenticated users to upload financial attachments"  
-- Operation: INSERT
-- Definition: (bucket_id = 'financial-attachments' AND auth.role() = 'authenticated')

-- Policy 3: "Allow authenticated users to update financial attachments"
-- Operation: UPDATE  
-- Definition: (bucket_id = 'financial-attachments' AND auth.role() = 'authenticated')

-- Policy 4: "Allow authenticated users to delete financial attachments"
-- Operation: DELETE
-- Definition: (bucket_id = 'financial-attachments' AND auth.role() = 'authenticated')

-- 4. Make sure the bucket is set to "Public" in Storage → Buckets
