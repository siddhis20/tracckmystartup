-- DEBUG_FUNDRAISING_DATA.sql
-- This script debugs why startup ID 11's fundraising data is not showing

-- 1. Check if startup ID 11 exists
SELECT 
    id,
    name,
    sector,
    compliance_status,
    created_at
FROM startups 
WHERE id = 11;

-- 2. Check if there's fundraising data for startup ID 11
SELECT 
    id,
    startup_id,
    active,
    type,
    value,
    equity,
    pitch_deck_url,
    pitch_video_url,
    created_at
FROM fundraising_details 
WHERE startup_id = 11;

-- 3. Check the join between startup 11 and fundraising details
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
    fd.pitch_video_url,
    fd.created_at
FROM startups s
LEFT JOIN fundraising_details fd ON s.id = fd.startup_id
WHERE s.id = 11;

-- 4. Check all active fundraising data
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
    fd.pitch_video_url,
    fd.created_at
FROM fundraising_details fd
JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
ORDER BY fd.created_at DESC;

-- 5. Check if there are any fundraising records that are not active
SELECT 
    COUNT(*) as total_fundraising_records,
    COUNT(CASE WHEN active = true THEN 1 END) as active_records,
    COUNT(CASE WHEN active = false THEN 1 END) as inactive_records
FROM fundraising_details;

-- 6. Show all fundraising records for startup 11 (active and inactive)
SELECT 
    id,
    startup_id,
    active,
    type,
    value,
    equity,
    pitch_deck_url,
    pitch_video_url,
    created_at
FROM fundraising_details 
WHERE startup_id = 11
ORDER BY created_at DESC;

