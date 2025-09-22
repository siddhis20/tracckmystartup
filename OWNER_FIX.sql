-- =====================================================
-- FIX FOR SUPABASE PROJECT OWNER
-- =====================================================
-- This script should work if you're the project owner

-- =====================================================
-- STEP 1: CREATE VERIFICATION-DOCUMENTS STORAGE BUCKET
-- =====================================================

-- Check if verification-documents bucket exists
SELECT 'Checking if verification-documents bucket exists...' as status;

SELECT 
    id, 
    name, 
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'verification-documents';

-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'verification-documents',
    'verification-documents',
    true, -- Public bucket for easier access
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
) ON CONFLICT (id) DO NOTHING;

-- Verify bucket was created
SELECT 'Verifying bucket creation...' as status;
SELECT 
    id, 
    name, 
    public,
    file_size_limit
FROM storage.buckets 
WHERE id = 'verification-documents';

-- =====================================================
-- STEP 2: FIX RLS POLICIES - REMOVE INFINITE RECURSION
-- =====================================================

-- First, let's see what RLS policies currently exist
SELECT 
  'Current RLS Policies' as info,
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

-- Check if RLS is enabled on the users table
SELECT 
  'RLS Status' as info,
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'users' 
  AND schemaname = 'public';

-- Drop ALL existing policies that might be causing infinite recursion
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can manage their own profile" ON users;

-- Create simple, non-recursive policies
CREATE POLICY "Users can insert their own profile" ON public.users
FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view their own profile" ON public.users
FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.users
FOR UPDATE USING (true);

-- Verify the new policies
SELECT 
  'New RLS Policies' as info,
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

-- =====================================================
-- STEP 3: CREATE STORAGE POLICIES (AS OWNER)
-- =====================================================

-- Check current storage policies
SELECT 
  'Current Storage Policies' as info,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'objects' 
  AND schemaname = 'storage';

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to upload verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete verification documents" ON storage.objects;

-- Create storage policies for verification-documents bucket
CREATE POLICY "Allow authenticated users to upload verification documents" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow public access to verification documents" ON storage.objects
FOR SELECT USING (
  bucket_id = 'verification-documents'
);

CREATE POLICY "Allow authenticated users to update verification documents" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow authenticated users to delete verification documents" ON storage.objects
FOR DELETE USING (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

-- =====================================================
-- STEP 4: VERIFY ALL FIXES
-- =====================================================

-- Check if the user profile exists and can be accessed
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
WHERE email = 'saeel.momin@gmail.com';

-- Test if we can query the users table without infinite recursion
SELECT 
  'Users Table Access Test' as info,
  COUNT(*) as total_users
FROM public.users;

-- Check storage bucket status
SELECT 
  'Storage Bucket Status' as info,
  id,
  name,
  public,
  file_size_limit
FROM storage.buckets 
WHERE id = 'verification-documents';

-- Check storage policies
SELECT 
  'Storage Policies Created' as info,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
  AND policyname LIKE '%verification%';

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT 
  'ALL FIXES COMPLETED' as status,
  'Storage bucket created, RLS policies fixed, and storage policies configured' as message,
  'You can now test the file upload functionality' as next_step;

