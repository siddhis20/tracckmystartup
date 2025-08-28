-- Test script to debug approved startups flow
-- This will help us understand why approved startups are not appearing in "My Startups"

-- 1. Check recognition records with their status
SELECT '=== RECOGNITION RECORDS WITH STATUS ===' as info;
SELECT 
    id,
    startup_id,
    program_name,
    facilitator_code,
    status,
    created_at,
    date_added
FROM public.recognition_records 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. Check startups that have recognition records
SELECT '=== STARTUPS WITH RECOGNITION RECORDS ===' as info;
SELECT 
    s.id,
    s.name,
    s.sector,
    s.current_valuation,
    s.compliance_status,
    rr.program_name,
    rr.facilitator_code,
    rr.status as recognition_status,
    rr.created_at as recognition_created
FROM public.startups s
JOIN public.recognition_records rr ON s.id = rr.startup_id
ORDER BY rr.created_at DESC;

-- 3. Check specifically approved recognition records
SELECT '=== APPROVED RECOGNITION RECORDS ===' as info;
SELECT 
    rr.id,
    rr.startup_id,
    rr.program_name,
    rr.facilitator_code,
    rr.status,
    s.name as startup_name,
    s.sector as startup_sector,
    s.current_valuation,
    s.compliance_status
FROM public.recognition_records rr
JOIN public.startups s ON rr.startup_id = s.id
WHERE rr.status = 'approved'
ORDER BY rr.created_at DESC;

-- 4. Check facilitator codes for users
SELECT '=== FACILITATOR CODES ===' as info;
SELECT 
    id,
    email,
    role,
    facilitator_code,
    created_at
FROM public.users 
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at DESC;

-- 5. Test the exact query used in the frontend
SELECT '=== FRONTEND QUERY TEST ===' as info;
SELECT 
    rr.id,
    rr.startup_id,
    rr.program_name,
    rr.facilitator_name,
    rr.facilitator_code,
    rr.incubation_type,
    rr.fee_type,
    rr.fee_amount,
    rr.equity_allocated,
    rr.pre_money_valuation,
    rr.signed_agreement_url,
    rr.status,
    rr.date_added,
    rr.created_at,
    s.id as startup_id_from_join,
    s.name as startup_name_from_join,
    s.sector as startup_sector_from_join,
    s.current_valuation as startup_valuation_from_join,
    s.compliance_status as startup_compliance_from_join
FROM public.recognition_records rr
JOIN public.startups s ON rr.startup_id = s.id
WHERE rr.facilitator_code = 'FAC-0EFCD9'  -- Replace with actual facilitator code
ORDER BY rr.created_at DESC;

-- 6. Check if there are any recognition records without startup data
SELECT '=== RECOGNITION RECORDS WITHOUT STARTUP DATA ===' as info;
SELECT 
    rr.id,
    rr.startup_id,
    rr.program_name,
    rr.facilitator_code,
    rr.status
FROM public.recognition_records rr
LEFT JOIN public.startups s ON rr.startup_id = s.id
WHERE s.id IS NULL;
