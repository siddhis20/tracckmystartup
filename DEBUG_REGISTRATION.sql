-- Debug Registration Process - Check what's happening
-- Run this to see the current state and debug the issue

-- 1. Check if the user exists in auth.users
SELECT 
  'Auth Users Check' as info,
  id,
  email,
  created_at,
  email_confirmed_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'olympiad_support1@startupnationindia.com';

-- 2. Check if the user exists in public.users
SELECT 
  'Public Users Check' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at,
  updated_at
FROM public.users 
WHERE email = 'olympiad_support1@startupnationindia.com';

-- 3. Check if there are any recent profile creation attempts
SELECT 
  'Recent Profile Creation Attempts' as info,
  id,
  email,
  name,
  role,
  government_id,
  ca_license,
  verification_documents,
  created_at
FROM public.users 
ORDER BY created_at DESC
LIMIT 5;

-- 4. Check if there are any database errors or constraints
SELECT 
  'Table Constraints' as info,
  conname,
  contype,
  constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass;

-- 5. Check if the columns exist and their types
SELECT 
  'Column Information' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
  AND column_name IN ('government_id', 'ca_license', 'verification_documents')
ORDER BY column_name;

-- 6. Check if there are any triggers that might be interfering
SELECT 
  'Table Triggers' as info,
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users'
  AND event_object_schema = 'public';
