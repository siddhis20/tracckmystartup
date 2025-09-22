-- =====================================================
-- FIX MISSING STARTUP SHARES RECORDS
-- =====================================================
-- This script fixes the issue where existing startups don't have 
-- startup_shares records, causing price per share to reset to 0

-- First, let's see which startups are missing startup_shares records
SELECT 
    s.id,
    s.name,
    s.user_id,
    s.created_at,
    CASE 
        WHEN ss.startup_id IS NULL THEN 'MISSING startup_shares record'
        ELSE 'HAS startup_shares record'
    END as shares_status
FROM startups s
LEFT JOIN startup_shares ss ON s.id = ss.startup_id
ORDER BY s.id;

-- Create startup_shares records for startups that don't have them
INSERT INTO startup_shares (startup_id, total_shares, price_per_share, esop_reserved_shares, updated_at)
SELECT 
    s.id as startup_id,
    1000000 as total_shares,  -- Default to 1 million shares
    1.0 as price_per_share,   -- Default to $1.00 per share
    0 as esop_reserved_shares, -- Default to 0 ESOP shares
    NOW() as updated_at
FROM startups s
LEFT JOIN startup_shares ss ON s.id = ss.startup_id
WHERE ss.startup_id IS NULL  -- Only for startups without startup_shares records
ON CONFLICT (startup_id) DO NOTHING;  -- Don't overwrite existing records

-- Verify the fix
SELECT 
    s.id,
    s.name,
    ss.total_shares,
    ss.price_per_share,
    ss.esop_reserved_shares,
    ss.updated_at
FROM startups s
LEFT JOIN startup_shares ss ON s.id = ss.startup_id
ORDER BY s.id;

-- Show summary
SELECT 
    COUNT(*) as total_startups,
    COUNT(ss.startup_id) as startups_with_shares,
    COUNT(*) - COUNT(ss.startup_id) as startups_missing_shares
FROM startups s
LEFT JOIN startup_shares ss ON s.id = ss.startup_id;

