-- ADD_SAMPLE_FUNDRAISING_DATA.sql
-- This script adds sample fundraising data for testing the investor dashboard

-- First, let's check if we have any startups to work with
SELECT 
    id,
    name,
    sector,
    compliance_status
FROM startups 
ORDER BY created_at DESC 
LIMIT 5;

-- Add sample fundraising details for existing startups
-- Replace the startup_id values with actual startup IDs from your database

-- Sample 1: Tech startup raising Series A
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) VALUES (
    (SELECT id FROM startups WHERE name LIKE '%Tech%' LIMIT 1),
    true,
    'Series A',
    5000000,
    15,
    false,
    'https://example.com/pitch-decks/tech-startup-deck.pdf',
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
) ON CONFLICT DO NOTHING;

-- Sample 2: Fintech startup raising Seed
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) VALUES (
    (SELECT id FROM startups WHERE name LIKE '%Fin%' OR name LIKE '%Bank%' LIMIT 1),
    true,
    'Seed',
    1000000,
    20,
    false,
    'https://example.com/pitch-decks/fintech-seed-deck.pdf',
    'https://www.youtube.com/watch?v=9bZkp7q19f0'
) ON CONFLICT DO NOTHING;

-- Sample 3: Health startup raising Pre-Seed
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) VALUES (
    (SELECT id FROM startups WHERE name LIKE '%Health%' OR name LIKE '%Med%' LIMIT 1),
    true,
    'Pre-Seed',
    500000,
    25,
    false,
    'https://example.com/pitch-decks/health-startup-deck.pdf',
    'https://www.youtube.com/watch?v=kJQP7kiw5Fk'
) ON CONFLICT DO NOTHING;

-- Sample 4: E-commerce startup raising Series B
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) VALUES (
    (SELECT id FROM startups WHERE name LIKE '%Shop%' OR name LIKE '%Store%' LIMIT 1),
    true,
    'Series B',
    10000000,
    10,
    false,
    'https://example.com/pitch-decks/ecommerce-series-b-deck.pdf',
    'https://www.youtube.com/watch?v=ZZ5LpwO-An4'
) ON CONFLICT DO NOTHING;

-- Sample 5: AI startup raising Bridge
INSERT INTO fundraising_details (
    startup_id,
    active,
    type,
    value,
    equity,
    validation_requested,
    pitch_deck_url,
    pitch_video_url
) VALUES (
    (SELECT id FROM startups WHERE name LIKE '%AI%' OR name LIKE '%Machine%' LIMIT 1),
    true,
    'Bridge',
    2000000,
    8,
    false,
    'https://example.com/pitch-decks/ai-bridge-deck.pdf',
    'https://www.youtube.com/watch?v=3YxaaGgTQYM'
) ON CONFLICT DO NOTHING;

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

