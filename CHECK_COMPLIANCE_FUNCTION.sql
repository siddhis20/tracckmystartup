-- =====================================================
-- CHECK COMPLIANCE FUNCTION AND SUBSIDIARIES
-- =====================================================
-- This script checks if the compliance function exists and if subsidiaries are being processed

-- =====================================================
-- STEP 1: CHECK IF THE FUNCTION EXISTS
-- =====================================================

-- Check if the generate_compliance_tasks_for_startup function exists
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'generate_compliance_tasks_for_startup'
AND routine_schema = 'public';

-- =====================================================
-- STEP 2: CHECK SUBSIDIARIES FOR A SPECIFIC STARTUP
-- =====================================================

-- Replace [STARTUP_ID] with your actual startup ID
-- Check subsidiaries for startup ID 1 (change this to your startup ID)
SELECT 
    id,
    startup_id,
    country,
    company_type,
    registration_date,
    created_at
FROM public.subsidiaries
WHERE startup_id = 1  -- Change this to your startup ID
ORDER BY id;

-- =====================================================
-- STEP 3: TEST THE FUNCTION MANUALLY
-- =====================================================

-- Test the function for startup ID 1 (change this to your startup ID)
SELECT * FROM generate_compliance_tasks_for_startup(1);  -- Change this to your startup ID

-- =====================================================
-- STEP 4: CHECK STARTUP DATA
-- =====================================================

-- Check startup data for startup ID 1 (change this to your startup ID)
SELECT 
    id,
    name,
    country_of_registration,
    company_type,
    registration_date
FROM public.startups
WHERE id = 1;  -- Change this to your startup ID

-- =====================================================
-- STEP 5: CHECK COMPLIANCE RULES FOR SUBSIDIARY COUNTRY
-- =====================================================

-- Check if compliance rules exist for the subsidiary's country
-- Replace 'USA' with your subsidiary's country
SELECT 
    country_code,
    country_name,
    company_type,
    compliance_name,
    frequency,
    verification_required
FROM public.compliance_rules_comprehensive
WHERE country_code = 'USA'  -- Change this to your subsidiary's country
LIMIT 10;

-- =====================================================
-- STEP 6: SUMMARY
-- =====================================================

-- Get all startup IDs that have subsidiaries
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.country_of_registration,
    s.company_type,
    COUNT(sub.id) as subsidiary_count
FROM public.startups s
LEFT JOIN public.subsidiaries sub ON s.id = sub.startup_id
GROUP BY s.id, s.name, s.country_of_registration, s.company_type
HAVING COUNT(sub.id) > 0
ORDER BY s.id;
