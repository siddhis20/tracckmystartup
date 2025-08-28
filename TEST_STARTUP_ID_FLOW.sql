-- TEST_STARTUP_ID_FLOW.sql
-- Test script to verify startup ID flow for facilitators

-- Step 1: Check current applications and their startup IDs
SELECT '=== APPLICATIONS WITH STARTUP IDS ===' as info;

SELECT 
    oa.id as application_id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    s.name as startup_name,
    s.id as startup_id_verified
FROM opportunity_applications oa
JOIN startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC;

-- Step 2: Check specific startup 11
SELECT '=== STARTUP 11 DETAILS ===' as info;

SELECT 
    id,
    name,
    investment_type,
    investment_value,
    equity_allocation,
    current_valuation,
    compliance_status,
    sector,
    total_funding,
    total_revenue,
    registration_date
FROM startups
WHERE id = 11;

-- Step 3: Check facilitator access to startup 11
SELECT '=== FACILITATOR ACCESS TO STARTUP 11 ===' as info;

SELECT 
    'Application Details' as info_type,
    oa.id as application_id,
    oa.startup_id,
    oa.status,
    oa.diligence_status,
    io.program_name,
    io.facilitator_code
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
WHERE oa.startup_id = 11
UNION ALL
SELECT 
    'Opportunity Details' as info_type,
    io.id as application_id,
    io.facilitator_id as startup_id,
    io.program_name as status,
    io.facilitator_code as diligence_status,
    io.program_name,
    io.facilitator_code
FROM incubation_opportunities io
WHERE io.id IN (
    SELECT opportunity_id 
    FROM opportunity_applications 
    WHERE startup_id = 11
);

-- Step 4: Test the exact query the facilitator service will use
SELECT '=== TESTING FACILITATOR SERVICE QUERY ===' as info;

-- Get facilitator code
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

-- Test opportunities query
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

-- Test applications query for startup 11
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
    io.facilitator_code,
    s.name as startup_name
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
JOIN startups s ON oa.startup_id = s.id, facilitator_info fi
WHERE oa.startup_id = 11 
AND io.facilitator_code = fi.facilitator_code
AND oa.diligence_status = 'approved';

-- Step 5: Show the complete flow
SELECT '=== COMPLETE FLOW TEST ===' as info;

-- This should show the complete path from facilitator to startup
WITH facilitator_info AS (
    SELECT facilitator_code 
    FROM users 
    WHERE role = 'Startup Facilitation Center' 
    LIMIT 1
)
SELECT 
    'Complete Flow' as flow_step,
    fi.facilitator_code,
    io.id as opportunity_id,
    io.program_name,
    oa.id as application_id,
    oa.startup_id,
    s.name as startup_name,
    oa.diligence_status,
    oa.status
FROM facilitator_info fi
JOIN incubation_opportunities io ON io.facilitator_code = fi.facilitator_code
JOIN opportunity_applications oa ON oa.opportunity_id = io.id
JOIN startups s ON oa.startup_id = s.id
WHERE oa.startup_id = 11
ORDER BY oa.created_at DESC;
