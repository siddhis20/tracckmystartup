-- Link New User Files to Profile
-- This will connect the storage files to the user profile for olympiad_support2@startupnationindia.com

-- 1. First, let's see what files exist in storage for this user
SELECT 
  'Storage Files Found' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%olympiad_support2%'
ORDER BY created_at DESC;

-- 2. Check the current user profile
SELECT 
  'Before Update' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
WHERE email = 'olympiad_support2@startupnationindia.com';

-- 3. Update the user profile with the storage file URLs
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

-- 4. Verify the update worked
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
WHERE email = 'olympiad_support2@startupnationindia.com';

-- 5. Check if there are any other users with missing documents
SELECT 
  'Other Users Needing Fix' as info,
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
