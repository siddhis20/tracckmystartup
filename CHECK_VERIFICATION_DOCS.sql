-- Check if verification documents were stored during registration
-- Run this in Supabase SQL Editor to see what's in the database

-- 1. Check all users and their verification documents
SELECT 
  'User Verification Documents' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
ORDER BY created_at DESC;

-- 2. Check specific user (replace with your email)
-- SELECT 
--   'Specific User Check' as info,
--   id,
--   email,
--   name,
--   role,
--   government_id,
--   ca_license,
--   verification_documents,
--   phone,
--   address,
--   city,
--   state,
--   country,
--   company,
--   profile_photo_url
-- FROM public.users 
-- WHERE email = 'your-email@example.com';

-- 3. Check if any users have verification documents
SELECT 
  'Verification Document Summary' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN government_id IS NOT NULL THEN 1 END) as users_with_gov_id,
  COUNT(CASE WHEN ca_license IS NOT NULL THEN 1 END) as users_with_ca_license,
  COUNT(CASE WHEN verification_documents IS NOT NULL AND array_length(verification_documents, 1) > 0 THEN 1 END) as users_with_verification_docs
FROM public.users;

-- 4. Check storage bucket contents (if you have access)
-- SELECT 
--   'Storage Bucket Check' as info,
--   name,
--   bucket_id,
--   created_at
-- FROM storage.objects 
-- WHERE bucket_id = 'verification-documents'
-- ORDER BY created_at DESC
-- LIMIT 10;
