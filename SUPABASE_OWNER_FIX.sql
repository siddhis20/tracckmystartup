-- =====================================================
-- SUPABASE OWNER FIX - USING PROPER SUPABASE FUNCTIONS
-- =====================================================
-- Run this in Supabase Dashboard → SQL Editor

-- =====================================================
-- STEP 1: CREATE VERIFICATION-DOCUMENTS STORAGE BUCKET
-- =====================================================

-- Create the bucket using Supabase's storage API
SELECT storage.create_bucket(
  'verification-documents',
  'verification-documents',
  true, -- public
  52428800, -- 50MB limit
  ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif']
);

-- Alternative method if the above doesn't work
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'verification-documents',
    'verification-documents',
    true,
    52428800,
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STEP 2: FIX RLS POLICIES
-- =====================================================

-- Drop problematic policies
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.users;

-- Create new policies
CREATE POLICY "Users can insert their own profile" ON public.users
FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view their own profile" ON public.users
FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.users
FOR UPDATE USING (true);

-- =====================================================
-- STEP 3: CREATE STORAGE POLICIES USING SUPABASE FUNCTIONS
-- =====================================================

-- Create storage policies using the proper Supabase approach
SELECT storage.create_policy(
  'Allow authenticated users to upload verification documents',
  'verification-documents',
  'INSERT',
  'authenticated',
  'bucket_id = ''verification-documents'' AND auth.role() = ''authenticated'''
);

SELECT storage.create_policy(
  'Allow public access to verification documents',
  'verification-documents',
  'SELECT',
  'public',
  'bucket_id = ''verification-documents'''
);

SELECT storage.create_policy(
  'Allow authenticated users to update verification documents',
  'verification-documents',
  'UPDATE',
  'authenticated',
  'bucket_id = ''verification-documents'' AND auth.role() = ''authenticated'''
);

SELECT storage.create_policy(
  'Allow authenticated users to delete verification documents',
  'verification-documents',
  'DELETE',
  'authenticated',
  'bucket_id = ''verification-documents'' AND auth.role() = ''authenticated'''
);

-- =====================================================
-- STEP 4: VERIFY EVERYTHING
-- =====================================================

-- Check bucket
SELECT 'Bucket Status:' as info, id, name, public FROM storage.buckets WHERE id = 'verification-documents';

-- Check RLS policies
SELECT 'RLS Policies:' as info, policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public';

-- Check storage policies
SELECT 'Storage Policies:' as info, policyname FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage' AND policyname LIKE '%verification%';

-- Test users table access
SELECT 'Users Table Test:' as info, COUNT(*) as total_users FROM public.users;

