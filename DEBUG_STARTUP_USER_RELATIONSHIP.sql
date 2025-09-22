-- Debug startup-user relationship for Investment Advisor workflow
-- This query helps identify why startups might not be showing up in the Investment Advisor dashboard

-- 1. Check all startup users and their investment advisor codes
SELECT 
    u.id as user_id,
    u.name as user_name,
    u.email as user_email,
    u.role,
    u.investment_advisor_code_entered,
    u.advisor_accepted,
    u.created_at as user_created_at
FROM users u
WHERE u.role = 'Startup'
ORDER BY u.created_at DESC;

-- 2. Check all startups and their user relationships
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.user_id,
    s.total_funding,
    s.sector,
    s.created_at as startup_created_at
FROM startups s
ORDER BY s.created_at DESC;

-- 3. Check startup-user relationships for users with investment advisor codes
SELECT 
    u.id as user_id,
    u.name as user_name,
    u.email as user_email,
    u.investment_advisor_code_entered,
    u.advisor_accepted,
    s.id as startup_id,
    s.name as startup_name,
    s.total_funding,
    s.sector
FROM users u
LEFT JOIN startups s ON u.id = s.user_id
WHERE u.role = 'Startup' 
AND u.investment_advisor_code_entered IS NOT NULL
ORDER BY u.created_at DESC;

-- 4. Check specifically for the Investment Advisor code 'INV-00C39B'
SELECT 
    u.id as user_id,
    u.name as user_name,
    u.email as user_email,
    u.investment_advisor_code_entered,
    u.advisor_accepted,
    s.id as startup_id,
    s.name as startup_name,
    s.total_funding,
    s.sector,
    CASE 
        WHEN s.id IS NULL THEN 'NO STARTUP FOUND'
        ELSE 'STARTUP FOUND'
    END as startup_status
FROM users u
LEFT JOIN startups s ON u.id = s.user_id
WHERE u.role = 'Startup' 
AND u.investment_advisor_code_entered = 'INV-00C39B'
ORDER BY u.created_at DESC;

-- 5. Check if there are any startups without proper user relationships
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.user_id,
    u.id as user_id_found,
    u.name as user_name,
    u.role as user_role,
    CASE 
        WHEN u.id IS NULL THEN 'ORPHANED STARTUP - NO USER FOUND'
        WHEN u.role != 'Startup' THEN 'WRONG USER ROLE'
        ELSE 'VALID RELATIONSHIP'
    END as relationship_status
FROM startups s
LEFT JOIN users u ON s.user_id = u.id
WHERE u.id IS NULL OR u.role != 'Startup'
ORDER BY s.created_at DESC;
