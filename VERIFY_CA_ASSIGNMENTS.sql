-- =====================================================
-- VERIFY CA ASSIGNMENTS
-- =====================================================
-- This script verifies the CA assignment system is working
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: CHECK CA ASSIGNMENTS TABLE
-- =====================================================

-- Check if ca_assignments table exists and has data
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'ca_assignments'
        ) THEN '✅ ca_assignments table EXISTS'
        ELSE '❌ ca_assignments table MISSING'
    END as ca_assignments_status;

-- Check table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'ca_assignments'
ORDER BY ordinal_position;

-- Check current assignments
SELECT 
    ca_code,
    startup_id,
    status,
    assignment_date,
    notes
FROM ca_assignments
ORDER BY assignment_date DESC;

-- =====================================================
-- STEP 2: CHECK CA ASSIGNMENT REQUESTS
-- =====================================================

-- Check current requests
SELECT 
    id,
    startup_id,
    startup_name,
    ca_code,
    status,
    request_date,
    notes
FROM ca_assignment_requests
ORDER BY request_date DESC;

-- =====================================================
-- STEP 3: CHECK RPC FUNCTIONS
-- =====================================================

-- Check if get_ca_startups function exists
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'get_ca_startups';

-- Test get_ca_startups function with a sample CA code
DO $$
DECLARE
    test_ca_code VARCHAR(20);
    test_result RECORD;
BEGIN
    -- Get first CA code from users table
    SELECT ca_code INTO test_ca_code 
    FROM public.users 
    WHERE role = 'CA' AND ca_code IS NOT NULL 
    LIMIT 1;
    
    IF test_ca_code IS NOT NULL THEN
        RAISE NOTICE 'Testing get_ca_startups with CA code: %', test_ca_code;
        
        -- Test the function
        FOR test_result IN 
            SELECT * FROM get_ca_startups(test_ca_code)
        LOOP
            RAISE NOTICE 'Found assignment: startup_id=%, startup_name=%, status=%', 
                test_result.startup_id, test_result.startup_name, test_result.status;
        END LOOP;
    ELSE
        RAISE NOTICE 'No CA users found with CA codes';
    END IF;
END $$;

-- =====================================================
-- STEP 4: CHECK STARTUPS WITH CA CODES
-- =====================================================

-- Check startups that have CA codes assigned
SELECT 
    s.id,
    s.name,
    s.ca_service_code,
    s.cs_service_code,
    ca.status as ca_assignment_status,
    ca.assignment_date
FROM public.startups s
LEFT JOIN ca_assignments ca ON s.id = ca.startup_id
WHERE s.ca_service_code IS NOT NULL
ORDER BY s.name;

-- =====================================================
-- STEP 5: MANUAL TEST
-- =====================================================

-- Test creating an assignment manually
DO $$
DECLARE
    test_startup_id INTEGER;
    test_ca_code VARCHAR(20);
BEGIN
    -- Get first startup
    SELECT id INTO test_startup_id FROM public.startups LIMIT 1;
    
    -- Get first CA code
    SELECT ca_code INTO test_ca_code 
    FROM public.users 
    WHERE role = 'CA' AND ca_code IS NOT NULL 
    LIMIT 1;
    
    IF test_startup_id IS NOT NULL AND test_ca_code IS NOT NULL THEN
        RAISE NOTICE 'Testing manual assignment: startup_id=%, ca_code=%', test_startup_id, test_ca_code;
        
        -- Try to create assignment
        INSERT INTO ca_assignments (ca_code, startup_id, status, notes)
        VALUES (test_ca_code, test_startup_id, 'active', 'Manual test assignment')
        ON CONFLICT (ca_code, startup_id) 
        DO UPDATE SET 
            status = 'active',
            notes = 'Manual test assignment updated',
            updated_at = NOW();
            
        RAISE NOTICE 'Manual assignment created/updated successfully';
    ELSE
        RAISE NOTICE 'Cannot test: missing startup_id or ca_code';
    END IF;
END $$;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT '🔍 CA Assignment Verification Complete!' as status;
