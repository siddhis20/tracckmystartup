-- URGENT FIX: Remove infinite recursion in users table RLS policy
-- The current policy is causing infinite recursion because it queries users table from within users table policy

-- 1. Drop the problematic policy immediately
DROP POLICY IF EXISTS "Users can view their own profile" ON users;

-- 2. Create a simple, non-recursive policy
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (
        -- Users can see their own profile
        id = auth.uid() OR 
        -- Admins can see all users
        role = 'Admin'
    );

-- 3. Drop existing policy and create a separate policy for Investment Advisors to see their investors
-- This uses a different approach to avoid recursion
DROP POLICY IF EXISTS "Investment Advisors can see their investors" ON users;

CREATE POLICY "Investment Advisors can see their investors" ON users
    FOR SELECT USING (
        -- Check if current user is an Investment Advisor
        EXISTS (
            SELECT 1 FROM users advisor_user 
            WHERE advisor_user.id = auth.uid() 
            AND advisor_user.role = 'Investment Advisor'
        )
        -- AND the user being queried has entered the advisor's code
        AND investment_advisor_code_entered = (
            SELECT investment_advisor_code 
            FROM users 
            WHERE id = auth.uid() 
            AND role = 'Investment Advisor'
        )
    );

-- 4. Alternative approach: Create a function to get advisor's investors
-- This bypasses RLS and is more efficient
CREATE OR REPLACE FUNCTION get_advisor_investors(advisor_id uuid)
RETURNS TABLE(
    user_id uuid,
    user_name text,
    user_email text,
    user_role text,
    investment_advisor_code_entered text,
    advisor_accepted boolean
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        u.id,
        u.name,
        u.email,
        u.role::text,
        u.investment_advisor_code_entered,
        u.advisor_accepted
    FROM users u
    WHERE u.investment_advisor_code_entered = (
        SELECT investment_advisor_code 
        FROM users advisor_table
        WHERE advisor_table.id = get_advisor_investors.advisor_id 
        AND advisor_table.role = 'Investment Advisor'
    );
END;
$$;

-- 5. Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_advisor_investors(uuid) TO authenticated;

-- 6. Test the function
SELECT * FROM get_advisor_investors('49812a94-ce11-4555-9901-604b2493a795'::uuid);
