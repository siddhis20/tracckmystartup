-- Check olympiad_info1@startupnationindia.com Status
-- This will verify if the documents were linked correctly

-- 1. Check the current user profile
SELECT 
  'Current Profile Status' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at,
  updated_at
FROM public.users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- 2. Check if there are any files for olympiad_info1 in storage
SELECT 
  'Storage Files for olympiad_info1' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%olympiad_info1%'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
ORDER BY created_at DESC;

-- 3. Check if there are any files with similar patterns
SELECT 
  'Similar Pattern Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND (
    name LIKE '%olympiad%' OR
    name LIKE '%sarvesh%'
  )
  AND name NOT LIKE '%olympiad_support2%'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
ORDER BY created_at DESC;

-- 4. Check all recent files to see what's available
SELECT 
  'All Recent Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
  AND created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY created_at DESC;
