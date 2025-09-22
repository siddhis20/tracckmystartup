-- Test Investment Advisor access to startups table
-- This will help identify if there are permission issues

-- 1. Check if the Investment Advisor user exists and has the right role
SELECT 
    id,
    name,
    email,
    role,
    investment_advisor_code,
    investment_advisor_code_entered,
    advisor_accepted,
    created_at
FROM users 
WHERE role = 'Investment Advisor' 
AND investment_advisor_code = 'INV-00C39B';

-- 2. Test direct access to startups table (this should work if permissions are correct)
SELECT 
    id,
    name,
    user_id,
    total_funding,
    sector,
    created_at
FROM startups 
ORDER BY created_at DESC 
LIMIT 5;

-- 3. Check if there are any RLS policies on the startups table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'startups';

-- 4. Check if the startups table exists and has data
SELECT 
    COUNT(*) as total_startups,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as startups_with_user_id,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as startups_without_user_id
FROM startups;

-- 5. Check if there are any startups with the specific user_id we're looking for
SELECT 
    id,
    name,
    user_id,
    total_funding,
    sector,
    created_at
FROM startups 
WHERE user_id = '5c2987d7-6b47-45ce-89d2-1c5b9181684b';

-- 6. Test the exact query that getAllStartupsForAdmin() uses
SELECT 
    s.*,
    f.id as founder_id,
    f.name as founder_name,
    f.email as founder_email
FROM startups s
LEFT JOIN founders f ON s.id = f.startup_id
ORDER BY s.created_at DESC
LIMIT 5;
