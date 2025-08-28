-- CHECK_AND_FIX_RLS_POLICIES.sql
-- This script checks and fixes RLS policies that might be blocking CA users from updating startups

-- 1. Check if RLS is enabled on startups table
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'startups';

-- 2. Check existing RLS policies on startups table
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

-- 3. Check if CA users can update startups
-- First, let's see what policies exist for UPDATE operations
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'startups' 
AND cmd = 'UPDATE';

-- 4. Create a policy that allows CA users to update startup compliance status
-- Use a unique name to avoid conflicts
DROP POLICY IF EXISTS "CA users can update startup compliance status" ON public.startups;

CREATE POLICY "CA users can update startup compliance status" ON public.startups
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CA'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CA'
        )
    );

-- 5. Also create a policy for CA users to SELECT startups (if they can't see them, they can't update them)
DROP POLICY IF EXISTS "CA users can view startups" ON public.startups;

CREATE POLICY "CA users can view startups" ON public.startups
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CA'
        )
    );

-- 6. Test if the policy works by checking current user context
-- (This will show what user context the policy sees)
SELECT 
    current_user,
    session_user,
    auth.uid() as auth_uid,
    auth.role() as auth_role;

-- 7. Check if there are any other constraints blocking updates
SELECT 
    conname,
    contype,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.startups'::regclass;

-- 8. Verify the startups table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name = 'compliance_status';

-- 9. Check if there are any conflicting policies on other tables
SELECT 
    schemaname,
    tablename,
    policyname
FROM pg_policies 
WHERE policyname LIKE '%compliance%' 
OR policyname LIKE '%CA%' 
OR policyname LIKE '%startup%';
