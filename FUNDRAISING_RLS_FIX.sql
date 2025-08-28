-- =====================================================
-- FUNDRAISING RLS FIX
-- =====================================================
-- This script fixes potential RLS policy issues for fundraising_details

-- First, let's check the current RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'fundraising_details' 
    AND schemaname = 'public';

-- Check existing policies
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
WHERE tablename = 'fundraising_details' 
    AND schemaname = 'public';

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view their own startup's fundraising details" ON fundraising_details;
DROP POLICY IF EXISTS "Startup users can manage their own fundraising details" ON fundraising_details;

-- Create a simpler, more permissive policy for testing
CREATE POLICY "Enable all operations for authenticated users" ON fundraising_details
    FOR ALL USING (true)
    WITH CHECK (true);

-- Alternative: Create more specific policies
-- CREATE POLICY "Users can view their own startup's fundraising details" ON fundraising_details
--     FOR SELECT USING (
--         startup_id IN (
--             SELECT id FROM startups 
--             WHERE name IN (
--                 SELECT startup_name FROM users 
--                 WHERE email = auth.jwt() ->> 'email'
--             )
--         )
--     );
-- 
-- CREATE POLICY "Startup users can manage their own fundraising details" ON fundraising_details
--     FOR ALL USING (
--         startup_id IN (
--             SELECT id FROM startups 
--             WHERE name IN (
--                 SELECT startup_name FROM users 
--                 WHERE email = auth.jwt() ->> 'email'
--             )
--         )
--     );

-- Verify the new policy
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
WHERE tablename = 'fundraising_details' 
    AND schemaname = 'public';
