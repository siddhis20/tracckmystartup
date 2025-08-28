-- Link olympiad_info1@startupnationindia.com Documents
-- This will find and link the existing storage documents to the user profile

-- 1. Find all storage files for this user
SELECT 
  'Found Storage Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%olympiad_info1%'
ORDER BY created_at DESC;

-- 2. Update the user profile with the found documents
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

-- 4. Check if there are any other users still needing fixes
SELECT 
  'All Users Status' as info,
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
  AND created_at >= CURRENT_DATE - INTERVAL '2 days'
ORDER BY created_at DESC;
