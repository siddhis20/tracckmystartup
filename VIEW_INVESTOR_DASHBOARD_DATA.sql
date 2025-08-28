-- VIEW_INVESTOR_DASHBOARD_DATA.sql
-- This script shows exactly what data will be displayed in the Investor Dashboard

-- Show all active fundraising startups with their details
SELECT 
    s.id,
    s.name as startup_name,
    s.sector,
    s.compliance_status,
    fd.active,
    fd.type as fundraising_type,
    fd.value as investment_value,
    fd.equity as equity_allocation,
    fd.pitch_deck_url,
    fd.pitch_video_url,
    fd.created_at,
    CASE 
        WHEN s.compliance_status = 'Compliant' THEN '✅ Startup Nation Verified'
        ELSE '⏳ Pending Verification'
    END as verification_status
FROM startups s
JOIN fundraising_details fd ON s.id = fd.startup_id
WHERE fd.active = true
ORDER BY fd.created_at DESC;

-- Summary statistics
SELECT 
    COUNT(*) as total_active_fundraising,
    COUNT(CASE WHEN s.compliance_status = 'Compliant' THEN 1 END) as verified_startups,
    COUNT(CASE WHEN s.compliance_status != 'Compliant' THEN 1 END) as pending_startups,
    SUM(fd.value) as total_investment_ask,
    AVG(fd.equity) as average_equity_offered,
    COUNT(CASE WHEN fd.type = 'Series A' THEN 1 END) as series_a_count,
    COUNT(CASE WHEN fd.type = 'Seed' THEN 1 END) as seed_count,
    COUNT(CASE WHEN fd.type = 'Pre-Seed' THEN 1 END) as pre_seed_count
FROM fundraising_details fd
JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true;

-- Show sector distribution
SELECT 
    s.sector,
    COUNT(*) as startup_count,
    SUM(fd.value) as total_investment_ask,
    AVG(fd.equity) as average_equity
FROM fundraising_details fd
JOIN startups s ON fd.startup_id = s.id
WHERE fd.active = true
GROUP BY s.sector
ORDER BY startup_count DESC;

