-- Simple script to add cs_license column to users table
-- Run this in Supabase SQL Editor

-- Step 1: Add the column (simple version)
ALTER TABLE public.users ADD COLUMN cs_license TEXT;

-- Step 2: Verify the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'cs_license';
