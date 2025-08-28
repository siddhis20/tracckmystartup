-- Fix All Recent Users - Link Storage Files to Profiles
-- This will fix all users who have files in storage but missing document links

-- 1. Find all recent users with missing documents
SELECT 
  'Users Needing Fix' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
WHERE (government_id IS NULL OR ca_license IS NULL OR verification_documents IS NULL)
  AND role IN ('CA', 'CS')
  AND created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY created_at DESC;

-- 2. Find all storage files for recent users
SELECT 
  'Storage Files for Recent Users' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
  AND created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY created_at DESC;

-- 3. Fix user: olympiad_support2@startupnationindia.com
UPDATE public.users 
SET 
  government_id = (
    SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
    FROM storage.objects 
    WHERE bucket_id = 'verification-documents'
      AND name LIKE '%olympiad_support2%'
      AND name LIKE '%government-id%'
    ORDER BY created_at DESC
    LIMIT 1
  ),
  ca_license = (
    SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
    FROM storage.objects 
    WHERE bucket_id = 'verification-documents'
      AND name LIKE '%olympiad_support2%'
      AND name LIKE '%ca-license%'
    ORDER BY created_at DESC
    LIMIT 1
  ),
  verification_documents = (
    SELECT ARRAY(
      SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
      FROM storage.objects 
      WHERE bucket_id = 'verification-documents'
        AND name LIKE '%olympiad_support2%'
        AND name NOT LIKE '%.emptyFolderPlaceholder'
      ORDER BY created_at DESC
    )
  ),
  updated_at = NOW()
WHERE email = 'olympiad_support2@startupnationindia.com';

-- 4. Fix user: olympiad_info1@startupnationindia.com (if exists)
UPDATE public.users 
SET 
  government_id = (
    SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
    FROM storage.objects 
    WHERE bucket_id = 'verification-documents'
      AND name LIKE '%olympiad_info1%'
      AND name LIKE '%government-id%'
    ORDER BY created_at DESC
    LIMIT 1
  ),
  ca_license = (
    SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
    FROM storage.objects 
    WHERE bucket_id = 'verification-documents'
      AND name LIKE '%olympiad_info1%'
      AND name LIKE '%ca-license%'
    ORDER BY created_at DESC
    LIMIT 1
  ),
  verification_documents = (
    SELECT ARRAY(
      SELECT 'https://dlesebbmlrewsbmqvuza.supabase.co/storage/v1/object/public/verification-documents/' || name
      FROM storage.objects 
      WHERE bucket_id = 'verification-documents'
        AND name LIKE '%olympiad_info1%'
        AND name NOT LIKE '%.emptyFolderPlaceholder'
      ORDER BY created_at DESC
    )
  ),
  updated_at = NOW()
WHERE email = 'olympiad_info1@startupnationindia.com';

-- 5. Verify all fixes worked
SELECT 
  'After Fix - All Users' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  updated_at
FROM public.users 
WHERE email IN ('olympiad_support2@startupnationindia.com', 'olympiad_info1@startupnationindia.com')
ORDER BY created_at DESC;

-- 6. Check if there are any other users still needing fixes
SELECT 
  'Remaining Users Needing Fix' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
WHERE (government_id IS NULL OR ca_license IS NULL OR verification_documents IS NULL)
  AND role IN ('CA', 'CS')
  AND created_at >= CURRENT_DATE - INTERVAL '1 day'
ORDER BY created_at DESC;
