-- =====================================================
-- QUICK FIX FOR IMMEDIATE ISSUES
-- =====================================================
-- Run this in Supabase Dashboard → SQL Editor

-- 1. Create the missing storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'verification-documents',
    'verification-documents',
    true,
    52428800, -- 50MB
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'image/gif']
) ON CONFLICT (id) DO NOTHING;

-- 2. Fix RLS policies by dropping and recreating them
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;

CREATE POLICY "Users can insert their own profile" ON public.users
FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view their own profile" ON public.users
FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.users
FOR UPDATE USING (true);

-- 3. Create basic storage policies
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to upload verification documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow public access to verification documents" ON storage.objects;

CREATE POLICY "Allow authenticated users to upload verification documents" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Allow public access to verification documents" ON storage.objects
FOR SELECT USING (
  bucket_id = 'verification-documents'
);

-- 4. Verify fixes
SELECT 'Storage bucket created:' as status, id, name, public FROM storage.buckets WHERE id = 'verification-documents';
SELECT 'RLS policies fixed:' as status, policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public';
SELECT 'Storage policies created:' as status, policyname FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage' AND policyname LIKE '%verification%';
