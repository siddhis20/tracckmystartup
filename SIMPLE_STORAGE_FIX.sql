-- =====================================================
-- SIMPLE STORAGE FIX - No table modifications
-- =====================================================
-- This approach doesn't require owner permissions

-- Check if storage buckets exist
SELECT name, public FROM storage.buckets 
WHERE name IN (
  'verification-documents',
  'startup-documents',
  'pitch-decks',
  'pitch-videos',
  'financial-documents',
  'employee-contracts'
);

-- Check current storage policies (read-only)
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;

-- Check RLS status (read-only)
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- =====================================================
-- MANUAL STEPS REQUIRED
-- =====================================================

-- Since we can't create policies via SQL, you need to:

-- 1. Go to Supabase Dashboard → Storage → Policies
-- 2. For each bucket, create these policies:

-- POLICY 1: "Allow authenticated users to upload files"
-- - Template: "Allow authenticated users to upload files"
-- - Apply to: All 6 buckets

-- POLICY 2: "Allow public access to download files"  
-- - Template: "Allow public access to download files"
-- - Apply to: All 6 buckets

-- POLICY 3: "Allow authenticated users to update files"
-- - Template: "Allow authenticated users to update files"
-- - Apply to: All 6 buckets

-- POLICY 4: "Allow authenticated users to delete files"
-- - Template: "Allow authenticated users to delete files"
-- - Apply to: All 6 buckets

-- =====================================================
-- QUICK FIX: Try this first
-- =====================================================

-- If you want to test without policies, try this:
-- Go to Storage → Settings → and temporarily disable RLS
-- (This is not recommended for production, but good for testing)

-- =====================================================
-- ALTERNATIVE: Use bucket settings
-- =====================================================

-- In the Storage dashboard:
-- 1. Click on each bucket
-- 2. Go to "Settings" tab
-- 3. Make sure "Public bucket" is checked ✅
-- 4. Set appropriate file size limits
-- 5. Set allowed MIME types if needed
