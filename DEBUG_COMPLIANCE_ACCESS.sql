-- DEBUG_COMPLIANCE_ACCESS.sql
-- Debug script to check compliance access issues

-- Step 1: Check current state of applications
SELECT '=== APPLICATIONS STATE ===' as info;

SELECT 
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    s.name as startup_name,
    io.program_name,
    io.facilitator_code
FROM opportunity_applications oa
JOIN startups s ON oa.startup_id = s.id
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
ORDER BY oa.created_at DESC;

-- Step 2: Check specific startup 11 applications
SELECT '=== STARTUP 11 APPLICATIONS ===' as info;

SELECT 
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
JOIN users u ON io.facilitator_id = u.id
WHERE oa.startup_id = 11
ORDER BY oa.created_at DESC;

-- Step 3: Check facilitator codes
SELECT '=== FACILITATOR CODES ===' as info;

SELECT 
    id,
    email,
    role,
    facilitator_code
FROM users 
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at DESC;

-- Step 4: Check opportunities with facilitator codes
SELECT '=== OPPORTUNITIES WITH FACILITATOR CODES ===' as info;

SELECT 
    id,
    program_name,
    facilitator_id,
    facilitator_code,
    created_at
FROM incubation_opportunities
ORDER BY created_at DESC;

-- Step 5: Test the exact query the service will use
SELECT '=== TEST COMPLIANCE ACCESS QUERY ===' as info;

-- First, get facilitator code
WITH facilitator_info AS (
    SELECT facilitator_code 
    FROM users 
    WHERE role = 'Startup Facilitation Center' 
    LIMIT 1
)
SELECT 
    'Facilitator Code' as info,
    facilitator_code
FROM facilitator_info;

-- Then test the opportunities query
WITH facilitator_info AS (
    SELECT facilitator_code 
    FROM users 
    WHERE role = 'Startup Facilitation Center' 
    LIMIT 1
)
SELECT 
    'Opportunities for facilitator code' as info,
    io.id,
    io.program_name,
    io.facilitator_code
FROM incubation_opportunities io, facilitator_info fi
WHERE io.facilitator_code = fi.facilitator_code;

-- Finally test the applications query
WITH facilitator_info AS (
    SELECT facilitator_code 
    FROM users 
    WHERE role = 'Startup Facilitation Center' 
    LIMIT 1
)
SELECT 
    'Applications for startup 11 with approved diligence' as info,
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.diligence_status,
    io.facilitator_code
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id, facilitator_info fi
WHERE oa.startup_id = 11 
AND io.facilitator_code = fi.facilitator_code
AND oa.diligence_status = 'approved';
