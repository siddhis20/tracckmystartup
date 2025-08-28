-- Debug olympiad_info1@startupnationindia.com Storage Files
-- This will help us understand why the linking failed and why there are duplicates

-- 1. Check ALL storage files for this user (any pattern)
SELECT 
  'All Storage Files for olympiad_info1' as info,
  name,
  bucket_id,
  created_at,
  updated_at,
  metadata
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

-- 2. Check for files with exact email pattern
SELECT 
  'Exact Email Pattern Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE 'olympiad_info1@startupnationindia.com/%'
ORDER BY created_at DESC;

-- 3. Check for files with underscore instead of @
SELECT 
  'Underscore Pattern Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%olympiad_info1_startupnationindia_com%'
ORDER BY created_at DESC;

-- 4. Check for files with different date patterns
SELECT 
  'Date Pattern Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%2025-08-24%'
  AND name LIKE '%olympiad%'
ORDER BY created_at DESC;

-- 5. Check for duplicate files (same name, different timestamps)
SELECT 
  'Potential Duplicates' as info,
  name,
  COUNT(*) as file_count,
  MIN(created_at) as first_created,
  MAX(created_at) as last_created
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%olympiad_info1%'
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY file_count DESC;

-- 6. Check the user's auth.users entry
SELECT 
  'Auth User Info' as info,
  id,
  email,
  created_at,
  updated_at
FROM auth.users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- 7. Check if there are any files with UUID patterns
SELECT 
  'UUID Pattern Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%9f86c968-6818-4a4f-8f38-7b6155db83c1%'
ORDER BY created_at DESC;
