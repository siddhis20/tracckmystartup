-- =====================================================
-- DATA VERIFICATION SCRIPT
-- =====================================================
-- This script helps verify that data from registration form is properly saved and can be loaded

-- Step 1: Check if founders table has the correct structure
SELECT 
    'Founders table structure check:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'founders'
ORDER BY ordinal_position;

-- Step 2: Check if startup_shares table has the correct structure
SELECT 
    'Startup shares table structure check:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'startup_shares'
ORDER BY ordinal_position;

-- Step 3: Check if startup_profiles table has the correct structure
SELECT 
    'Startup profiles table structure check:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'startup_profiles'
ORDER BY ordinal_position;

-- Step 4: Check if investment_records table has shares columns
SELECT 
    'Investment records table structure check:' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'investment_records'
AND column_name IN ('shares', 'price_per_share')
ORDER BY ordinal_position;

-- Step 5: Sample data check - show recent startups with their data
SELECT 
    'Recent startups with their data:' as info,
    s.id,
    s.name,
    s.created_at,
    COUNT(f.id) as founder_count,
    ss.total_shares,
    ss.price_per_share,
    ss.esop_reserved_shares
FROM startups s
LEFT JOIN founders f ON f.startup_id = s.id
LEFT JOIN startup_shares ss ON ss.startup_id = s.id
GROUP BY s.id, s.name, s.created_at, ss.total_shares, ss.price_per_share, ss.esop_reserved_shares
ORDER BY s.created_at DESC
LIMIT 5;

-- Step 6: Sample founders data
SELECT 
    'Sample founders data:' as info,
    f.startup_id,
    f.name,
    f.email,
    f.shares,
    f.equity_percentage,
    f.created_at
FROM founders f
ORDER BY f.created_at DESC
LIMIT 10;

-- Step 7: Sample startup shares data
SELECT 
    'Sample startup shares data:' as info,
    ss.startup_id,
    ss.total_shares,
    ss.price_per_share,
    ss.esop_reserved_shares,
    ss.updated_at
FROM startup_shares ss
ORDER BY ss.updated_at DESC
LIMIT 10;

-- Step 8: Sample startup profiles data
SELECT 
    'Sample startup profiles data:' as info,
    sp.startup_id,
    sp.country,
    sp.company_type,
    sp.currency,
    sp.total_shares,
    sp.price_per_share,
    sp.esop_reserved_shares,
    sp.created_at
FROM startup_profiles sp
ORDER BY sp.created_at DESC
LIMIT 10;


