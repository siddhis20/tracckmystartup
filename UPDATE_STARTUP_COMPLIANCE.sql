-- UPDATE_STARTUP_COMPLIANCE.sql
-- This script updates some startups to compliant status for testing

-- First, let's see the current compliance status of all startups
SELECT 
    id,
    name,
    sector,
    compliance_status,
    created_at
FROM startups 
ORDER BY created_at DESC;

-- Update the first 3 startups to compliant status
UPDATE startups 
SET compliance_status = 'Compliant'
WHERE id IN (
    SELECT s.id 
    FROM startups s
    JOIN fundraising_details fd ON s.id = fd.startup_id
    WHERE fd.active = true
    ORDER BY s.created_at ASC
    LIMIT 3
);

-- Verify the changes
SELECT 
    s.id,
    s.name,
    s.sector,
    s.compliance_status,
    fd.active,
    fd.type,
    fd.value,
    fd.equity
FROM startups s
JOIN fundraising_details fd ON s.id = fd.startup_id
WHERE fd.active = true
ORDER BY s.created_at ASC;

-- Show updated count
SELECT 
    COUNT(*) as active_fundraising_count,
    COUNT(CASE WHEN s.compliance_status = 'Compliant' THEN 1 END) as compliant_count,
    COUNT(CASE WHEN s.compliance_status != 'Compliant' THEN 1 END) as non_compliant_count
FROM fundraising_details fd
JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true;

