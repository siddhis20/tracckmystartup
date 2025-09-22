-- Fix Investment Advisor access to startups table
-- This script addresses the permission issue preventing Investment Advisors from seeing startups

-- 1. First, let's check the current RLS policies on the startups table
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

-- 2. Check if RLS is enabled on the startups table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'startups';

-- 3. Create a policy to allow Investment Advisors to read all startups
-- This policy allows Investment Advisors to SELECT from the startups table
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

-- 4. Alternative approach: Create a function that Investment Advisors can call
-- This function bypasses RLS and returns all startups
CREATE OR REPLACE FUNCTION get_startups_for_investment_advisor()
RETURNS TABLE(
    id integer,
    name text,
    user_id uuid,
    total_funding numeric,
    sector text,
    created_at timestamp with time zone,
    investment_type text,
    investment_value numeric,
    equity_allocation numeric,
    current_valuation numeric,
    compliance_status text,
    total_revenue numeric,
    registration_date date
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        s.id,
        s.name,
        s.user_id,
        s.total_funding,
        s.sector,
        s.created_at,
        s.investment_type,
        s.investment_value,
        s.equity_allocation,
        s.current_valuation,
        s.compliance_status,
        s.total_revenue,
        s.registration_date
    FROM startups s;
END;
$$;

-- 5. Grant execute permission on the function to authenticated users
GRANT EXECUTE ON FUNCTION get_startups_for_investment_advisor() TO authenticated;

-- 6. Test the function to make sure it works
SELECT * FROM get_startups_for_investment_advisor() LIMIT 5;

-- 7. Verify that the Investment Advisor user exists and has the right role
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

-- 8. Test direct access to startups table (should work after policy is created)
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
