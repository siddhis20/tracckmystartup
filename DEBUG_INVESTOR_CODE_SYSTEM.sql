-- DEBUG_INVESTOR_CODE_SYSTEM.sql
-- Diagnostic script to debug investor code system

-- 1. Check if investor_code column exists in users table
SELECT 
    'users table investor_code column' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'investor_code';

-- 2. Check if investor_code column exists in investment_records table
SELECT 
    'investment_records table investor_code column' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'investment_records' 
AND column_name = 'investor_code';

-- 3. Show all investors and their codes
SELECT 
    'Investors with codes' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at
FROM users 
WHERE role = 'Investor'
ORDER BY created_at DESC;

-- 4. Show all investment records with investor codes
SELECT 
    'Investment records with investor codes' as check_type,
    id,
    startup_id,
    investor_name,
    investor_code,
    amount,
    equity_allocated,
    created_at
FROM investment_records 
WHERE investor_code IS NOT NULL
ORDER BY created_at DESC;

-- 5. Show investment records without investor codes
SELECT 
    'Investment records WITHOUT investor codes' as check_type,
    id,
    startup_id,
    investor_name,
    investor_code,
    amount,
    equity_allocated,
    created_at
FROM investment_records 
WHERE investor_code IS NULL
ORDER BY created_at DESC;

-- 6. Count total investment records
SELECT 
    'Total investment records' as check_type,
    COUNT(*) as total_records,
    COUNT(investor_code) as records_with_investor_code,
    COUNT(*) - COUNT(investor_code) as records_without_investor_code
FROM investment_records;

-- 7. Show recent investment records (last 10)
SELECT 
    'Recent investment records' as check_type,
    id,
    startup_id,
    investor_name,
    investor_code,
    amount,
    equity_allocated,
    date,
    created_at
FROM investment_records 
ORDER BY created_at DESC 
LIMIT 10;

-- 8. Check if there are any investment records at all
SELECT 
    'Investment records count' as check_type,
    COUNT(*) as total_count
FROM investment_records;

-- 9. Show startup names for investment records
SELECT 
    'Investment records with startup names' as check_type,
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
