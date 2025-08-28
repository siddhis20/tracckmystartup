-- DEBUG_FACILITATOR_DATA_LOADING.sql
-- Debug script to check facilitator data flow

-- Step 1: Check if facilitator_code columns exist and have data
SELECT '=== COLUMN CHECK ===' as info;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('users', 'incubation_opportunities')
AND column_name = 'facilitator_code';

-- Step 2: Check facilitators and their codes
SELECT '=== FACILITATORS ===' as info;

SELECT 
    id,
    email,
    role,
    facilitator_code,
    created_at
FROM users 
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at DESC;

-- Step 3: Check opportunities and their codes
SELECT '=== OPPORTUNITIES ===' as info;

SELECT 
    id,
    program_name,
    facilitator_id,
    facilitator_code,
    created_at
FROM incubation_opportunities
ORDER BY created_at DESC;

-- Step 4: Check applications
SELECT '=== APPLICATIONS ===' as info;

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
LEFT JOIN users u ON io.facilitator_id = u.id
ORDER BY oa.created_at DESC;

-- Step 5: Test the exact query the service should use
SELECT '=== TEST SERVICE QUERY ===' as info;

-- First, get a facilitator code
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

-- Step 6: Test opportunities query
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

-- Step 7: Test applications query
WITH facilitator_info AS (
    SELECT facilitator_code 
    FROM users 
    WHERE role = 'Startup Facilitation Center' 
    LIMIT 1
)
SELECT 
    'Applications for facilitator code' as info,
    oa.id,
    oa.startup_id,
    oa.status,
    oa.diligence_status,
    io.program_name,
    io.facilitator_code
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id, facilitator_info fi
WHERE io.facilitator_code = fi.facilitator_code;
