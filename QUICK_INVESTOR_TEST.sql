-- QUICK_INVESTOR_TEST.sql
-- Quick test to verify investor code system is working

-- Test 1: Check if the specific user now has an investor code
SELECT 
    'User Status Check' as test_name,
    id,
    email,
    role,
    investor_code,
    CASE 
        WHEN investor_code IS NULL THEN '❌ FAILED: Still missing code'
        WHEN investor_code = '' THEN '⚠️ WARNING: Empty code'
        WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN '✅ PASSED: Valid code format'
        ELSE '⚠️ WARNING: Invalid code format'
    END as test_result
FROM users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- Test 2: Check all investors have codes
SELECT 
    'All Investors Check' as test_name,
    COUNT(*) as total_investors,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes,
    CASE 
        WHEN COUNT(*) - COUNT(investor_code) = 0 THEN '✅ PASSED: All investors have codes'
        ELSE '❌ FAILED: Some investors missing codes'
    END as test_result
FROM users 
WHERE role = 'Investor';

-- Test 3: Verify code format validity
SELECT 
    'Code Format Validation' as test_name,
    COUNT(*) as total_codes,
    COUNT(CASE WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN 1 END) as valid_format,
    COUNT(CASE WHEN investor_code !~ '^INV-[A-Z0-9]{6}$' THEN 1 END) as invalid_format,
    CASE 
        WHEN COUNT(CASE WHEN investor_code !~ '^INV-[A-Z0-9]{6}$' THEN 1 END) = 0 THEN '✅ PASSED: All codes have valid format'
        ELSE '❌ FAILED: Some codes have invalid format'
    END as test_result
FROM users 
WHERE role = 'Investor' AND investor_code IS NOT NULL;

-- Test 4: Show sample of working codes
SELECT 
    'Sample Working Codes' as test_name,
    email,
    investor_code,
    created_at
FROM users 
WHERE role = 'Investor' 
AND investor_code IS NOT NULL
ORDER BY created_at DESC 
LIMIT 3;

-- Test 5: Final status
SELECT 
    'FINAL STATUS' as test_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE role = 'Investor' AND (investor_code IS NULL OR investor_code = '')
        ) THEN '❌ SYSTEM NOT READY: Some investors missing codes'
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE role = 'Investor' AND investor_code !~ '^INV-[A-Z0-9]{6}$'
        ) THEN '⚠️ SYSTEM PARTIALLY READY: Some codes have invalid format'
        ELSE '✅ SYSTEM READY: All investors have valid codes'
    END as overall_status;

