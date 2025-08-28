-- Fix Storage Path Inconsistency
-- This will help us understand and fix the storage path issue

-- 1. Find the user with email olympiad_info1@startupnationindia.com
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
WHERE email LIKE '%olympiad_info1%'
ORDER BY created_at DESC
LIMIT 3;

-- 2. Check all recent users to see the pattern
SELECT 
  'Recent Users Pattern' as info,
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

-- 3. Check storage files for the specific user
SELECT 
  'Storage Files for User' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
  AND (name LIKE '%olympiad_info1%' OR name LIKE '%5329590a-8741-410d-b739%')
ORDER BY created_at DESC;

-- 4. Check if there are multiple users with similar emails
SELECT 
  'Duplicate Email Check' as info,
  id,
  email,
  name,
  role,
  created_at
FROM public.users 
WHERE email LIKE '%olympiad%'
ORDER BY created_at DESC;

-- 5. Check the auth.users table for the same email
SELECT 
  'Auth Users Check' as info,
  id,
  email,
  created_at,
  email_confirmed_at,
  last_sign_in_at
FROM auth.users 
WHERE email LIKE '%olympiad%'
ORDER BY created_at DESC;
