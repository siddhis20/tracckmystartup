-- CHECK_STARTUP_11.sql
-- This script checks if startup ID 11 exists and fixes any issues

-- 1. Check if startup 11 exists in the startups table
SELECT 
    id,
    name,
    sector,
    compliance_status,
    created_at
FROM startups 
WHERE id = 11;

-- 2. If startup 11 doesn't exist, create it
INSERT INTO startups (id, name, sector, compliance_status, investment_type, investment_value, equity_allocation, current_valuation, total_funding, total_revenue, registration_date)
SELECT 
    11,
    'TechFlow Solutions',
    'Technology',
    'Compliant',
    'Series A',
    5000000,
    15,
    25000000,
    2000000,
    1500000,
    '2023-01-15'
WHERE NOT EXISTS (SELECT 1 FROM startups WHERE id = 11);

-- 3. Now check the complete join
SELECT 
    s.id as startup_id,
    s.name as startup_name,
    s.sector,
    s.compliance_status,
    fd.id as fundraising_id,
    fd.active,
    fd.type,
    fd.value,
    fd.equity,
    fd.pitch_deck_url,
    fd.pitch_video_url
FROM startups s
JOIN fundraising_details fd ON s.id = fd.startup_id
WHERE s.id = 11 AND fd.active = true;

-- 4. Show all active fundraising data that should appear in the app
SELECT 
    fd.id,
    s.id as startup_id,
    s.name as startup_name,
    s.sector,
    s.compliance_status,
    fd.active,
    fd.type,
    fd.value,
    fd.equity,
    fd.pitch_deck_url,
    fd.pitch_video_url
FROM fundraising_details fd
JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
ORDER BY fd.created_at DESC;

