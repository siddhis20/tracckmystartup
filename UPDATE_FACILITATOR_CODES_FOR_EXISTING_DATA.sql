-- UPDATE_FACILITATOR_CODES_FOR_EXISTING_DATA.sql
-- This script updates existing opportunities with real facilitator codes from the users table

-- Step 1: Check current state
SELECT '=== CURRENT STATE ===' as info;

-- Show facilitators and their codes
SELECT 
    'Facilitators with codes' as step,
    id,
    email,
    role,
    facilitator_code
FROM users 
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at DESC;

-- Step 2: Show opportunities before update
SELECT 
    'Opportunities before update' as step,
    id,
    program_name,
    facilitator_id,
    facilitator_code,
    created_at
FROM incubation_opportunities
ORDER BY created_at DESC;

-- Step 3: Update opportunities with real facilitator codes
UPDATE incubation_opportunities 
SET facilitator_code = users.facilitator_code
FROM users 
WHERE incubation_opportunities.facilitator_id = users.id 
AND users.facilitator_code IS NOT NULL
AND incubation_opportunities.facilitator_code IS NULL;

-- Step 4: Verify the update
SELECT 
    'Opportunities after update' as step,
    id,
    program_name,
    facilitator_id,
    facilitator_code,
    created_at
FROM incubation_opportunities
ORDER BY created_at DESC;

-- Step 5: Show applications with updated facilitator codes
SELECT 
    'Applications with updated facilitator codes' as step,
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

-- Step 6: Count opportunities by facilitator code
SELECT 
    'Opportunities count by facilitator code' as step,
    facilitator_code,
    COUNT(*) as opportunity_count
FROM incubation_opportunities
WHERE facilitator_code IS NOT NULL
GROUP BY facilitator_code
ORDER BY opportunity_count DESC;
