-- Check the valid enum values for user_role
-- This will help us understand what roles are available

-- 1. Check the enum type definition
SELECT '1. User role enum definition:' as info;
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname = 'user_role'
ORDER BY e.enumsortorder;

-- 2. Show current users and their roles
SELECT '2. Current users and roles:' as info;
SELECT 
    id,
    name,
    email,
    role,
    created_at
FROM users
ORDER BY created_at;

-- 3. Count users by role
SELECT '3. User count by role:' as info;
SELECT 
    role,
    COUNT(*) as user_count
FROM users
GROUP BY role
ORDER BY user_count DESC;

-- 4. Check if there are any users that might be facilitators
SELECT '4. Potential facilitator users:' as info;
SELECT 
    id,
    name,
    email,
    role,
    created_at
FROM users
WHERE name ILIKE '%facilitator%' 
   OR name ILIKE '%incubation%'
   OR name ILIKE '%program%'
   OR email ILIKE '%facilitator%'
   OR email ILIKE '%incubation%'
ORDER BY created_at;

-- 5. Show table structure for users table
SELECT '5. Users table structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'users'
AND table_schema = 'public'
ORDER BY ordinal_position;
