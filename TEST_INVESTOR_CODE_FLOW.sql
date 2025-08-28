-- TEST_INVESTOR_CODE_FLOW.sql
-- Test script to debug investor code flow

-- Step 1: First, let's run the setup script to ensure columns exist
-- Run ADD_INVESTOR_CODE_COLUMN.sql first if you haven't already

-- Step 2: Check current state
SELECT '=== CURRENT STATE ===' as info;

-- Check if columns exist
SELECT 
    'Column check' as step,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('users', 'investment_records')
AND column_name = 'investor_code';

-- Step 3: Show all investors
SELECT 
    'All investors' as step,
    id,
    email,
    role,
    investor_code,
    created_at
FROM users 
WHERE role = 'Investor'
ORDER BY created_at DESC;

-- Step 4: Show all investment records
SELECT 
    'All investment records' as step,
    id,
    startup_id,
    investor_name,
    investor_code,
    amount,
    equity_allocated,
    created_at
FROM investment_records 
ORDER BY created_at DESC;

-- Step 5: Test specific investor code lookup
-- Replace 'YOUR_INVESTOR_CODE_HERE' with the actual investor code you used
SELECT 
    'Test specific investor code' as step,
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
WHERE ir.investor_code = 'YOUR_INVESTOR_CODE_HERE'  -- Replace this with actual code
ORDER BY ir.created_at DESC;

-- Step 6: Show recent investments with startup names
SELECT 
    'Recent investments with startup names' as step,
    ir.id,
    ir.startup_id,
    s.name as startup_name,
    ir.investor_name,
    ir.investor_code,
    ir.amount,
    ir.equity_allocated,
    ir.date,
    ir.created_at
FROM investment_records ir
LEFT JOIN startups s ON ir.startup_id = s.id
ORDER BY ir.created_at DESC
LIMIT 5;

-- Step 7: Check for any investment records without investor codes
SELECT 
    'Investments without investor codes' as step,
    COUNT(*) as count
FROM investment_records 
WHERE investor_code IS NULL OR investor_code = '';

-- Step 8: Show sample data for debugging
SELECT 
    'Sample data for debugging' as step,
    'users' as table_name,
    COUNT(*) as record_count,
    COUNT(investor_code) as with_investor_code
FROM users 
WHERE role = 'Investor'

UNION ALL

SELECT 
    'Sample data for debugging' as step,
    'investment_records' as table_name,
    COUNT(*) as record_count,
    COUNT(investor_code) as with_investor_code
FROM investment_records;
