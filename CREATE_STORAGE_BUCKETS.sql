-- CREATE_STORAGE_BUCKETS.sql
-- Run these commands in Supabase Dashboard → SQL Editor

-- Step 1: Create the storage buckets
-- Go to Supabase Dashboard → Storage → Create a new bucket

-- Bucket 1: verification-documents
-- Name: verification-documents
-- Public bucket: Yes
-- File size limit: 50 MB

-- Bucket 2: startup-documents  
-- Name: startup-documents
-- Public bucket: Yes
-- File size limit: 50 MB

-- Bucket 3: pitch-decks
-- Name: pitch-decks
-- Public bucket: Yes
-- File size limit: 100 MB

-- Bucket 4: financial-documents
-- Name: financial-documents
-- Public bucket: Yes
-- File size limit: 50 MB

-- Step 2: Create storage policies (after buckets are created)
-- Go to Supabase Dashboard → Storage → Policies

-- For each bucket, create this policy:
/*
Policy Name: Allow authenticated users to upload
Target roles: authenticated
Policy definition: 
(auth.role() = 'authenticated')

Policy Name: Allow public read access
Target roles: public  
Policy definition:
(true)
*/

-- Step 3: Test the connection
-- Use the Storage Test button in the app to verify everything works
