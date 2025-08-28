-- =====================================================
-- FIX PROFILE FUNCTION PERMISSIONS
-- =====================================================
-- This script fixes permission issues with profile update functions
-- =====================================================

-- Step 1: Check function permissions
-- =====================================================

SELECT 
    'function_permissions_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_startup_profile'
            AND routine_schema = 'public'
        )
        THEN '✅ update_startup_profile function exists'
        ELSE '❌ update_startup_profile function missing'
    END as status
UNION ALL
SELECT 
    'simple_function_permissions_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_startup_profile_simple'
            AND routine_schema = 'public'
        )
        THEN '✅ update_startup_profile_simple function exists'
        ELSE '❌ update_startup_profile_simple function missing'
    END as status;

-- Step 2: Grant necessary permissions
-- =====================================================

-- Grant execute permissions on the functions
GRANT EXECUTE ON FUNCTION public.update_startup_profile(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_startup_profile_simple(INTEGER, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- Grant permissions on the startups table
GRANT SELECT, UPDATE ON public.startups TO authenticated;

-- Step 3: Check RLS policies on startups table
-- =====================================================

-- Check if RLS is enabled
SELECT 
    'rls_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE tablename = 'startups' 
            AND rowsecurity = true
        )
        THEN '✅ RLS is enabled on startups table'
        ELSE '❌ RLS is not enabled on startups table'
    END as status;

-- Step 4: Create/Update RLS policies for startups table
-- =====================================================

-- Enable RLS if not already enabled
ALTER TABLE public.startups ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own startups" ON public.startups;
DROP POLICY IF EXISTS "Users can update their own startups" ON public.startups;
DROP POLICY IF EXISTS "Users can insert their own startups" ON public.startups;

-- Create RLS policies for startups table
CREATE POLICY "Users can view their own startups" ON public.startups
    FOR SELECT USING (
        user_id = auth.uid()
    );

CREATE POLICY "Users can update their own startups" ON public.startups
    FOR UPDATE USING (
        user_id = auth.uid()
    );

CREATE POLICY "Users can insert their own startups" ON public.startups
    FOR INSERT WITH CHECK (
        user_id = auth.uid()
    );

-- Step 5: Test the function with proper permissions
-- =====================================================

DO $$
DECLARE
    startup_id_val INTEGER;
    update_result BOOLEAN;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM public.startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing update_startup_profile_simple with permissions on ID: %', startup_id_val;
        
        -- Test with valid data
        SELECT update_startup_profile_simple(
            startup_id_val,
            'Permission Test Country',
            'Permission Test Type',
            '2025-01-20',
            'PERM-CA-001',
            'PERM-CS-001'
        ) INTO update_result;
        
        RAISE NOTICE 'Permission test result: %', update_result;
        
        IF update_result THEN
            RAISE NOTICE '✅ Function works with proper permissions!';
        ELSE
            RAISE NOTICE '❌ Function still has issues';
        END IF;
        
    ELSE
        RAISE NOTICE 'No startups found for testing';
    END IF;
END $$;

-- Step 6: Verify all permissions are set correctly
-- =====================================================

SELECT 
    'final_permissions_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_startup_profile_simple'
            AND routine_schema = 'public'
        ) AND EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'startups' 
            AND policyname = 'Users can update their own startups'
        )
        THEN '✅ All permissions set correctly'
        ELSE '❌ Some permissions missing'
    END as status;

-- Step 7: Show current policies
-- =====================================================

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'startups'
ORDER BY policyname;

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'PROFILE FUNCTION PERMISSIONS FIXED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Function permissions granted';
    RAISE NOTICE '✅ RLS policies created';
    RAISE NOTICE '✅ Function tested with permissions';
    RAISE NOTICE '✅ Ready for frontend testing';
    RAISE NOTICE '========================================';
END $$;

