-- Test startup fetching for Investment Advisor
-- This query simulates what getAllStartupsForAdmin() should return

-- 1. Check if there are any startups in the database
SELECT 
    COUNT(*) as total_startups,
    MIN(created_at) as earliest_startup,
    MAX(created_at) as latest_startup
FROM startups;

-- 2. Get all startups with founders (same as getAllStartupsForAdmin)
SELECT 
    s.id,
    s.name,
    s.user_id,
    s.total_funding,
    s.sector,
    s.created_at,
    f.id as founder_id,
    f.name as founder_name,
    f.email as founder_email
FROM startups s
LEFT JOIN founders f ON s.id = f.startup_id
ORDER BY s.created_at DESC;

-- 3. Check specifically for Farah's startup
SELECT 
    s.id,
    s.name,
    s.user_id,
    s.total_funding,
    s.sector,
    s.created_at,
    u.id as user_id_from_users,
    u.name as user_name,
    u.email as user_email,
    u.role as user_role
FROM startups s
LEFT JOIN users u ON s.user_id = u.id
WHERE s.user_id = '5c2987d7-6b47-45ce-89d2-1c5b9181684b'
ORDER BY s.created_at DESC;

-- 4. Check if there are any RLS (Row Level Security) policies that might be blocking access
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

-- 5. Check if the Investment Advisor user has the right permissions
SELECT 
    u.id,
    u.name,
    u.email,
    u.role,
    u.investment_advisor_code,
    u.investment_advisor_code_entered,
    u.advisor_accepted
FROM users u
WHERE u.role = 'Investment Advisor'
AND u.investment_advisor_code = 'INV-00C39B';
