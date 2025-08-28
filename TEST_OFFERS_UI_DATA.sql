-- Test script to verify the offers UI data flow
-- This will help ensure the UI shows the correct buttons based on real data

-- 1. Check current applications and their status
SELECT '1. Current applications with status:' as test_step;
SELECT 
    oa.id,
    s.name as startup_name,
    io.program_name,
    oa.status,
    oa.diligence_status,
    oa.agreement_url,
    oa.created_at,
    u.name as facilitator_name,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'Incubation - Accepted'
        WHEN oa.diligence_status = 'requested' THEN 'Due Diligence - Pending'
        WHEN oa.diligence_status = 'approved' THEN 'Due Diligence - Approved'
        ELSE 'Other'
    END as offer_type
FROM opportunity_applications oa
LEFT JOIN startups s ON oa.startup_id = s.id
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
LEFT JOIN users u ON io.facilitator_id = u.id
WHERE oa.status = 'accepted' OR oa.diligence_status = 'requested'
ORDER BY oa.created_at DESC;

-- 2. Show what the UI should display for each application
SELECT '2. UI Display Logic:' as test_step;
SELECT 
    oa.id,
    s.name as startup_name,
    io.program_name,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'Incubation'
        WHEN oa.diligence_status = 'requested' THEN 'Due Diligence'
        WHEN oa.diligence_status = 'approved' THEN 'Due Diligence'
        ELSE 'Other'
    END as offer_type,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'Accepted into Program'
        WHEN oa.diligence_status = 'requested' THEN 'Request for Compliance access until 2024-09-15'
        WHEN oa.diligence_status = 'approved' THEN 'Compliance access granted'
        ELSE 'Other'
    END as offer_details,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' AND oa.agreement_url IS NOT NULL THEN 'Download Agreement'
        WHEN oa.diligence_status = 'requested' THEN 'Accept Request'
        WHEN oa.diligence_status = 'approved' AND oa.agreement_url IS NOT NULL THEN 'Download Agreement'
        WHEN oa.diligence_status = 'approved' AND oa.agreement_url IS NULL THEN 'Accepted'
        ELSE 'No Action'
    END as ui_action,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'accepted'
        WHEN oa.diligence_status = 'requested' THEN 'pending'
        WHEN oa.diligence_status = 'approved' THEN 'accepted'
        ELSE 'pending'
    END as ui_status
FROM opportunity_applications oa
LEFT JOIN startups s ON oa.startup_id = s.id
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
WHERE oa.status = 'accepted' OR oa.diligence_status = 'requested'
ORDER BY oa.created_at DESC;

-- 3. Check if there are any applications that should show "Accept Request" button
SELECT '3. Applications ready for "Accept Request":' as test_step;
SELECT 
    oa.id,
    s.name as startup_name,
    io.program_name,
    u.name as facilitator_name,
    oa.created_at
FROM opportunity_applications oa
LEFT JOIN startups s ON oa.startup_id = s.id
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
LEFT JOIN users u ON io.facilitator_id = u.id
WHERE oa.diligence_status = 'requested'
ORDER BY oa.created_at DESC;

-- 4. Check if there are any applications that should show "Download Agreement" button
SELECT '4. Applications ready for "Download Agreement":' as test_step;
SELECT 
    oa.id,
    s.name as startup_name,
    io.program_name,
    u.name as facilitator_name,
    oa.agreement_url,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'Incubation'
        WHEN oa.diligence_status = 'approved' THEN 'Due Diligence'
        ELSE 'Other'
    END as offer_type
FROM opportunity_applications oa
LEFT JOIN startups s ON oa.startup_id = s.id
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
LEFT JOIN users u ON io.facilitator_id = u.id
WHERE oa.agreement_url IS NOT NULL
AND (oa.status = 'accepted' OR oa.diligence_status = 'approved')
ORDER BY oa.created_at DESC;

-- 5. Simulate the exact data that the frontend should receive
SELECT '5. Frontend Data Structure:' as test_step;
SELECT 
    oa.id as application_id,
    u.name as from_facilitator,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'Incubation'
        WHEN oa.diligence_status = 'requested' THEN 'Due Diligence'
        WHEN oa.diligence_status = 'approved' THEN 'Due Diligence'
        ELSE 'Other'
    END as offer_type,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'Accepted into Program'
        WHEN oa.diligence_status = 'requested' THEN 'Request for Compliance access until 2024-09-15'
        WHEN oa.diligence_status = 'approved' THEN 'Compliance access granted'
        ELSE 'Other'
    END as offer_details,
    CASE 
        WHEN oa.status = 'accepted' AND oa.diligence_status = 'none' THEN 'accepted'
        WHEN oa.diligence_status = 'requested' THEN 'pending'
        WHEN oa.diligence_status = 'approved' THEN 'accepted'
        ELSE 'pending'
    END as offer_status,
    oa.agreement_url,
    CONCAT('FAC-', UPPER(SUBSTRING(oa.id::text FROM 25 FOR 6))) as offer_code
FROM opportunity_applications oa
LEFT JOIN startups s ON oa.startup_id = s.id
LEFT JOIN incubation_opportunities io ON oa.opportunity_id = io.id
LEFT JOIN users u ON io.facilitator_id = u.id
WHERE oa.status = 'accepted' OR oa.diligence_status = 'requested'
ORDER BY oa.created_at DESC;

-- 6. Summary
SELECT 'OFFERS UI DATA TEST COMPLETE' as summary;
SELECT 
    'If you see data in step 3, "Accept Request" buttons should appear' as accept_buttons,
    'If you see data in step 4, "Download Agreement" buttons should appear' as download_buttons,
    'Step 5 shows the exact data structure the frontend should receive' as data_structure;
