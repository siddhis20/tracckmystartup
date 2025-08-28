-- CHECK_ORPHANED_FUNDRAISING_RECORDS.sql
-- Check for fundraising records that reference non-existent startups

-- 1. Check which fundraising records have null startup references
SELECT 
    fd.id as fundraising_id,
    fd.startup_id,
    fd.active,
    fd.type,
    fd.value,
    fd.equity,
    s.id as startup_exists,
    s.name as startup_name
FROM fundraising_details fd
LEFT JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
ORDER BY fd.id;

-- 2. Count orphaned records (fundraising records with no matching startup)
SELECT 
    COUNT(*) as orphaned_fundraising_records
FROM fundraising_details fd
LEFT JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true AND s.id IS NULL;

-- 3. Show orphaned records details
SELECT 
    fd.id as fundraising_id,
    fd.startup_id,
    fd.active,
    fd.type,
    fd.value,
    fd.equity,
    fd.pitch_deck_url,
    fd.pitch_video_url
FROM fundraising_details fd
LEFT JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true AND s.id IS NULL;

-- 4. Check which startup IDs exist in startups table
SELECT 
    id,
    name,
    sector,
    compliance_status
FROM startups
ORDER BY id;

-- 5. Check fundraising_details startup_id values
SELECT DISTINCT startup_id FROM fundraising_details WHERE active = true ORDER BY startup_id;
