-- Check Profile Documents - Debug why verification documents aren't showing
-- Run this to see what's actually stored in the database

-- 1. Check the specific user who just registered
SELECT 
  'User Profile Check' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
WHERE email = 'olympiad_support1@startupnationindia.com';

-- 2. Check all recent users to see document status
SELECT 
  'Recent Users Document Status' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
ORDER BY created_at DESC
LIMIT 5;

-- 3. Check if verification_documents array has content
SELECT 
  'Verification Documents Array Check' as info,
  id,
  email,
  name,
  role,
  CASE 
    WHEN verification_documents IS NULL THEN 'NULL'
    WHEN array_length(verification_documents, 1) IS NULL THEN 'Empty Array'
    ELSE 'Has ' || array_length(verification_documents, 1) || ' documents'
  END as array_status,
  verification_documents
FROM public.users 
WHERE verification_documents IS NOT NULL 
  AND array_length(verification_documents, 1) > 0
ORDER BY created_at DESC;

-- 4. Check storage bucket to confirm files exist
-- (This will show if files are actually in storage)
SELECT 
  'Storage Files Check' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
ORDER BY created_at DESC
LIMIT 10;

