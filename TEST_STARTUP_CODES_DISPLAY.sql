-- TEST_STARTUP_CODES_DISPLAY.sql
-- Test script to verify startup codes are working

-- Step 1: Check if startup codes exist
SELECT '=== STARTUP CODES CHECK ===' as info;

SELECT 
    id,
    name,
    startup_code,
    created_at
FROM startups
ORDER BY created_at DESC;

-- Step 2: Check if applications have startup codes
SELECT '=== APPLICATIONS WITH STARTUP CODES ===' as info;

SELECT 
    oa.id,
    oa.startup_id,
    oa.startup_code,
    s.name as startup_name,
    oa.status,
    oa.diligence_status
FROM opportunity_applications oa
JOIN startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC;

-- Step 3: Test the exact query the frontend will use
SELECT '=== FRONTEND DATA TEST ===' as info;

-- Simulate what the frontend will receive
SELECT 
    id,
    name,
    startup_code,
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
WHERE id = 11  -- Test with startup 11
LIMIT 1;

-- Step 4: Show sample data for display
SELECT '=== SAMPLE DISPLAY DATA ===' as info;

SELECT 
    'Startup Dashboard Header' as display_location,
    name as startup_name,
    startup_code as display_code,
    '🏷️ Your Startup ID: ' || startup_code as header_display
FROM startups
WHERE id = 11
UNION ALL
SELECT 
    'Facilitator Offers Table' as display_location,
    s.name as startup_name,
    io.facilitator_code as display_code,
    'FAC-' || SUBSTRING(io.facilitator_code FROM 4) as header_display
FROM opportunity_applications oa
JOIN startups s ON oa.startup_id = s.id
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
WHERE oa.startup_id = 11
LIMIT 1;
