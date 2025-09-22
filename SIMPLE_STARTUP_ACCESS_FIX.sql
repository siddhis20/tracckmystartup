-- Simple fix for Investment Advisor startup access
-- This version uses a simpler approach to avoid type issues

-- 1. Create a policy to allow Investment Advisors to read all startups
CREATE POLICY "Investment Advisors can read startups" ON startups
FOR SELECT 
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = 'Investment Advisor'
    )
);

-- 2. Alternative approach: Create a view that Investment Advisors can access
CREATE OR REPLACE VIEW investment_advisor_startups AS
SELECT 
    s.*
FROM startups s;

-- 3. Grant access to the view for authenticated users
GRANT SELECT ON investment_advisor_startups TO authenticated;

-- 4. Test the view
SELECT * FROM investment_advisor_startups LIMIT 5;

-- 5. Verify that the Investment Advisor user exists
SELECT 
    id,
    name,
    email,
    role,
    investment_advisor_code,
    investment_advisor_code_entered,
    advisor_accepted
FROM users 
WHERE role = 'Investment Advisor' 
AND investment_advisor_code = 'INV-00C39B';
