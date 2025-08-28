-- Check Existing User Profile
-- This will show us what's currently stored for the user

-- 1. Check the current user profile
SELECT 
  'Current Profile Data' as info,
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
WHERE id = 'fe28e158-c531-4bed-89f0-02e9dd905830';

-- 2. Check if there are any other users with similar data
SELECT 
  'All Users with Documents' as info,
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

-- 3. Check the exact column types
SELECT 
  'Column Types' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
  AND column_name IN ('government_id', 'ca_license', 'verification_documents')
ORDER BY column_name;
