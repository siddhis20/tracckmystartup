-- =====================================================
-- MANUAL DIAGNOSTIC
-- =====================================================
-- Run this first to understand the exact state

-- 1. Check if user_id column exists
SELECT 'user_id column exists:' as check_type,
       EXISTS (
           SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'startups' AND column_name = 'user_id'
       ) as result;

-- 2. Count everything
SELECT 'startups count:' as check_type, COUNT(*) as result FROM public.startups
UNION ALL
SELECT 'users count:' as check_type, COUNT(*) as result FROM public.users
UNION ALL
SELECT 'startups with null user_id:' as check_type, COUNT(*) as result FROM public.startups WHERE user_id IS NULL;

-- 3. Show all users
SELECT 'All users:' as info;
SELECT id, email, role, created_at FROM public.users ORDER BY created_at;

-- 4. Show all startups
SELECT 'All startups:' as info;
SELECT id, name, created_at, user_id FROM public.startups ORDER BY created_at;

-- 5. Show startups with null user_id (if any)
SELECT 'Startups with null user_id:' as info;
SELECT id, name, created_at FROM public.startups WHERE user_id IS NULL;
