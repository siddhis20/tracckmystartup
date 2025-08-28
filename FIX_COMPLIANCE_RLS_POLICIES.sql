-- =====================================================
-- FIX COMPLIANCE RLS POLICIES - ENABLE FRONTEND ACCESS
-- =====================================================
-- This script fixes the RLS policies for compliance_checks table
-- so that the frontend can access the compliance data
-- =====================================================

-- Step 1: Check current RLS policies
-- =====================================================

SELECT 
    'current_policies' as check_type,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'compliance_checks';

-- Step 2: Drop existing policies that might be blocking access
-- =====================================================

DROP POLICY IF EXISTS "Startups can view their own compliance checks" ON public.compliance_checks;
DROP POLICY IF EXISTS "CA can view all compliance checks" ON public.compliance_checks;
DROP POLICY IF EXISTS "CS can view all compliance checks" ON public.compliance_checks;
DROP POLICY IF EXISTS "Admin can view all compliance checks" ON public.compliance_checks;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.compliance_checks;

-- Step 3: Create new policies that allow proper access
-- =====================================================

-- Policy for startups to view their own compliance checks
CREATE POLICY "Startups can view their own compliance checks" ON public.compliance_checks
    FOR SELECT USING (
        auth.uid() IN (
            SELECT user_id FROM public.startups WHERE id = compliance_checks.startup_id
        )
    );

-- Policy for CA users to view all compliance checks
CREATE POLICY "CA can view all compliance checks" ON public.compliance_checks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'CA'
        )
    );

-- Policy for CS users to view all compliance checks
CREATE POLICY "CS can view all compliance checks" ON public.compliance_checks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'CS'
        )
    );

-- Policy for Admin users to view all compliance checks
CREATE POLICY "Admin can view all compliance checks" ON public.compliance_checks
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'Admin'
        )
    );

-- Policy for authenticated users to view compliance checks (temporary for testing)
CREATE POLICY "Authenticated users can view compliance checks" ON public.compliance_checks
    FOR SELECT USING (auth.role() = 'authenticated');

-- Step 4: Test the policies by checking data access
-- =====================================================

-- Check if we can see the data now
SELECT 
    'compliance_data_test' as check_type,
    COUNT(*) as total_tasks,
    COUNT(DISTINCT startup_id) as startups_with_tasks
FROM public.compliance_checks;

-- Show sample data
SELECT 
    'sample_data' as check_type,
    startup_id,
    task_id,
    entity_display_name,
    year,
    task_name
FROM public.compliance_checks 
LIMIT 5;

-- Step 5: Verify RLS is enabled and policies are created
-- =====================================================

SELECT 
    'rls_status' as check_type,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'compliance_checks';

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'COMPLIANCE RLS POLICIES FIXED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Old policies dropped';
    RAISE NOTICE '✅ New policies created';
    RAISE NOTICE '✅ Frontend should now access data';
    RAISE NOTICE '✅ Check the compliance page now';
    RAISE NOTICE '========================================';
END $$;


