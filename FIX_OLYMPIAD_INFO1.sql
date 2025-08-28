-- Fix olympiad_info1@startupnationindia.com User
-- This will specifically fix this user's missing documents

-- 1. First, let's see what storage files exist for this user
SELECT 
  'Storage Files for olympiad_info1' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%olympiad_info1%'
ORDER BY created_at DESC;

-- 2. Check the current user profile
SELECT 
  'Current Profile' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- 3. Check if there are any files with similar email patterns
SELECT 
  'Similar Email Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND (name LIKE '%olympiad%' OR name LIKE '%startupnationindia%')
  AND name NOT LIKE '%.emptyFolderPlaceholder'
ORDER BY created_at DESC;

-- 4. Check all recent storage files to see the pattern
SELECT 
  'All Recent Storage Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
  AND created_at >= CURRENT_DATE - INTERVAL '2 days'
ORDER BY created_at DESC;

-- 5. Try to find the exact files for this user
-- Let's check if the files might be stored with a different pattern
SELECT 
  'Potential User Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND (
    name LIKE '%olympiad_info1%' OR
    name LIKE '%olympiad%' OR
    name LIKE '%sarvesh%' OR
    name LIKE '%2025-08-24%'
  )
  AND name NOT LIKE '%.emptyFolderPlaceholder'
ORDER BY created_at DESC;
