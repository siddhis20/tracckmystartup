-- Link Registration Files to User Profile
-- This will connect the files uploaded during registration to the user's profile

-- 1. First, let's see what we're working with
SELECT 
  'Current Situation' as info,
  'Registration files stored with email path' as detail,
  'Profile files stored with UUID path' as detail2;

-- 2. Find the user profile that needs linking
SELECT 
  'User Profile to Fix' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
WHERE email LIKE '%olympiad_info1%'
ORDER BY created_at DESC
LIMIT 1;

-- 3. Find the registration files in storage
SELECT 
  'Registration Files Found' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND name LIKE '%olympiad_info1%'
ORDER BY created_at DESC;

-- 4. Update the user profile to link to registration files
-- We'll extract the file URLs from the storage paths
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
WHERE email LIKE '%olympiad_info1%'
  AND (government_id IS NULL OR ca_license IS NULL OR verification_documents IS NULL);

-- 5. Verify the update worked
SELECT 
  'After Linking Files' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  updated_at
FROM public.users 
WHERE email LIKE '%olympiad_info1%'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Check if there are other users with similar issues
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
  AND created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY created_at DESC;
