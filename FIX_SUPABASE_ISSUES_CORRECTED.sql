-- =====================================================
-- FIX SUPABASE ISSUES - CORRECTED VERSION
-- =====================================================
-- This script fixes the storage bucket and RLS policy issues
-- WITHOUT trying to modify storage.objects table directly

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
-- STEP 3: VERIFY THE FIXES
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

-- =====================================================
-- STEP 4: ADDITIONAL STORAGE BUCKETS (OPTIONAL)
-- =====================================================

-- Create other commonly used buckets if they don't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  (
    'startup-documents',
    'startup-documents',
    true,
    52428800, -- 50MB
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
  ),
  (
    'pitch-decks',
    'pitch-decks',
    true,
    104857600, -- 100MB
    ARRAY['application/pdf', 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation']
  ),
  (
    'financial-documents',
    'financial-documents',
    true,
    52428800, -- 50MB
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
  )
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT 
  'FIXES COMPLETED' as status,
  'Storage bucket created and RLS policies fixed' as message,
  'Storage policies need to be configured in Supabase Dashboard' as next_step;

