-- CS_RLS_POLICIES.sql
-- Create RLS policies for CS users to update startup compliance status

-- 1. Check existing RLS policies on startups table
SELECT 
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'startups';

-- 2. Check if RLS is enabled
SELECT 
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'startups';

-- 3. Create policy for CS users to update startups
-- Use unique names to avoid conflicts
DROP POLICY IF EXISTS "CS_UPDATE_STARTUP_COMPLIANCE_2024" ON public.startups;

CREATE POLICY "CS_UPDATE_STARTUP_COMPLIANCE_2024" ON public.startups
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CS'
        )
    );

-- 4. Also ensure CS users can view startups
DROP POLICY IF EXISTS "CS_VIEW_STARTUPS_2024" ON public.startups;

CREATE POLICY "CS_VIEW_STARTUPS_2024" ON public.startups
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CS'
        )
    );

-- 5. Test the current user context
SELECT 
    current_user,
    session_user;

-- 6. Verify the policies were created
SELECT 
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'startups' 
AND policyname LIKE '%2024%';

-- 7. Check if there are any other constraints blocking updates
SELECT 
    conname,
    contype,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.startups'::regclass;
