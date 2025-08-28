-- Create storage bucket for opportunity poster images
-- Run this in Supabase SQL editor

-- Step 1: Check if storage bucket already exists
SELECT 
  'Checking existing storage buckets' as step,
  id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets 
WHERE id = 'opportunity-posters';

-- Step 2: Create storage bucket for opportunity posters
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'opportunity-posters',
  'opportunity-posters',
  true, -- public bucket for easy access
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Step 3: Create storage policies for the bucket
-- Allow authenticated users to upload poster images
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
CREATE POLICY "Allow authenticated uploads" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'opportunity-posters');

-- Allow public read access to poster images
DROP POLICY IF EXISTS "Allow public read access" ON storage.objects;
CREATE POLICY "Allow public read access" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'opportunity-posters');

-- Allow facilitators to update their own poster images
DROP POLICY IF EXISTS "Allow facilitator updates" ON storage.objects;
CREATE POLICY "Allow facilitator updates" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'opportunity-posters')
  WITH CHECK (bucket_id = 'opportunity-posters');

-- Allow facilitators to delete their own poster images
DROP POLICY IF EXISTS "Allow facilitator deletes" ON storage.objects;
CREATE POLICY "Allow facilitator deletes" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'opportunity-posters');

-- Step 4: Verify storage bucket creation
SELECT 
  'Storage bucket created successfully' as status,
  id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets 
WHERE id = 'opportunity-posters';

-- Step 5: Show all storage buckets for reference
SELECT 
  'All storage buckets' as info,
  id, name, public
FROM storage.buckets 
ORDER BY id;
