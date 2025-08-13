-- =====================================================
-- DEBUG ATTACHMENT URLS
-- =====================================================

-- Check what attachment URLs are stored in the database
SELECT 
    id,
    record_type,
    description,
    attachment_url,
    created_at
FROM financial_records 
WHERE attachment_url IS NOT NULL 
AND attachment_url != ''
ORDER BY created_at DESC;

-- Check if any URLs are pointing to the wrong bucket
SELECT 
    id,
    record_type,
    description,
    attachment_url,
    CASE 
        WHEN attachment_url LIKE '%financial-documents%' THEN 'financial-documents bucket'
        WHEN attachment_url LIKE '%financial-attachments%' THEN 'financial-attachments bucket'
        ELSE 'unknown bucket'
    END as bucket_type
FROM financial_records 
WHERE attachment_url IS NOT NULL 
AND attachment_url != '';

-- Check if the financial-attachments bucket exists and has files
SELECT 
    id, 
    name, 
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'financial-attachments';

-- List files in the financial-attachments bucket
SELECT 
    name,
    bucket_id,
    created_at,
    updated_at
FROM storage.objects 
WHERE bucket_id = 'financial-attachments'
ORDER BY created_at DESC;

-- Count total files in the bucket
SELECT 
    COUNT(*) as total_files
FROM storage.objects 
WHERE bucket_id = 'financial-attachments';
