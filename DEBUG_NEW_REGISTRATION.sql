-- Debug New Registration - Check what happened with the latest user
-- Run this to see the current state of the new registration

-- 1. Check the most recent user registration
SELECT 
  'Most Recent User' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at,
  updated_at
FROM public.users 
ORDER BY created_at DESC
LIMIT 1;

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

-- 3. Check if there are any users with documents at all
SELECT 
  'Users with Documents' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
WHERE government_id IS NOT NULL 
   OR ca_license IS NOT NULL 
   OR (verification_documents IS NOT NULL AND array_length(verification_documents, 1) > 0)
ORDER BY created_at DESC;

-- 4. Check the latest files in storage
SELECT 
  'Latest Storage Files' as info,
  name,
  bucket_id,
  created_at,
  updated_at
FROM storage.objects 
WHERE bucket_id = 'verification-documents'
ORDER BY created_at DESC
LIMIT 5;

-- 5. Check if there are any database errors or constraints blocking inserts
SELECT 
  'Table Constraints' as info,
  conname,
  contype,
  constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass;

-- 6. Check RLS policies on users table
SELECT 
  'RLS Policies' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'users' 
  AND schemaname = 'public';
