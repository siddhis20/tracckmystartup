-- TEST_INVESTOR_CODE_SYSTEM_COMPREHENSIVE.sql
-- Comprehensive diagnostic script to debug investor code system

-- Step 1: Check database structure
SELECT '=== DATABASE STRUCTURE CHECK ===' as info;

-- Check if investor_code column exists in users table
SELECT 
    'users table structure' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('investor_code', 'id', 'email', 'role')
ORDER BY column_name;

-- Check if investor_code column exists in investment_records table
SELECT 
    'investment_records table structure' as check_type,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'investment_records' 
AND column_name = 'investor_code';

-- Step 2: Check current data state
SELECT '=== CURRENT DATA STATE ===' as info;

-- Show all users with their roles and investor codes
SELECT 
    'All users with roles and codes' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ Missing Code'
        WHEN investor_code = '' THEN '⚠️ Empty Code'
        ELSE '✅ Has Code'
    END as code_status
FROM users 
ORDER BY created_at DESC;

-- Step 3: Focus on investors specifically
SELECT '=== INVESTOR ANALYSIS ===' as info;

-- Show all investors and their codes
SELECT 
    'Investors analysis' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ Missing Code'
        WHEN investor_code = '' THEN '⚠️ Empty Code'
        WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN '✅ Valid Format'
        ELSE '⚠️ Invalid Format'
    END as code_status
FROM users 
WHERE role = 'Investor'
ORDER BY created_at DESC;

-- Count investors by code status
SELECT 
    'Investor code status summary' as check_type,
    COUNT(*) as total_investors,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes,
    COUNT(CASE WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN 1 END) as valid_format,
    COUNT(CASE WHEN investor_code IS NOT NULL AND investor_code !~ '^INV-[A-Z0-9]{6}$' THEN 1 END) as invalid_format
FROM users 
WHERE role = 'Investor';

-- Step 4: Check investment records
SELECT '=== INVESTMENT RECORDS ANALYSIS ===' as info;

-- Show all investment records with investor codes
SELECT 
    'Investment records with investor codes' as check_type,
    id,
    startup_id,
    investor_name,
    investor_code,
    amount,
    equity_allocated,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ Missing Code'
        WHEN investor_code = '' THEN '⚠️ Empty Code'
        ELSE '✅ Has Code'
    END as code_status
FROM investment_records 
ORDER BY created_at DESC;

-- Count investment records by code status
SELECT 
    'Investment records code status summary' as check_type,
    COUNT(*) as total_records,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes
FROM investment_records;

-- Step 5: Check for orphaned records
SELECT '=== ORPHANED RECORDS CHECK ===' as info;

-- Check for investment records with investor codes that don't exist in users table
SELECT 
    'Orphaned investment records' as check_type,
    ir.id,
    ir.startup_id,
    ir.investor_name,
    ir.investor_code,
    ir.amount,
    ir.created_at
FROM investment_records ir
LEFT JOIN users u ON ir.investor_code = u.investor_code
WHERE ir.investor_code IS NOT NULL 
AND u.id IS NULL
ORDER BY ir.created_at DESC;

-- Step 6: Test data integrity
SELECT '=== DATA INTEGRITY CHECK ===' as info;

-- Check if there are any duplicate investor codes
SELECT 
    'Duplicate investor codes check' as check_type,
    investor_code,
    COUNT(*) as count,
    array_agg(email) as users_with_code
FROM users 
WHERE investor_code IS NOT NULL 
AND investor_code != ''
GROUP BY investor_code
HAVING COUNT(*) > 1;

-- Step 7: Sample data for debugging
SELECT '=== SAMPLE DATA FOR DEBUGGING ===' as info;

-- Show recent users with full details
SELECT 
    'Recent users sample' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at,
    CASE 
        WHEN role = 'Investor' AND investor_code IS NULL THEN '❌ Investor without code'
        WHEN role = 'Investor' AND investor_code IS NOT NULL THEN '✅ Investor with code'
        ELSE 'ℹ️ Non-investor user'
    END as status
FROM users 
ORDER BY created_at DESC 
LIMIT 10;

-- Show recent investment records with startup names
SELECT 
    'Recent investment records sample' as check_type,
    ir.id,
    ir.startup_id,
    s.name as startup_name,
    ir.investor_name,
    ir.investor_code,
    ir.amount,
    ir.equity_allocated,
    ir.created_at
FROM investment_records ir
LEFT JOIN startups s ON ir.startup_id = s.id
ORDER BY ir.created_at DESC
LIMIT 10;

-- Step 8: Recommendations
SELECT '=== RECOMMENDATIONS ===' as info;

-- Generate recommendations based on findings
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE role = 'Investor' AND investor_code IS NULL
        ) THEN '❌ Run ADD_INVESTOR_CODE_COLUMN.sql to generate missing codes'
        ELSE '✅ All investors have codes'
    END as recommendation_1,
    
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM investment_records 
            WHERE investor_code IS NULL
        ) THEN '⚠️ Some investment records missing investor codes'
        ELSE '✅ All investment records have codes'
    END as recommendation_2,
    
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE investor_code IS NOT NULL 
            AND investor_code !~ '^INV-[A-Z0-9]{6}$'
        ) THEN '⚠️ Some investor codes have invalid format'
        ELSE '✅ All investor codes have valid format'
    END as recommendation_3;

