-- TEST_FACILITATOR_CODE_SYSTEM.sql
-- Test script to verify facilitator code system

-- Step 1: Run the setup script first
-- Run ADD_FACILITATOR_CODE_COLUMN.sql if you haven't already

-- Step 2: Check current state
SELECT '=== CURRENT STATE ===' as info;

-- Check if columns exist
SELECT 
    'Column check' as step,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('users', 'incubation_opportunities')
AND column_name = 'facilitator_code';

-- Step 3: Show all facilitators
SELECT 
    'All facilitators' as step,
    id,
    email,
    role,
    facilitator_code,
    created_at
FROM users
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at DESC;

-- Step 4: Show all incubation opportunities
SELECT 
    'All incubation opportunities' as step,
    id,
    program_name,
    facilitator_id,
    facilitator_code,
    created_at
FROM incubation_opportunities
ORDER BY created_at DESC;

-- Step 5: Show opportunities with facilitator codes
SELECT 
    'Opportunities with facilitator codes' as step,
    io.id,
    io.program_name,
    io.facilitator_id,
    io.facilitator_code,
    u.email as facilitator_email,
    u.facilitator_code as user_facilitator_code
FROM incubation_opportunities io
LEFT JOIN users u ON io.facilitator_id = u.id
WHERE io.facilitator_code IS NOT NULL
ORDER BY io.created_at DESC;

-- Step 6: Show applications with facilitator info
SELECT 
    'Applications with facilitator info' as step,
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    io.program_name,
    io.facilitator_code,
    u.email as facilitator_email
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
LEFT JOIN users u ON io.facilitator_id = u.id
ORDER BY oa.created_at DESC
LIMIT 10;

-- Step 7: Test specific facilitator code lookup
-- Replace 'YOUR_FACILITATOR_CODE_HERE' with an actual facilitator code
SELECT 
    'Test specific facilitator code' as step,
    io.id,
    io.program_name,
    io.facilitator_code,
    u.email as facilitator_email,
    COUNT(oa.id) as application_count
FROM incubation_opportunities io
LEFT JOIN users u ON io.facilitator_id = u.id
LEFT JOIN opportunity_applications oa ON io.id = oa.opportunity_id
WHERE io.facilitator_code = 'YOUR_FACILITATOR_CODE_HERE'  -- Replace this with actual code
GROUP BY io.id, io.program_name, io.facilitator_code, u.email
ORDER BY io.created_at DESC;
