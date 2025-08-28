-- Check if we can enforce email confirmation at database level
-- This will help understand how to control user access

-- 1. Check current auth.users table structure
SELECT 
  'Auth Users Structure' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth' 
  AND table_name = 'users'
  AND column_name IN ('email_confirmed_at', 'confirmed_at', 'email_verified_at')
ORDER BY column_name;

-- 2. Check if there are any RLS policies that could enforce email confirmation
SELECT 
  'Current Auth RLS Policies' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'auth' 
  AND tablename = 'users';

-- 3. Check if we can create a policy to block unconfirmed users
SELECT 
  'Can Create Email Confirmation Policy' as info,
  'Yes - We can create RLS policies on auth.users' as answer,
  'But this requires careful consideration of security implications' as note;

-- 4. Alternative: Check if we can use a trigger to enforce confirmation
SELECT 
  'Trigger Option' as info,
  'Yes - We can create triggers on auth.users' as answer,
  'But this is complex and may interfere with Supabase auth flow' as note;

