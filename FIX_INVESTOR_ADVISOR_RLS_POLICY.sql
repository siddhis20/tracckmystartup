-- Fix RLS policy for Investment Advisor to see investors who entered their code
-- The current policy is backwards - it's preventing advisors from seeing their investors

-- 1. Drop the incorrect policy
DROP POLICY IF EXISTS "Users can view their own profile" ON users;

-- 2. Create the correct policy
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (
        -- Users can see their own profile
        id = auth.uid() OR 
        -- Admins can see all users
        role = 'Admin' OR
        -- Investment Advisors can see users who entered their advisor code
        (EXISTS (
            SELECT 1 FROM users advisor 
            WHERE advisor.id = auth.uid() 
            AND advisor.role = 'Investment Advisor'
            AND advisor.investment_advisor_code = users.investment_advisor_code_entered
        ))
    );

-- 3. Verify the policy works by testing it
-- This should show all users that the current Investment Advisor can see
SELECT 
    id,
    name,
    email,
    role,
    investment_advisor_code_entered,
    advisor_accepted
FROM users 
WHERE investment_advisor_code_entered IS NOT NULL;

-- 4. Test specifically for the advisor code 'IA-926840'
SELECT 
    id,
    name,
    email,
    role,
    investment_advisor_code_entered,
    advisor_accepted
FROM users 
WHERE investment_advisor_code_entered = 'IA-926840';
