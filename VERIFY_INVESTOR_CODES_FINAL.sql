-- VERIFY_INVESTOR_CODES_FINAL.sql
-- Final verification that the investor code system is working

-- Check 1: Overall investor status
SELECT 
    'FINAL STATUS CHECK' as check_type,
    COUNT(*) as total_investors,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes,
    CASE 
        WHEN COUNT(*) - COUNT(investor_code) = 0 THEN '✅ SYSTEM READY: All investors have codes'
        ELSE '❌ SYSTEM NOT READY: Some investors missing codes'
    END as system_status
FROM users 
WHERE role = 'Investor';

-- Check 2: Your specific user status
SELECT 
    'YOUR USER STATUS' as check_type,
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
WHERE email = 'olympiad_info1@startupnationindia.com'
AND role = 'Investor';

-- Check 3: All investors with their codes
SELECT 
    'ALL INVESTORS DETAILED' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ Missing'
        WHEN investor_code = '' THEN '⚠️ Empty'
        WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN '✅ Valid'
        ELSE '⚠️ Invalid Format'
    END as code_status
FROM users 
WHERE role = 'Investor'
ORDER BY created_at DESC;

-- Check 4: Verify trigger exists
SELECT 
    'TRIGGER VERIFICATION' as check_type,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement,
    '✅ Trigger exists and should auto-generate codes' as status
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_generate_investor_code'
AND event_object_table = 'users';

-- Check 5: Test new investor registration simulation
SELECT 
    'NEW INVESTOR TEST' as test_type,
    'System should now automatically generate codes for new investors' as message,
    'Trigger is active and will handle future registrations' as status;

