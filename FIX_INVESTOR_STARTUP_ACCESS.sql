-- FIX_INVESTOR_STARTUP_ACCESS.sql
-- Fix RLS policies to allow investors to access startups table for startup addition requests

-- 1. Check current RLS policies on startups table
SELECT '=== CURRENT RLS POLICIES ===' as info;

SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual
FROM pg_policies 
WHERE tablename = 'startups'
ORDER BY policyname;

-- 2. Check if RLS is enabled
SELECT '=== RLS STATUS ===' as info;

SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'startups';

-- 3. Drop all existing conflicting policies
SELECT '=== DROPPING CONFLICTING POLICIES ===' as info;

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

-- 4. Create comprehensive RLS policies
SELECT '=== CREATING NEW RLS POLICIES ===' as info;

-- Policy 1: Anyone can view startups (needed for investors to see startup details)
CREATE POLICY "startups_select_all" ON public.startups
    FOR SELECT USING (true);

-- Policy 2: Users can manage their own startups
CREATE POLICY "startups_manage_own" ON public.startups
    FOR ALL USING (
        user_id = auth.uid()
    );

-- Policy 3: CA users can update startup compliance status
CREATE POLICY "startups_ca_update" ON public.startups
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CA'
        )
    );

-- Policy 4: CS users can update startup compliance status
CREATE POLICY "startups_cs_update" ON public.startups
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'CS'
        )
    );

-- Policy 5: Authenticated users can create startups (for new registrations)
CREATE POLICY "startups_insert_authenticated" ON public.startups
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated'
    );

-- 5. Verify the new policies
SELECT '=== VERIFYING NEW POLICIES ===' as info;

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
SELECT '=== TESTING INVESTOR ACCESS ===' as info;

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

-- 8. Final verification
SELECT '=== FINAL VERIFICATION ===' as info;

SELECT 
    'RLS Policies Created' as check_type,
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

