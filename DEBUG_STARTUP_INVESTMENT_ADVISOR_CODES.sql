-- Debug script to check startup investment advisor codes
-- This script will help identify why startups aren't showing up in "My Startup Offers"

-- 1. Check if investment_advisor_code_entered column exists in startups table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name IN ('investment_advisor_code', 'investment_advisor_code_entered', 'advisor_accepted');

-- 2. Check all startups with their investment advisor codes
SELECT 
    id,
    name,
    user_id,
    investment_advisor_code,
    investment_advisor_code_entered,
    advisor_accepted,
    created_at
FROM startups 
ORDER BY created_at DESC;

-- 3. Check if there are any startups with investment advisor codes
SELECT 
    COUNT(*) as total_startups,
    COUNT(investment_advisor_code) as with_investment_advisor_code,
    COUNT(investment_advisor_code_entered) as with_investment_advisor_code_entered,
    COUNT(CASE WHEN advisor_accepted = true THEN 1 END) as accepted_by_advisor
FROM startups;

-- 4. Sample query to find startups associated with a specific investment advisor
-- Replace 'IA-123456' with an actual investment advisor code
SELECT 
    s.id,
    s.name,
    s.user_id,
    s.investment_advisor_code,
    s.investment_advisor_code_entered,
    s.advisor_accepted,
    s.created_at
FROM startups s
WHERE s.investment_advisor_code_entered = 'IA-123456'
   OR s.investment_advisor_code = 'IA-123456';

-- 5. Check the users table to see if startups have investment advisor codes there
SELECT 
    u.id,
    u.email,
    u.name,
    u.role,
    u.investment_advisor_code_entered,
    u.created_at
FROM users u
WHERE u.role = 'Startup' 
AND u.investment_advisor_code_entered IS NOT NULL;

-- 6. Compare startup data between startups and users tables
SELECT 
    'startups_table' as source,
    s.id,
    s.name,
    s.investment_advisor_code_entered,
    s.advisor_accepted
FROM startups s
WHERE s.investment_advisor_code_entered IS NOT NULL

UNION ALL

SELECT 
    'users_table' as source,
    u.id::text,
    u.name,
    u.investment_advisor_code_entered,
    NULL as advisor_accepted
FROM users u
WHERE u.role = 'Startup' 
AND u.investment_advisor_code_entered IS NOT NULL

ORDER BY name, source;
