    -- SIMPLE_CA_UPDATE_FIX.sql
    -- Simple fix for CA users to update startup compliance status

    -- 1. First, let's see what policies currently exist
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

    -- 3. Create a simple policy for CA users to update startups
    -- Use a very unique name to avoid conflicts
    DROP POLICY IF EXISTS "CA_UPDATE_STARTUP_COMPLIANCE_2024" ON public.startups;

    CREATE POLICY "CA_UPDATE_STARTUP_COMPLIANCE_2024" ON public.startups
        FOR UPDATE USING (
            EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid() 
                AND role = 'CA'
            )
        );

    -- 4. Also ensure CA users can view startups
    DROP POLICY IF EXISTS "CA_VIEW_STARTUPS_2024" ON public.startups;

    CREATE POLICY "CA_VIEW_STARTUPS_2024" ON public.startups
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM public.users 
                WHERE id = auth.uid() 
                AND role = 'CA'
            )
        );

    -- 5. Test the current user context
    SELECT 
        current_user,
        session_user;

    -- 6. Verify the policy was created
    SELECT 
        tablename,
        policyname,
        cmd,
        permissive
    FROM pg_policies 
    WHERE tablename = 'startups' 
    AND policyname LIKE '%2024%';
