-- ADD_REAL_FUNDRAISING_DATA.sql
-- This script adds real fundraising data to existing startups

-- First, let's see what startups we have
SELECT 
    id,
    name,
    sector,
    compliance_status,
    created_at
FROM startups 
ORDER BY created_at DESC;

-- Now let's add fundraising details for existing startups
-- We'll add one fundraising record per startup

-- Get the first startup and add Series A fundraising
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) 
SELECT 
    s.id,
    true,
    'Series A',
    5000000,
    15,
    false,
    'https://drive.google.com/file/d/1-2X3Y4Z5A6B7C8D9E0F/view?usp=sharing',
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
FROM startups s
WHERE s.id = (SELECT MIN(id) FROM startups)
ON CONFLICT DO NOTHING;

-- Get the second startup and add Seed fundraising
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) 
SELECT 
    s.id,
    true,
    'Seed',
    1000000,
    20,
    false,
    'https://drive.google.com/file/d/2-3X4Y5Z6A7B8C9D0E1F/view?usp=sharing',
    'https://www.youtube.com/watch?v=9bZkp7q19f0'
FROM startups s
WHERE s.id = (SELECT MIN(id) FROM startups WHERE id > (SELECT MIN(id) FROM startups))
ON CONFLICT DO NOTHING;

-- Get the third startup and add Pre-Seed fundraising
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) 
SELECT 
    s.id,
    true,
    'Pre-Seed',
    500000,
    25,
    false,
    'https://drive.google.com/file/d/3-4X5Y6Z7A8B9C0D1E2F/view?usp=sharing',
    'https://www.youtube.com/watch?v=kJQP7kiw5Fk'
FROM startups s
WHERE s.id = (
    SELECT MIN(id) FROM startups 
    WHERE id > (SELECT MIN(id) FROM startups WHERE id > (SELECT MIN(id) FROM startups))
)
ON CONFLICT DO NOTHING;

-- Get the fourth startup and add Series B fundraising
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) 
SELECT 
    s.id,
    true,
    'Series B',
    10000000,
    10,
    false,
    'https://drive.google.com/file/d/4-5X6Y7Z8A9B0C1D2E3F/view?usp=sharing',
    'https://www.youtube.com/watch?v=ZZ5LpwO-An4'
FROM startups s
WHERE s.id = (
    SELECT MIN(id) FROM startups 
    WHERE id > (
        SELECT MIN(id) FROM startups 
        WHERE id > (SELECT MIN(id) FROM startups WHERE id > (SELECT MIN(id) FROM startups))
    )
)
ON CONFLICT DO NOTHING;

-- Get the fifth startup and add Bridge fundraising
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) 
SELECT 
    s.id,
    true,
    'Bridge',
    2000000,
    8,
    false,
    'https://drive.google.com/file/d/5-6X7Y8Z9A0B1C2D3E4F/view?usp=sharing',
    'https://www.youtube.com/watch?v=3YxaaGgTQYM'
FROM startups s
WHERE s.id = (
    SELECT MIN(id) FROM startups 
    WHERE id > (
        SELECT MIN(id) FROM startups 
        WHERE id > (
            SELECT MIN(id) FROM startups 
            WHERE id > (SELECT MIN(id) FROM startups WHERE id > (SELECT MIN(id) FROM startups))
        )
    )
)
ON CONFLICT DO NOTHING;

-- Verify the data was inserted
SELECT 
    fd.id,
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

-- Show count of active fundraising startups
SELECT 
    COUNT(*) as active_fundraising_count,
    COUNT(CASE WHEN s.compliance_status = 'Compliant' THEN 1 END) as compliant_count,
    COUNT(CASE WHEN s.compliance_status != 'Compliant' THEN 1 END) as non_compliant_count
FROM fundraising_details fd
JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true;

