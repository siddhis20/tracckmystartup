-- DEBUG_INVESTOR_CODE_FLOW.sql
-- Debug the investor code flow from startup dashboard to investor dashboard

-- Check 1: Verify startup_addition_requests table structure
SELECT 
    'STARTUP_ADDITION_REQUESTS TABLE STRUCTURE' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startup_addition_requests'
ORDER BY ordinal_position;

-- Check 2: Check if there are any startup addition requests
SELECT 
    'EXISTING STARTUP ADDITION REQUESTS' as check_type,
    COUNT(*) as total_requests,
    COUNT(investor_code) as with_investor_codes,
    COUNT(*) - COUNT(investor_code) as without_investor_codes
FROM startup_addition_requests;

-- Check 3: Show all startup addition requests with details
SELECT 
    'ALL STARTUP ADDITION REQUESTS DETAILED' as check_type,
    id,
    name,
    investment_type,
    investment_value,
    equity_allocation,
    sector,
    investor_code,
    status,
    created_at
FROM startup_addition_requests
ORDER BY created_at DESC;

-- Check 4: Check investment_records table for investor codes
SELECT 
    'INVESTMENT RECORDS WITH INVESTOR CODES' as check_type,
    COUNT(*) as total_records,
    COUNT(investor_code) as with_investor_codes,
    COUNT(*) - COUNT(investor_code) as without_investor_codes
FROM investment_records;

-- Check 5: Show recent investment records with investor codes
SELECT 
    'RECENT INVESTMENT RECORDS' as check_type,
    id,
    startup_id,
    investor_name,
    investor_code,
    amount,
    equity_allocated,
    date,
    created_at
FROM investment_records
WHERE investor_code IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- Check 6: Check if your user has an investor code
SELECT 
    'YOUR USER INVESTOR CODE STATUS' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at
FROM users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- Check 7: Check all investors and their codes
SELECT 
    'ALL INVESTORS AND THEIR CODES' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at
FROM users 
WHERE role = 'Investor'
ORDER BY created_at DESC;

-- Check 8: Test the flow - what should happen when startup adds investor code
SELECT 
    'FLOW TEST' as check_type,
    'When startup adds investment with investor code:' as step_1,
    '1. Investment record created in investment_records table' as step_2,
    '2. handleInvestorAdded callback should create startup addition request' as step_3,
    '3. Request should appear in startup_addition_requests table' as step_4,
    '4. Request should show in investor dashboard' as step_5;

