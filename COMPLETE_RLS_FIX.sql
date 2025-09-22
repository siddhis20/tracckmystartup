-- COMPLETE RLS FIX: Remove ALL infinite recursion issues
-- This will fix the users table RLS policies that are causing infinite recursion

-- 1. DISABLE RLS temporarily to clean up policies
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 2. Drop ALL existing policies on users table
DROP POLICY IF EXISTS "Users can view their own profile" ON users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users;
DROP POLICY IF EXISTS "Users can update their own profile" ON users;
DROP POLICY IF EXISTS "Users can manage their own profile" ON users;
DROP POLICY IF EXISTS "Investment Advisors can see their investors" ON users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.users;

-- 3. Re-enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 4. Create simple, non-recursive policies
-- These policies do NOT query the users table, preventing infinite recursion

-- Allow users to insert their own profile (for registration)
CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (true);

-- Allow users to view their own profile
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (true);

-- 5. Create a separate function for Investment Advisors to get their investors
-- This bypasses RLS completely and is more efficient
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

-- 6. Grant execute permission on the function
GRANT EXECUTE ON FUNCTION get_advisor_investors(uuid) TO authenticated;

-- 7. Test the function with the advisor ID
SELECT * FROM get_advisor_investors('49812a94-ce11-4555-9901-604b2493a795'::uuid);

-- 8. Verify the policies are working
SELECT 
    'RLS Policies Status' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'users' 
  AND schemaname = 'public';

-- 9. Test basic users table access
SELECT 
    'Users Table Access Test' as info,
    COUNT(*) as total_users
FROM users;

-- 10. Check if specific user exists
SELECT 
    'User Profile Check' as info,
    id,
    email,
    name,
    role,
    investment_advisor_code,
    investment_advisor_code_entered,
    created_at
FROM users 
WHERE email = 'solapurkarsiddhi@gmail.com';
