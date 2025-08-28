-- Cleanup all CS-related tables and functions
-- This will give us a fresh start

-- Drop CS-related tables
DROP TABLE IF EXISTS public.cs_assignments CASCADE;
DROP TABLE IF EXISTS public.cs_assignment_requests CASCADE;

-- Drop CS-related triggers first (before functions)
DROP TRIGGER IF EXISTS trigger_generate_cs_code ON public.users;

-- Drop CS-related functions with CASCADE to handle dependencies
DROP FUNCTION IF EXISTS public.get_cs_startups(VARCHAR(20)) CASCADE;
DROP FUNCTION IF EXISTS public.generate_cs_code() CASCADE;
DROP FUNCTION IF EXISTS public.handle_cs_code_generation() CASCADE;
DROP FUNCTION IF EXISTS public.create_cs_assignment_request(BIGINT, TEXT, VARCHAR(20), TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.get_cs_assignment_requests(VARCHAR(20)) CASCADE;
DROP FUNCTION IF EXISTS public.approve_cs_assignment_request(INTEGER, VARCHAR(20), TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.reject_cs_assignment_request(INTEGER, VARCHAR(20), TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.get_startup_cs_requests(BIGINT) CASCADE;

-- Remove CS code column from users table (we'll add it back properly)
ALTER TABLE public.users DROP COLUMN IF EXISTS cs_code;

-- Clean up any CS-related policies
DROP POLICY IF EXISTS cs_assignment_requests_select_own ON public.cs_assignment_requests;
DROP POLICY IF EXISTS cs_assignment_requests_insert_own ON public.cs_assignment_requests;
DROP POLICY IF EXISTS cs_assignment_requests_update_own ON public.cs_assignment_requests;
DROP POLICY IF EXISTS cs_assignments_select_own ON public.cs_assignments;
DROP POLICY IF EXISTS cs_assignments_insert_own ON public.cs_assignments;
DROP POLICY IF EXISTS cs_assignments_update_own ON public.cs_assignments;

-- Verify cleanup
SELECT 
    'Cleanup Complete' as status,
    'All CS-related tables, functions, and triggers have been removed' as message;

-- Check what's left
SELECT 
    table_name,
    'Table' as type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%cs%'
UNION ALL
SELECT 
    routine_name,
    'Function' as type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%cs%';
