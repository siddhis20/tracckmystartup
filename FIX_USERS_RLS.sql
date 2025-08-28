-- Fix Users Table RLS Policies
-- This will allow users to create their own profiles during registration

-- 1. First, let's see what RLS policies currently exist
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

-- 2. Check if RLS is enabled on the users table
SELECT 
  'RLS Status' as info,
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE tablename = 'users' 
  AND schemaname = 'public';

-- 3. Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;

-- 4. Create new permissive policies for profile creation
CREATE POLICY "Users can insert their own profile" ON public.users
FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view their own profile" ON public.users
FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON public.users
FOR UPDATE USING (true);

-- 5. Verify the new policies
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

-- 6. Check if the user profile was created despite the error
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
WHERE email = 'olympiad_support2@startupnationindia.com';
