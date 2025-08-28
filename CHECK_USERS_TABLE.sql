-- Check Users Table Structure
-- Run this in Supabase SQL Editor to see what columns actually exist

-- 1. Check all columns in users table
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- 2. Check if verification document columns exist
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'government_id'
    ) THEN 'government_id column EXISTS'
    ELSE 'government_id column DOES NOT EXIST'
  END as government_id_status,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'ca_license'
    ) THEN 'ca_license column EXISTS'
    ELSE 'ca_license column DOES NOT EXIST'
  END as ca_license_status,
  
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'verification_documents'
    ) THEN 'verification_documents column EXISTS'
    ELSE 'verification_documents column DOES NOT EXIST'
  END as verification_documents_status;

-- 3. Check sample user data (without sensitive info)
SELECT 
  id,
  email,
  name,
  role,
  created_at
FROM public.users 
LIMIT 5;

