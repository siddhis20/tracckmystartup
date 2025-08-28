-- CHECK_STARTUP_REFERENCES.sql
-- Check if startup IDs referenced in fundraising_details exist in startups table

-- 1. Check which startup IDs exist in startups table
SELECT 
    id,
    name,
    sector,
    compliance_status
FROM startups
WHERE id IN (9, 11, 12, 13, 16)
ORDER BY id;

-- 2. Check the full join between fundraising_details and startups
SELECT 
    fd.id as fundraising_id,
    fd.startup_id,
    fd.active,
    fd.type,
    fd.value,
    fd.equity,
    fd.pitch_deck_url,
    fd.pitch_video_url,
    s.id as startup_exists,
    s.name as startup_name,
    s.sector as startup_sector
FROM fundraising_details fd
LEFT JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
ORDER BY fd.id;

-- 3. Count how many fundraising records have valid startup references
SELECT 
    COUNT(*) as total_fundraising_records,
    COUNT(s.id) as records_with_valid_startups,
    COUNT(*) - COUNT(s.id) as orphaned_records
FROM fundraising_details fd
LEFT JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true;
