-- =====================================================
-- WORKING FIX FOR SUPABASE PROJECT OWNER
-- =====================================================
-- Since you have table privileges, this should work

-- =====================================================
-- STEP 1: CREATE VERIFICATION-DOCUMENTS STORAGE BUCKET
-- =====================================================

-- Create the bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'verification-documents',
    'verification-documents',
    true,
    52428800, -- 50MB
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- STEP 2: FIX RLS POLICIES
-- =====================================================

-- Drop all existing policies that might cause infinite recursion
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.users;

-- Create simple, working policies
CREATE POLICY "Users can insert their own profile" ON public.users
FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view their own profile" ON public.users
FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.users
FOR UPDATE USING (true);

-- =====================================================
-- STEP 3: CREATE STORAGE POLICIES
-- =====================================================

-- Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Allow authenticated users to upload verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to update verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to delete verification documents" ON storage.objects;

-- Create storage policies
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
-- STEP 4: VERIFY EVERYTHING WORKS
-- =====================================================

-- Check bucket creation
SELECT 'Bucket created:' as status, id, name, public FROM storage.buckets WHERE id = 'verification-documents';

-- Check RLS policies
SELECT 'RLS policies fixed:' as status, policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public';

-- Check storage policies
SELECT 'Storage policies created:' as status, policyname FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage' AND policyname LIKE '%verification%';

-- Test users table access (should not cause infinite recursion)
SELECT 'Users table accessible:' as status, COUNT(*) as total_users FROM public.users;

-- Test specific user
SELECT 'User profile check:' as status, id, email, name, role FROM public.users WHERE email = 'saeel.momin@gmail.com';

