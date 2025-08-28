-- =====================================================
-- FIX CA STARTUPS FUNCTION
-- =====================================================
-- This script fixes the get_ca_startups RPC function type mismatch
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: DROP AND RECREATE THE FUNCTION
-- =====================================================

-- Drop the existing function
DROP FUNCTION IF EXISTS get_ca_startups(VARCHAR(20));

-- Recreate the function with correct types
CREATE OR REPLACE FUNCTION get_ca_startups(ca_code_param VARCHAR(20))
RETURNS TABLE (
    startup_id INTEGER,
    startup_name VARCHAR(255),
    assignment_date TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20),
    notes TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ca.startup_id,
        s.name::VARCHAR(255) as startup_name,
        ca.assignment_date,
        ca.status::VARCHAR(20),
        ca.notes
    FROM ca_assignments ca
    JOIN public.startups s ON ca.startup_id = s.id
    WHERE ca.ca_code = ca_code_param AND ca.status = 'active'
    ORDER BY ca.assignment_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 2: TEST THE FUNCTION
-- =====================================================

-- Test the function with a sample CA code
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
-- STEP 3: VERIFY FUNCTION EXISTS
-- =====================================================

-- Check if function exists with correct signature
SELECT 
    r.routine_name,
    r.routine_type,
    r.data_type as return_type,
    p.parameter_name,
    p.parameter_mode,
    p.parameter_default,
    p.data_type as param_data_type
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name
WHERE r.routine_name = 'get_ca_startups'
ORDER BY p.ordinal_position;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT '✅ CA Startups Function Fixed!' as status;
