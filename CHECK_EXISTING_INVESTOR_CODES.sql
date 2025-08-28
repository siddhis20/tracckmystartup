-- CHECK_EXISTING_INVESTOR_CODES.sql
-- Check which existing users have investor codes and which ones are missing them

-- Step 1: Check all users and their investor code status
SELECT 
    'All Users Status' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ Missing Code'
        WHEN investor_code = '' THEN '⚠️ Empty Code'
        WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN '✅ Valid Code'
        ELSE '⚠️ Invalid Format'
    END as code_status
FROM users 
ORDER BY created_at DESC;

-- Step 2: Focus on investors specifically
SELECT 
    'Investors Only - Detailed Status' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ CRITICAL: Missing Investor Code'
        WHEN investor_code = '' THEN '⚠️ WARNING: Empty Investor Code'
        WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN '✅ OK: Valid Investor Code'
        ELSE '⚠️ WARNING: Invalid Code Format'
    END as code_status
FROM users 
WHERE role = 'Investor'
ORDER BY created_at DESC;

-- Step 3: Count users by role and code status
SELECT 
    'User Count by Role and Code Status' as check_type,
    role,
    COUNT(*) as total_users,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes,
    COUNT(CASE WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN 1 END) as valid_format,
    COUNT(CASE WHEN investor_code IS NOT NULL AND investor_code !~ '^INV-[A-Z0-9]{6}$' THEN 1 END) as invalid_format
FROM users 
GROUP BY role
ORDER BY role;

-- Step 4: Summary for investors only
SELECT 
    'Investors Summary' as check_type,
    COUNT(*) as total_investors,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes,
    CASE 
        WHEN COUNT(*) - COUNT(investor_code) = 0 THEN '✅ All investors have codes'
        ELSE '❌ Some investors missing codes'
    END as overall_status
FROM users 
WHERE role = 'Investor';

-- Step 5: Show specific users missing codes
SELECT 
    'Users Missing Investor Codes' as check_type,
    id,
    email,
    role,
    created_at
FROM users 
WHERE role = 'Investor' 
AND (investor_code IS NULL OR investor_code = '')
ORDER BY created_at DESC;

-- Step 6: Show users with valid codes
SELECT 
    'Users with Valid Investor Codes' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at
FROM users 
WHERE role = 'Investor' 
AND investor_code ~ '^INV-[A-Z0-9]{6}$'
ORDER BY created_at DESC;

-- Step 7: Check for any duplicate codes
SELECT 
    'Duplicate Code Check' as check_type,
    investor_code,
    COUNT(*) as users_with_code,
    array_agg(email) as users_list
FROM users 
WHERE investor_code IS NOT NULL 
AND investor_code != ''
GROUP BY investor_code
HAVING COUNT(*) > 1;

-- Step 8: Final assessment
SELECT 
    'FINAL ASSESSMENT' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE role = 'Investor' AND (investor_code IS NULL OR investor_code = '')
        ) THEN '❌ ACTION REQUIRED: Some investors missing codes'
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE role = 'Investor' AND investor_code !~ '^INV-[A-Z0-9]{6}$'
        ) THEN '⚠️ ATTENTION: Some codes have invalid format'
        ELSE '✅ SYSTEM READY: All investors have valid codes'
    END as system_status;

