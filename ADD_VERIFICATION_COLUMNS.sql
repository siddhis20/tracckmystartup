-- Add Missing Verification Document and Profile Columns to Users Table
-- This script adds the columns needed for storing verification documents and profile information

-- 1. Add verification document columns
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS government_id TEXT,
ADD COLUMN IF NOT EXISTS ca_license TEXT,
ADD COLUMN IF NOT EXISTS verification_documents TEXT[];

-- 2. Add profile information columns
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS country TEXT,
ADD COLUMN IF NOT EXISTS company TEXT,
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT;

-- 3. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_city ON public.users(city);
CREATE INDEX IF NOT EXISTS idx_users_state ON public.users(state);
CREATE INDEX IF NOT EXISTS idx_users_country ON public.users(country);

-- 4. Add comments to document the new fields
COMMENT ON COLUMN public.users.government_id IS 'URL to government ID document (passport, driver license, etc.)';
COMMENT ON COLUMN public.users.ca_license IS 'URL to CA license document';
COMMENT ON COLUMN public.users.verification_documents IS 'Array of URLs to additional verification documents';
COMMENT ON COLUMN public.users.phone IS 'User phone number';
COMMENT ON COLUMN public.users.address IS 'User street address';
COMMENT ON COLUMN public.users.city IS 'User city';
COMMENT ON COLUMN public.users.state IS 'User state/province';
COMMENT ON COLUMN public.users.country IS 'User country';
COMMENT ON COLUMN public.users.company IS 'User company/organization';
COMMENT ON COLUMN public.users.profile_photo_url IS 'Public URL of profile photo';

-- 5. Verify the new structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name IN (
    'government_id', 'ca_license', 'verification_documents',
    'phone', 'address', 'city', 'state', 'country', 'company', 'profile_photo_url'
  )
ORDER BY column_name;

-- 6. Show current table structure
SELECT 
  'Current Users Table Structure' as info,
  COUNT(*) as total_columns
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users';

-- 7. Test: Check if new columns are accessible
SELECT 
  'Test Query' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  phone,
  address,
  city,
  state,
  country,
  company,
  profile_photo_url
FROM public.users 
LIMIT 2;
