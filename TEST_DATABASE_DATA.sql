-- =====================================================
-- TEST DATABASE DATA SCRIPT
-- =====================================================
-- This script checks if the registration data exists in the database

-- Step 1: Check if startup exists
SELECT 
    'Startup exists check:' as info,
    id,
    name,
    user_id,
    created_at
FROM startups 
WHERE id = 54;

-- Step 2: Check if founders exist for this startup
SELECT 
    'Founders check:' as info,
    startup_id,
    name,
    email,
    shares,
    equity_percentage,
    created_at
FROM founders 
WHERE startup_id = 54;

-- Step 3: Check if startup_shares exist for this startup
SELECT 
    'Startup shares check:' as info,
    startup_id,
    total_shares,
    price_per_share,
    esop_reserved_shares,
    updated_at
FROM startup_shares 
WHERE startup_id = 54;

-- Step 4: Check if startup_profiles exist for this startup
SELECT 
    'Startup profiles check:' as info,
    startup_id,
    country,
    company_type,
    currency,
    total_shares,
    price_per_share,
    esop_reserved_shares,
    created_at
FROM startup_profiles 
WHERE startup_id = 54;

-- Step 5: Check all startups with their related data
SELECT 
    'All startups with related data:' as info,
    s.id,
    s.name,
    COUNT(f.id) as founder_count,
    ss.total_shares,
    ss.esop_reserved_shares,
    sp.total_shares as profile_total_shares,
    sp.esop_reserved_shares as profile_esop_shares
FROM startups s
LEFT JOIN founders f ON f.startup_id = s.id
LEFT JOIN startup_shares ss ON ss.startup_id = s.id
LEFT JOIN startup_profiles sp ON sp.startup_id = s.id
GROUP BY s.id, s.name, ss.total_shares, ss.esop_reserved_shares, sp.total_shares, sp.esop_reserved_shares
ORDER BY s.created_at DESC;


