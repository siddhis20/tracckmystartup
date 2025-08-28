-- =====================================================
-- VERIFY FACILITATOR SYSTEM
-- =====================================================
-- This script verifies that the facilitator system is working properly

-- 1. Check if facilitator codes are assigned
SELECT 'CHECKING FACILITATOR CODES:' as info;
SELECT 
    id,
    name,
    email,
    role,
    facilitator_code,
    CASE 
        WHEN facilitator_code IS NOT NULL THEN '✅ Code Assigned'
        ELSE '❌ No Code'
    END as status
FROM users 
WHERE role = 'Startup Facilitation Center'
ORDER BY name;

-- 2. Check if opportunities exist
SELECT 'CHECKING OPPORTUNITIES:' as info;
SELECT 
    io.id,
    io.program_name,
    io.facilitator_code,
    u.name as facilitator_name,
    io.created_at
FROM public.incubation_opportunities io
LEFT JOIN users u ON io.facilitator_id = u.id
ORDER BY io.created_at DESC;

-- 3. Check if applications exist
SELECT 'CHECKING APPLICATIONS:' as info;
SELECT 
    oa.id,
    s.name as startup_name,
    io.program_name,
    io.facilitator_code,
    oa.status,
    oa.diligence_status
FROM public.opportunity_applications oa
JOIN public.incubation_opportunities io ON oa.opportunity_id = io.id
JOIN public.startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC;

-- 4. Check if functions exist
SELECT 'CHECKING FUNCTIONS:' as info;
SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name IS NOT NULL THEN '✅ Function Exists'
        ELSE '❌ Function Missing'
    END as status
FROM information_schema.routines 
WHERE routine_name IN (
    'generate_facilitator_code',
    'assign_facilitator_code',
    'get_facilitator_code',
    'get_facilitator_by_code',
    'get_opportunities_with_codes',
    'get_applications_with_codes'
)
ORDER BY routine_name;

-- 5. Test facilitator code generation
SELECT 'TESTING CODE GENERATION:' as info;
SELECT 
    generate_facilitator_code() as test_code,
    '✅ Code Generation Works' as status;

-- 6. Check if tables have correct structure
SELECT 'CHECKING TABLE STRUCTURE:' as info;
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('users', 'incubation_opportunities', 'opportunity_applications')
AND column_name IN ('facilitator_code', 'facilitator_id')
ORDER BY table_name, column_name;

-- 7. Summary
SELECT 'FACILITATOR SYSTEM VERIFICATION COMPLETE' as summary;
SELECT 
    COUNT(*) as total_facilitators,
    COUNT(CASE WHEN facilitator_code IS NOT NULL THEN 1 END) as facilitators_with_codes,
    COUNT(CASE WHEN facilitator_code IS NULL THEN 1 END) as facilitators_without_codes
FROM users 
WHERE role = 'Startup Facilitation Center';
