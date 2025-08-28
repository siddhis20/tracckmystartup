-- Simple CS Cleanup - Only removes what exists
-- This script safely removes CS-related objects without errors

-- Drop triggers first (if they exist)
DROP TRIGGER IF EXISTS trigger_generate_cs_code ON public.users;

-- Drop functions with CASCADE (if they exist)
DROP FUNCTION IF EXISTS public.get_cs_startups(VARCHAR(20)) CASCADE;
DROP FUNCTION IF EXISTS public.generate_cs_code() CASCADE;
DROP FUNCTION IF EXISTS public.handle_cs_code_generation() CASCADE;
DROP FUNCTION IF EXISTS public.create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.get_cs_assignment_requests(VARCHAR(20)) CASCADE;
DROP FUNCTION IF EXISTS public.approve_cs_assignment_request(INTEGER, VARCHAR(20), TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.reject_cs_assignment_request(INTEGER, VARCHAR(20), TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.get_startup_cs_requests(BIGINT) CASCADE;

-- Drop tables (if they exist)
DROP TABLE IF EXISTS public.cs_assignments CASCADE;
DROP TABLE IF EXISTS public.cs_assignment_requests CASCADE;

-- Remove CS code column from users table (if it exists)
ALTER TABLE public.users DROP COLUMN IF EXISTS cs_code;

-- Clean up any CS-related policies (if they exist)
DROP POLICY IF EXISTS cs_assignment_requests_select_own ON public.cs_assignment_requests;
DROP POLICY IF EXISTS cs_assignment_requests_insert_own ON public.cs_assignment_requests;
DROP POLICY IF EXISTS cs_assignment_requests_update_own ON public.cs_assignment_requests;
DROP POLICY IF EXISTS cs_assignments_select_own ON public.cs_assignments;
DROP POLICY IF EXISTS cs_assignments_insert_own ON public.cs_assignments;
DROP POLICY IF EXISTS cs_assignments_update_own ON public.cs_assignments;

-- Verify cleanup
SELECT 
    'CS Cleanup Complete' as status,
    'All existing CS-related objects have been removed' as message;

-- Check what CS-related objects remain (should be empty)
SELECT 
    'Remaining CS Objects' as check_type,
    COUNT(*) as count
FROM (
    SELECT table_name as name, 'Table' as type
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name LIKE '%cs%'
    UNION ALL
    SELECT routine_name as name, 'Function' as type
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name LIKE '%cs%'
) cs_objects;
