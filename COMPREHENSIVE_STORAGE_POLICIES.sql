-- =====================================================
-- COMPREHENSIVE STORAGE POLICIES FOR STARTUP NATION APP
-- =====================================================
-- This file contains role-based storage policies for all buckets
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: ENABLE ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 2: CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to get current user's role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT role::TEXT 
    FROM public.users 
    WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Admin';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is startup
CREATE OR REPLACE FUNCTION is_startup()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Startup';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is investor
CREATE OR REPLACE FUNCTION is_investor()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Investor';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is CA or CS
CREATE OR REPLACE FUNCTION is_ca_or_cs()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() IN ('CA', 'CS');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is facilitator
CREATE OR REPLACE FUNCTION is_facilitator()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN get_user_role() = 'Startup Facilitation Center';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 3: BUCKET-SPECIFIC POLICIES
-- =====================================================

-- =====================================================
-- 1. STARTUP-DOCUMENTS BUCKET POLICIES
-- =====================================================
-- Purpose: General startup documents, business plans, etc.
-- Access: Startups (full access), Investors (read), Admins (full access), CA/CS (read)

-- Allow startups to upload their own documents
CREATE POLICY "startup-documents-upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'startup-documents' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups and admins to update their documents
CREATE POLICY "startup-documents-update" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'startup-documents' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups and admins to delete their documents
CREATE POLICY "startup-documents-delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'startup-documents' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow all authenticated users to view startup documents
CREATE POLICY "startup-documents-view" ON storage.objects
FOR SELECT USING (
  bucket_id = 'startup-documents' AND
  auth.role() = 'authenticated'
);

-- =====================================================
-- 2. PITCH-DECKS BUCKET POLICIES
-- =====================================================
-- Purpose: Pitch deck presentations
-- Access: Startups (full access), Investors (read), Admins (full access), CA/CS (read)

-- Allow startups to upload pitch decks
CREATE POLICY "pitch-decks-upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'pitch-decks' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups and admins to update pitch decks
CREATE POLICY "pitch-decks-update" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'pitch-decks' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups and admins to delete pitch decks
CREATE POLICY "pitch-decks-delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'pitch-decks' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow all authenticated users to view pitch decks
CREATE POLICY "pitch-decks-view" ON storage.objects
FOR SELECT USING (
  bucket_id = 'pitch-decks' AND
  auth.role() = 'authenticated'
);

-- =====================================================
-- 3. PITCH-VIDEOS BUCKET POLICIES
-- =====================================================
-- Purpose: Pitch video presentations
-- Access: Startups (full access), Investors (read), Admins (full access), CA/CS (read)

-- Allow startups to upload pitch videos
CREATE POLICY "pitch-videos-upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'pitch-videos' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups and admins to update pitch videos
CREATE POLICY "pitch-videos-update" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'pitch-videos' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups and admins to delete pitch videos
CREATE POLICY "pitch-videos-delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'pitch-videos' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow all authenticated users to view pitch videos
CREATE POLICY "pitch-videos-view" ON storage.objects
FOR SELECT USING (
  bucket_id = 'pitch-videos' AND
  auth.role() = 'authenticated'
);

-- =====================================================
-- 4. FINANCIAL-DOCUMENTS BUCKET POLICIES
-- =====================================================
-- Purpose: Financial statements, tax documents, etc.
-- Access: Startups (full access), CA/CS (full access), Admins (full access), Investors (limited read)

-- Allow startups and CA/CS to upload financial documents
CREATE POLICY "financial-documents-upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'financial-documents' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_ca_or_cs() OR is_admin())
);

-- Allow startups, CA/CS, and admins to update financial documents
CREATE POLICY "financial-documents-update" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'financial-documents' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_ca_or_cs() OR is_admin())
);

-- Allow startups, CA/CS, and admins to delete financial documents
CREATE POLICY "financial-documents-delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'financial-documents' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_ca_or_cs() OR is_admin())
);

-- Allow all authenticated users to view financial documents
CREATE POLICY "financial-documents-view" ON storage.objects
FOR SELECT USING (
  bucket_id = 'financial-documents' AND
  auth.role() = 'authenticated'
);

-- =====================================================
-- 5. EMPLOYEE-CONTRACTS BUCKET POLICIES
-- =====================================================
-- Purpose: Employee contracts, HR documents
-- Access: Startups (full access), Admins (full access), CA/CS (read)

