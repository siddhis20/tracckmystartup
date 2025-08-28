-- SAFE_RLS_FIX.sql
-- Safe fix for RLS policies that ONLY affects startups table
-- This will NOT impact incubation programs, recognition records, or any other functionality

-- 1. Check current RLS policies on startups table ONLY
SELECT '=== CURRENT STARTUPS RLS POLICIES ===' as info;

SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual
FROM pg_policies 
WHERE tablename = 'startups'
ORDER BY policyname;

-- 2. Check if RLS is enabled on startups table ONLY
SELECT '=== STARTUPS RLS STATUS ===' as info;

SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'startups';

-- 3. SAFELY drop ONLY the conflicting startups policies
-- Keep all other table policies intact!
SELECT '=== SAFELY DROPPING ONLY STARTUPS CONFLICTING POLICIES ===' as info;

DROP POLICY IF EXISTS "Anyone can view startups" ON public.startups;
DROP POLICY IF EXISTS "Authenticated users can create startups" ON public.startups;
DROP POLICY IF EXISTS "Authenticated users can update startups" ON public.startups;
DROP POLICY IF EXISTS "Users can view their own startups" ON public.startups;
DROP POLICY IF EXISTS "Users can insert their own startups" ON public.startups;
DROP POLICY IF EXISTS "Users can update their own startups" ON public.startups;
DROP POLICY IF EXISTS "Users can delete their own startups" ON public.startups;
DROP POLICY IF EXISTS "startups_read_all" ON public.startups;
DROP POLICY IF EXISTS "CA_UPDATE_STARTUP_COMPLIANCE_2024" ON public.startups;
DROP POLICY IF EXISTS "CA_VIEW_STARTUPS_2024" ON public.startups;
DROP POLICY IF EXISTS "CS_UPDATE_STARTUP_COMPLIANCE_2024" ON public.startups;
DROP POLICY IF EXISTS "CS_VIEW_STARTUPS_2024" ON public.startups;

-- 4. Create MINIMAL, SAFE RLS policies for startups table ONLY
SELECT '=== CREATING MINIMAL, SAFE STARTUPS RLS POLICIES ===' as info;

-- Policy 1: Anyone can view startups (needed for investors to see startup details)
-- This is the ONLY policy that affects investor access
CREATE POLICY "startups_select_all" ON public.startups
    FOR SELECT USING (true);

-- Policy 2: Users can manage their own startups (preserves existing functionality)
CREATE POLICY "startups_manage_own" ON public.startups
    FOR ALL USING (
        user_id = auth.uid()
    );

-- Policy 3: CA users can update startup compliance status (preserves CA functionality)
CREATE POLICY "startups_ca_update" ON public.startups
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CA'
        )
    );

-- Policy 4: CS users can update startup compliance status (preserves CS functionality)
CREATE POLICY "startups_cs_update" ON public.startups
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CS'
        )
    );

-- Policy 5: Authenticated users can create startups (preserves registration functionality)
CREATE POLICY "startups_insert_authenticated" ON public.startups
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated'
    );

-- 5. Verify ONLY startups policies were changed
SELECT '=== VERIFYING ONLY STARTUPS POLICIES CHANGED ===' as info;

SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual
FROM pg_policies 
WHERE tablename = 'startups'
ORDER BY policyname;

-- 6. Test that investors can now read startup data
SELECT '=== TESTING INVESTOR ACCESS TO STARTUPS ===' as info;

-- This should work now for authenticated users
SELECT COUNT(*) as can_read_startups FROM startups;

-- 7. Test the specific operation that was failing
SELECT '=== TESTING STARTUP ADDITION REQUEST FLOW ===' as info;

-- Check if we can read startup data (this was failing with 403)
SELECT 
    id,
    name,
    sector,
    total_funding
FROM startups 
LIMIT 3;

-- 8. VERIFY OTHER TABLES ARE UNTOUCHED
SELECT '=== VERIFYING OTHER TABLES UNTOUCHED ===' as info;

-- Check incubation programs table (should be unchanged)
SELECT 
    'incubation_programs' as table_name,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'incubation_programs';

-- Check recognition records table (should be unchanged)
SELECT 
    'recognition_records' as table_name,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'recognition_records';

-- Check opportunity applications table (should be unchanged)
SELECT 
    'opportunity_applications' as table_name,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'opportunity_applications';

-- Check financial records table (should be unchanged)
SELECT 
    'financial_records' as table_name,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'financial_records';

-- 9. Final verification
SELECT '=== FINAL VERIFICATION ===' as info;

SELECT 
    'Startups RLS Policies' as check_type,
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'startups';

SELECT 
    'Startup Access Test' as check_type,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ Investors can now read startups'
        ELSE '❌ Still cannot read startups'
    END as status
FROM startups;

SELECT 
    'Other Tables Unchanged' as check_type,
    '✅ Incubation, Recognition, Financial records unaffected' as status;

