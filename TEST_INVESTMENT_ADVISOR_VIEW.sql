-- Test if the investment_advisor_startups view exists and works

-- 1. Check if the view exists
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'investment_advisor_startups';

-- 2. Test the view directly
SELECT * FROM investment_advisor_startups LIMIT 5;

-- 3. Check if the RLS policy is working
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
WHERE tablename = 'startups' 
AND policyname = 'Investment Advisors can read startups';

-- 4. Test direct access to startups table (should work with the policy)
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