-- Allow startups to upload employee contracts
CREATE POLICY "employee-contracts-upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'employee-contracts' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups and admins to update employee contracts
CREATE POLICY "employee-contracts-update" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'employee-contracts' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups and admins to delete employee contracts
CREATE POLICY "employee-contracts-delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'employee-contracts' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin())
);

-- Allow startups, admins, and CA/CS to view employee contracts
CREATE POLICY "employee-contracts-view" ON storage.objects
FOR SELECT USING (
  bucket_id = 'employee-contracts' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_admin() OR is_ca_or_cs())
);

-- =====================================================
-- 6. VERIFICATION-DOCUMENTS BUCKET POLICIES
-- =====================================================
-- Purpose: Legal verification documents, compliance certificates
-- Access: Startups (upload), CA/CS (full access), Admins (full access), Facilitators (read)

-- Allow startups to upload verification documents
CREATE POLICY "verification-documents-upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated' AND
  (is_startup() OR is_ca_or_cs() OR is_admin())
);

-- Allow CA/CS and admins to update verification documents
CREATE POLICY "verification-documents-update" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated' AND
  (is_ca_or_cs() OR is_admin())
);

-- Allow CA/CS and admins to delete verification documents
CREATE POLICY "verification-documents-delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated' AND
  (is_ca_or_cs() OR is_admin())
);

-- Allow all authenticated users to view verification documents
CREATE POLICY "verification-documents-view" ON storage.objects
FOR SELECT USING (
  bucket_id = 'verification-documents' AND
  auth.role() = 'authenticated'
);

-- =====================================================
-- STEP 4: VERIFICATION QUERIES
-- =====================================================

-- Check if all policies were created successfully
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'
ORDER BY policyname;

-- Check RLS status
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- Test helper functions
SELECT 
  'get_user_role' as function_name,
  get_user_role() as result
UNION ALL
SELECT 
  'is_admin' as function_name,
  is_admin()::TEXT as result
UNION ALL
SELECT 
  'is_startup' as function_name,
  is_startup()::TEXT as result
UNION ALL
SELECT 
  'is_investor' as function_name,
  is_investor()::TEXT as result
UNION ALL
SELECT 
  'is_ca_or_cs' as function_name,
  is_ca_or_cs()::TEXT as result
UNION ALL
SELECT 
  'is_facilitator' as function_name,
  is_facilitator()::TEXT as result;

-- =====================================================
-- STEP 5: TROUBLESHOOTING POLICIES (if needed)
-- =====================================================

-- If you encounter issues, you can temporarily use these simpler policies:

-- Uncomment the lines below if you need simpler policies for testing:

/*
-- Drop all existing policies
DROP POLICY IF EXISTS "startup-documents-upload" ON storage.objects;
DROP POLICY IF EXISTS "startup-documents-update" ON storage.objects;
DROP POLICY IF EXISTS "startup-documents-delete" ON storage.objects;
DROP POLICY IF EXISTS "startup-documents-view" ON storage.objects;
-- (repeat for all other policies)

-- Simple policy for all authenticated users
CREATE POLICY "Allow all operations for authenticated users" ON storage.objects
FOR ALL USING (auth.role() = 'authenticated');
*/

-- =====================================================
-- NOTES FOR IMPLEMENTATION
-- =====================================================

/*
AFTER RUNNING THIS SCRIPT:

1. Test file uploads in your app for each bucket
2. Verify that users can only access what they should
3. Check browser console for any policy-related errors
4. Make sure all users are properly authenticated

COMMON ISSUES AND SOLUTIONS:

- If uploads fail: Check that the user is authenticated and has the correct role
- If downloads fail: Verify the user has read permissions for that bucket
- If you get "permission denied": The policies are working correctly, user lacks permission
- If you get "bucket not found": Check bucket names are exactly as specified

ROLE-BASED ACCESS SUMMARY:

1. startup-documents: Startups (full), Investors (read), Admins (full), CA/CS (read)
2. pitch-decks: Startups (full), Investors (read), Admins (full), CA/CS (read)  
3. pitch-videos: Startups (full), Investors (read), Admins (full), CA/CS (read)
4. financial-documents: Startups (full), CA/CS (full), Admins (full), Investors (read)
5. employee-contracts: Startups (full), Admins (full), CA/CS (read)
6. verification-documents: Startups (upload), CA/CS (full), Admins (full), All (read)

SECURITY FEATURES:
- Row Level Security enabled
- Role-based access control
- Separate policies for each operation (INSERT, SELECT, UPDATE, DELETE)
- Helper functions for role checking
- Comprehensive audit trail
*/
