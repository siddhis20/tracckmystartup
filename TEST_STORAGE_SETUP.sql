-- Test script to verify storage setup for agreement uploads
-- Run this after executing FIX_STORAGE_POLICIES_FOR_AGREEMENTS.sql

-- 1. Check if the bucket exists and is properly configured
SELECT '1. Checking bucket configuration:' as test_step;
SELECT 
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types,
    CASE 
        WHEN public = true THEN '✅ Public bucket'
        ELSE '❌ Private bucket'
    END as bucket_status
FROM storage.buckets 
WHERE id = 'startup-documents';

-- 2. Check if RLS is enabled on storage.objects
SELECT '2. Checking RLS status:' as test_step;
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'storage' 
AND tablename = 'objects';

-- 3. List all storage policies
SELECT '3. Listing storage policies:' as test_step;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    CASE 
        WHEN cmd = 'INSERT' THEN '✅ Upload policy'
        WHEN cmd = 'SELECT' THEN '✅ View policy'
        ELSE '❓ Other policy'
    END as policy_type
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
ORDER BY cmd, policyname;

-- 4. Check if there are any existing files in the bucket
SELECT '4. Checking existing files:' as test_step;
SELECT 
    COUNT(*) as total_files,
    COUNT(CASE WHEN (storage.foldername(name))[1] = 'agreements' THEN 1 END) as agreement_files,
    COUNT(CASE WHEN (storage.foldername(name))[1] = 'pitch-decks' THEN 1 END) as pitch_deck_files
FROM storage.objects 
WHERE bucket_id = 'startup-documents';

-- 5. Show sample file structure
SELECT '5. Sample file structure:' as test_step;
SELECT 
    name,
    (storage.foldername(name))[1] as folder_type,
    (storage.foldername(name))[2] as subfolder,
    created_at,
    metadata
FROM storage.objects 
WHERE bucket_id = 'startup-documents'
ORDER BY created_at DESC
LIMIT 5;

-- 6. Test policy permissions (this will show what the current user can do)
SELECT '6. Testing current user permissions:' as test_step;
SELECT 
    'Current user can upload to agreements folder' as permission_test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM storage.objects 
            WHERE bucket_id = 'startup-documents' 
            AND (storage.foldername(name))[1] = 'agreements'
            LIMIT 1
        ) THEN '✅ Can access agreements folder'
        ELSE '❌ Cannot access agreements folder'
    END as upload_permission;

-- Summary
SELECT 'STORAGE SETUP TEST COMPLETE' as summary;
SELECT 
    'If you see ✅ marks above, the storage is properly configured.' as status,
    'If you see ❌ marks, run FIX_STORAGE_POLICIES_FOR_AGREEMENTS.sql again.' as action;
