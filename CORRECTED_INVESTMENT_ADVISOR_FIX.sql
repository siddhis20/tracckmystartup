-- Corrected fix for Investment Advisor startup access
-- This version uses the correct column types from the startups table

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

-- 2. Create a function that Investment Advisors can call to get all startups
-- Using generic types to avoid type mismatch issues
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
        s.investment_type::text,  -- Cast to text to ensure type compatibility
        s.investment_value,
        s.equity_allocation,
        s.current_valuation,
        s.compliance_status::text,  -- Cast to text to ensure type compatibility
        s.total_revenue,
        s.registration_date
    FROM startups s;
END;
$$;

-- 3. Grant execute permission on the function to authenticated users
GRANT EXECUTE ON FUNCTION get_startups_for_investment_advisor() TO authenticated;

-- 4. Test the function to make sure it works
SELECT * FROM get_startups_for_investment_advisor() LIMIT 5;

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
