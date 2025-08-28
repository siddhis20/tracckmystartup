-- Fix olympiad_info1@startupnationindia.com - Remove Incorrect Document Links
-- This will remove the wrong documents that were linked from olympiad_support2

-- 1. First, let's see what we're about to fix
SELECT 
  'Before Fix - Current Incorrect Links' as info,
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

-- 2. Remove the incorrect document links (set to null since no files exist for this user)
UPDATE public.users 
SET 
  government_id = NULL,
  ca_license = NULL,
  verification_documents = NULL,
  updated_at = NOW()
WHERE email = 'olympiad_info1@startupnationindia.com';

-- 3. Verify the fix worked
SELECT 
  'After Fix - Documents Removed' as info,
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

-- 4. Verify olympiad_support2 still has their documents
SELECT 
  'olympiad_support2 Status' as info,
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

-- 5. Check if there are any files that might belong to olympiad_info1
SELECT 
  'Potential olympiad_info1 Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND (
    name LIKE '%olympiad_info1%' OR
    name LIKE '%sarvesh%'
  )
  AND name NOT LIKE '%olympiad_support2%'
  AND name NOT LIKE '%.emptyFolderPlaceholder'
ORDER BY created_at DESC;
