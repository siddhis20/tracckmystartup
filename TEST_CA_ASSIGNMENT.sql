-- =====================================================
-- TEST CA ASSIGNMENT
-- =====================================================
-- This script tests and fixes CA assignments
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: CHECK CURRENT CA ASSIGNMENTS
-- =====================================================

-- Check if CA-6BB957 has any assignments
SELECT 
    ca.ca_code,
    ca.startup_id,
    s.name as startup_name,
    ca.assignment_date,
    ca.status
FROM public.ca_assignments ca
JOIN public.startups s ON ca.startup_id = s.id
WHERE ca.ca_code = 'CA-6BB957';

-- =====================================================
-- STEP 2: CHECK IF MULSETU AGROTECH EXISTS
-- =====================================================

-- Check if Mulsetu Agrotech startup exists
SELECT 
    id,
    name,
    sector,
    compliance_status,
    created_at
FROM public.startups 
WHERE name ILIKE '%mulsetu%' OR name ILIKE '%agrotech%';

-- =====================================================
-- STEP 3: CREATE CA ASSIGNMENT IF MISSING
-- =====================================================

-- Get the startup ID for Mulsetu Agrotech
DO $$
DECLARE
    startup_id_val INTEGER;
BEGIN
    -- Find the startup ID
    SELECT id INTO startup_id_val
    FROM public.startups 
    WHERE name ILIKE '%mulsetu%' OR name ILIKE '%agrotech%'
    LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        -- Create CA assignment if it doesn't exist
        INSERT INTO public.ca_assignments (ca_code, startup_id, status, notes)
        VALUES ('CA-6BB957', startup_id_val, 'active', 'Auto-assigned for testing')
        ON CONFLICT (ca_code, startup_id) DO NOTHING;
        
        RAISE NOTICE 'CA assignment created for startup ID: %', startup_id_val;
    ELSE
        RAISE NOTICE 'No Mulsetu Agrotech startup found';
    END IF;
END $$;

-- =====================================================
-- STEP 4: VERIFY THE ASSIGNMENT
-- =====================================================

-- Check the final assignment
SELECT 
    'CA Assignment Status' as check_type,
    ca.ca_code,
    s.name as startup_name,
    ca.status,
    ca.assignment_date
FROM public.ca_assignments ca
JOIN public.startups s ON ca.startup_id = s.id
WHERE ca.ca_code = 'CA-6BB957';

-- =====================================================
-- STEP 5: TEST THE CA FUNCTION
-- =====================================================

-- Test the get_ca_startups function
SELECT * FROM public.get_ca_startups('CA-6BB957');

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT '✅ CA Assignment Test Complete!' as status;
