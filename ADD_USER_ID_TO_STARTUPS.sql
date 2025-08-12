-- =====================================================
-- ADD USER_ID TO STARTUPS TABLE MIGRATION (FIXED)
-- =====================================================
-- This script adds a user_id field to the startups table
-- Run this in your Supabase SQL Editor

-- Step 1: Add user_id column to startups table (nullable initially)
ALTER TABLE public.startups 
ADD COLUMN user_id UUID REFERENCES public.users(id) ON DELETE CASCADE;

-- Step 2: Check if there are any users in the system
DO $$
DECLARE
    user_count INTEGER;
    admin_count INTEGER;
BEGIN
    -- Count total users
    SELECT COUNT(*) INTO user_count FROM public.users;
    
    -- Count admin users
    SELECT COUNT(*) INTO admin_count FROM public.users WHERE role = 'Admin';
    
    -- If no users exist, we can't proceed
    IF user_count = 0 THEN
        RAISE EXCEPTION 'No users found in the system. Please create at least one user before running this migration.';
    END IF;
    
    -- If no admin users, use the first available user
    IF admin_count = 0 THEN
        UPDATE public.startups 
        SET user_id = (SELECT id FROM public.users LIMIT 1)
        WHERE user_id IS NULL;
    ELSE
        -- Use the first admin user
        UPDATE public.startups 
        SET user_id = (SELECT id FROM public.users WHERE role = 'Admin' LIMIT 1)
        WHERE user_id IS NULL;
    END IF;
END $$;

-- Step 3: Verify all startups have a user_id assigned
DO $$
DECLARE
    null_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_count FROM public.startups WHERE user_id IS NULL;
    
    IF null_count > 0 THEN
        RAISE EXCEPTION 'There are still % startups without user_id assigned. Please check the data.', null_count;
    END IF;
END $$;

-- Step 4: Now make user_id NOT NULL
ALTER TABLE public.startups 
ALTER COLUMN user_id SET NOT NULL;

-- Step 5: Create index for better performance
CREATE INDEX idx_startups_user_id ON public.startups(user_id);

-- Step 6: Update RLS policies for startups table
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view startups" ON public.startups;
DROP POLICY IF EXISTS "Authenticated users can manage startups" ON public.startups;

-- Create new user-specific policies
CREATE POLICY "Users can view their own startups" ON public.startups
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own startups" ON public.startups
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own startups" ON public.startups
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own startups" ON public.startups
    FOR DELETE USING (auth.uid() = user_id);

-- Step 7: Enable RLS on startups table
ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if the column was added successfully
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'startups' AND column_name = 'user_id';

-- Check the new policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies 
WHERE tablename = 'startups' 
AND schemaname = 'public'
ORDER BY policyname;

-- Check RLS status
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'startups' 
AND schemaname = 'public';

-- Verify all startups have user_id assigned
SELECT COUNT(*) as total_startups, 
       COUNT(user_id) as startups_with_user_id,
       COUNT(*) - COUNT(user_id) as startups_without_user_id
FROM public.startups;
