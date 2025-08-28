-- Profile Storage Setup for Supabase
-- This script sets up storage buckets and updates the users table

-- 1. Create storage buckets (run these in Supabase Dashboard > Storage)

-- Profile Photos Bucket
-- Go to Supabase Dashboard > Storage > Create new bucket
-- Bucket name: profile-photos
-- Public bucket: true
-- File size limit: 5MB
-- Allowed MIME types: image/*

-- Verification Documents Bucket
-- Go to Supabase Dashboard > Storage > Create new bucket
-- Bucket name: verification-documents
-- Public bucket: true
-- File size limit: 10MB
-- Allowed MIME types: application/pdf, image/*, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document

-- 2. Set up storage policies for profile-photos bucket

-- Allow authenticated users to upload their own profile photos
CREATE POLICY "Users can upload their own profile photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'profile-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to view profile photos
CREATE POLICY "Users can view profile photos" ON storage.objects
FOR SELECT USING (
  bucket_id = 'profile-photos'
);

-- Allow users to update their own profile photos
CREATE POLICY "Users can update their own profile photos" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own profile photos
CREATE POLICY "Users can delete their own profile photos" ON storage.objects
FOR DELETE USING (
  bucket_id = 'profile-photos' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 3. Set up storage policies for verification-documents bucket

-- Allow authenticated users to upload their own verification documents
CREATE POLICY "Users can upload their own verification documents" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'verification-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow authenticated users to view verification documents
CREATE POLICY "Users can view verification documents" ON storage.objects
FOR SELECT USING (
  bucket_id = 'verification-documents'
);

-- Allow users to update their own verification documents
CREATE POLICY "Users can update their own verification documents" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'verification-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow users to delete their own verification documents
CREATE POLICY "Users can delete their own verification documents" ON storage.objects
FOR DELETE USING (
  bucket_id = 'verification-documents' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- 4. Update users table to include new profile fields

-- Add new columns to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS state TEXT,
ADD COLUMN IF NOT EXISTS country TEXT,
ADD COLUMN IF NOT EXISTS company TEXT,
ADD COLUMN IF NOT EXISTS government_id TEXT,
ADD COLUMN IF NOT EXISTS ca_license TEXT,
ADD COLUMN IF NOT EXISTS verification_documents TEXT[],
ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
ADD COLUMN IF NOT EXISTS profile_photo_path TEXT;

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_city ON public.users(city);
CREATE INDEX IF NOT EXISTS idx_users_state ON public.users(state);
CREATE INDEX IF NOT EXISTS idx_users_country ON public.users(country);

-- 6. Add comments to document the new fields
COMMENT ON COLUMN public.users.phone IS 'User phone number';
COMMENT ON COLUMN public.users.address IS 'User street address';
COMMENT ON COLUMN public.users.city IS 'User city';
COMMENT ON COLUMN public.users.state IS 'User state/province';
COMMENT ON COLUMN public.users.country IS 'User country';
COMMENT ON COLUMN public.users.company IS 'User company/organization';
COMMENT ON COLUMN public.users.government_id IS 'Government ID document path in storage';
COMMENT ON COLUMN public.users.ca_license IS 'CA license document path in storage';
COMMENT ON COLUMN public.users.verification_documents IS 'Array of additional verification document paths';
COMMENT ON COLUMN public.users.profile_photo_url IS 'Public URL of profile photo';
COMMENT ON COLUMN public.users.profile_photo_path IS 'Storage path of profile photo';

-- 7. Update RLS policies to allow users to update their own profile
-- (This assumes you already have RLS enabled on the users table)

-- Allow users to update their own profile information
CREATE POLICY IF NOT EXISTS "Users can update their own profile" ON public.users
FOR UPDATE USING (auth.uid()::text = id::text);

-- Allow users to select their own profile
CREATE POLICY IF NOT EXISTS "Users can select their own profile" ON public.users
FOR SELECT USING (auth.uid()::text = id::text);

-- 8. Sample data update (optional - for testing)
-- UPDATE public.users 
-- SET 
--   phone = '+1234567890',
--   address = '123 Main St',
--   city = 'New York',
--   state = 'NY',
--   country = 'USA',
--   company = 'Sample Company'
-- WHERE email = 'test@example.com';
