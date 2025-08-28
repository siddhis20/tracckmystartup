-- Users Table Update for Profile Management
-- This script adds missing profile fields to the existing users table
-- Uses existing verification-documents storage bucket

-- 1. Add new profile fields to users table (only if they don't exist)
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS country TEXT,
ADD COLUMN IF NOT EXISTS company TEXT,
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- Note: government_id, ca_license, and verification_documents fields 
-- should already exist from your registration system

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_city ON public.users(city);
CREATE INDEX IF NOT EXISTS idx_users_state ON public.users(state);
CREATE INDEX IF NOT EXISTS idx_users_country ON public.users(country);

-- 3. Add comments to document the new fields
COMMENT ON COLUMN public.users.phone IS 'User phone number';
COMMENT ON COLUMN public.users.address IS 'User street address';
COMMENT ON COLUMN public.users.city IS 'User city';
COMMENT ON COLUMN public.users.state IS 'User state/province';
COMMENT ON COLUMN public.users.country IS 'User country';
COMMENT ON COLUMN public.users.company IS 'User company/organization';
COMMENT ON COLUMN public.users.profile_photo_url IS 'Public URL of profile photo';

-- 4. Update RLS policies to allow users to update their own profile
-- (This assumes you already have RLS enabled on the users table)

-- Drop existing policies if they exist, then create new ones
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can select their own profile" ON public.users;

-- Allow users to update their own profile information
CREATE POLICY "Users can update their own profile" ON public.users
FOR UPDATE USING (auth.uid()::text = id::text);

-- Allow users to select their own profile
CREATE POLICY "Users can select their own profile" ON public.users
FOR SELECT USING (auth.uid()::text = id::text);

-- 5. Verify the table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name IN (
    'phone', 'address', 'city', 'state', 'country', 'company', 
    'government_id', 'ca_license', 'verification_documents', 'profile_photo_url'
  )
ORDER BY column_name;

-- 6. Test: Check if existing users have verification documents
SELECT 
  'Verification Documents Test' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  CASE 
    WHEN government_id IS NOT NULL OR ca_license IS NOT NULL OR (verification_documents IS NOT NULL AND array_length(verification_documents, 1) > 0)
    THEN 'Has Documents'
    ELSE 'No Documents'
  END as document_status
FROM public.users 
WHERE role IN ('CA', 'CS')
LIMIT 10;
