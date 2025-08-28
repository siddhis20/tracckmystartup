-- FIX_STARTUP_11_FUNDRAISING.sql
-- This script ensures startup ID 11 has active fundraising data

-- First, check if startup 11 exists
SELECT 
    id,
    name,
    sector,
    compliance_status
FROM startups 
WHERE id = 11;

-- If startup 11 doesn't exist, create it
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

-- Check existing fundraising data for startup 11
SELECT 
    id,
    startup_id,
    active,
    type,
    value,
    equity,
    pitch_deck_url,
    pitch_video_url
FROM fundraising_details 
WHERE startup_id = 11;

-- Update or insert fundraising data for startup 11
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
    11,
    true,
    'Series A',
    5000000,
    15,
    false,
    'https://drive.google.com/file/d/1-2X3Y4Z5A6B7C8D9E0F/view?usp=sharing',
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
) ON CONFLICT (startup_id) DO UPDATE SET
    active = EXCLUDED.active,
    type = EXCLUDED.type,
    value = EXCLUDED.value,
    equity = EXCLUDED.equity,
    pitch_deck_url = EXCLUDED.pitch_deck_url,
    pitch_video_url = EXCLUDED.pitch_video_url,
    updated_at = NOW();

-- Verify the data
SELECT 
    s.id,
    s.name,
    s.sector,
    s.compliance_status,
    fd.active,
    fd.type,
    fd.value,
    fd.equity,
    fd.pitch_deck_url,
    fd.pitch_video_url
FROM startups s
JOIN fundraising_details fd ON s.id = fd.startup_id
WHERE s.id = 11;

-- Show all active fundraising data
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

