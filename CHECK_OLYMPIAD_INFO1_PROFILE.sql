-- Check olympiad_info1@startupnationindia.com Profile Status
-- This will show us the current state of the user profile

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

-- 2. Check if there are any files with UUID pattern for this user
SELECT 
  'UUID Pattern Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%9f86c968-6818-4a4f-8f38-7b6155db83c1%'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
ORDER BY created_at DESC;

-- 3. Check all files created around the same time as the user
SELECT 
  'Files Created Around User Registration' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND created_at BETWEEN '2025-08-24 10:46:00' AND '2025-08-24 11:00:00'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
ORDER BY created_at DESC;

-- 4. Check if there are any orphaned files (files without clear user association)
SELECT 
  'Orphaned Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name NOT LIKE '%olympiad_support2%'
  AND name NOT LIKE '%olympiad_info1%'
  AND name NOT LIKE '%olympiad%'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
  AND created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY created_at DESC;
