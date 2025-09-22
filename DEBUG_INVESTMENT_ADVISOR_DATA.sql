-- Debug script to check investment advisor data
-- This script will help identify why investment advisor dashboard tables are empty

-- 1. Check if investment_advisor_code column exists in users table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'investment_advisor_code';

-- 2. Check if investment_advisor_code column exists in startups table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'startups' AND column_name = 'investment_advisor_code';

-- 3. Check all users with their investment advisor codes
SELECT 
    id,
    email,
    name,
    role,
    investment_advisor_code,
    created_at
FROM users 
WHERE role IN ('Investment Advisor', 'Investor', 'Startup')
ORDER BY role, created_at DESC;

-- 4. Check all startups with their investment advisor codes
SELECT 
    id,
    name,
    user_id,
    investment_advisor_code,
    created_at
FROM startups 
ORDER BY created_at DESC;

-- 5. Check investment advisor relationships
SELECT 
    iar.id,
    iar.investment_advisor_id,
    iar.investor_id,
    iar.startup_id,
    iar.relationship_type,
    iar.created_at,
    u1.name as advisor_name,
    u1.investment_advisor_code as advisor_code,
    u2.name as investor_name,
    s.name as startup_name
FROM investment_advisor_relationships iar
LEFT JOIN users u1 ON iar.investment_advisor_id = u1.id
LEFT JOIN users u2 ON iar.investor_id = u2.id
LEFT JOIN startups s ON iar.startup_id = s.id
ORDER BY iar.created_at DESC;

-- 6. Check if there are any users with investment_advisor_code_entered field
SELECT 
    id,
    email,
    name,
    role,
    investment_advisor_code,
    investment_advisor_code_entered,
    created_at
FROM users 
WHERE investment_advisor_code_entered IS NOT NULL
ORDER BY created_at DESC;

-- 7. Sample query to find investors associated with a specific investment advisor
-- Replace 'IA-123456' with an actual investment advisor code
SELECT 
    u.id,
    u.email,
    u.name,
    u.role,
    u.investment_advisor_code_entered,
    u.created_at
FROM users u
WHERE u.role = 'Investor' 
AND u.investment_advisor_code_entered = 'IA-123456';

-- 8. Sample query to find startups associated with a specific investment advisor
-- Replace 'IA-123456' with an actual investment advisor code
SELECT 
    s.id,
    s.name,
    s.user_id,
    s.investment_advisor_code,
    s.created_at
FROM startups s
WHERE s.investment_advisor_code = 'IA-123456';
