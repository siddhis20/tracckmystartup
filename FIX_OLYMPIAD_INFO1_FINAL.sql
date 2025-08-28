-- Final Fix for olympiad_info1@startupnationindia.com
-- This will find and link documents regardless of storage path pattern

-- 1. First, let's see what files actually exist for this user
SELECT 
  'All Files for olympiad_info1' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND (
    name LIKE '%olympiad_info1%' OR
    name LIKE '%olympiad%' OR
    name LIKE '%sarvesh%'
  )
  AND name NOT LIKE '%.emptyFolderPlaceholder'
ORDER BY created_at DESC;

-- 2. Update the user profile with the most recent files found
UPDATE public.users 
SET 
  government_id = (
    SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
    FROM storage.objects 
    WHERE bucket_id = 'verification-documents'
      AND (
        name LIKE '%olympiad_info1%' OR
        name LIKE '%olympiad%' OR
        name LIKE '%sarvesh%'
      )
      AND name LIKE '%government-id%'
      AND name NOT LIKE '%.emptyFolderPlaceholder'
    ORDER BY created_at DESC
    LIMIT 1
  ),
  ca_license = (
    SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
    FROM storage.objects 
    WHERE bucket_id = 'verification-documents'
      AND (
        name LIKE '%olympiad_info1%' OR
        name LIKE '%olympiad%' OR
        name LIKE '%sarvesh%'
      )
      AND name LIKE '%ca-license%'
      AND name NOT LIKE '%.emptyFolderPlaceholder'
    ORDER BY created_at DESC
    LIMIT 1
  ),
  verification_documents = (
    SELECT ARRAY(
      SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
      FROM storage.objects 
      WHERE bucket_id = 'verification-documents'
        AND (
          name LIKE '%olympiad_info1%' OR
          name LIKE '%olympiad%' OR
          name LIKE '%sarvesh%'
        )
        AND name NOT LIKE '%.emptyFolderPlaceholder'
      ORDER BY created_at DESC
    )
  ),
  updated_at = NOW()
WHERE email = 'olympiad_info1@startupnationindia.com';

-- 3. Verify the update worked
SELECT 
  'After Update' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  updated_at
FROM public.users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- 4. Clean up duplicate files (keep only the most recent)
DELETE FROM storage.objects 
WHERE id IN (
  SELECT id FROM (
    SELECT 
      id,
      name,
      created_at,
      ROW_NUMBER() OVER (PARTITION BY name ORDER BY created_at DESC) as rn
    FROM storage.objects 
    WHERE bucket_id = 'verification-documents'
      AND (
        name LIKE '%olympiad_info1%' OR
        name LIKE '%olympiad%' OR
        name LIKE '%sarvesh%'
      )
      AND name NOT LIKE '%.emptyFolderPlaceholder'
  ) ranked
  WHERE rn > 1
);

-- 5. Final verification - check if duplicates are gone
SELECT 
  'After Cleanup' as info,
  name,
  COUNT(*) as file_count,
  MIN(created_at) as first_created,
  MAX(created_at) as last_created
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND (
    name LIKE '%olympiad_info1%' OR
    name LIKE '%olympiad%' OR
    name LIKE '%sarvesh%'
  )
  AND name NOT LIKE '%.emptyFolderPlaceholder'
GROUP BY name
ORDER BY file_count DESC;
