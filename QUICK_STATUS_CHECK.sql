-- QUICK_STATUS_CHECK.sql
-- Quick check to see current status

-- 1. Check if columns exist
SELECT 'Columns exist?' as check_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'investor_code') 
           THEN 'YES - users.investor_code exists'
           ELSE 'NO - users.investor_code missing'
       END as users_column,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'investment_records' AND column_name = 'investor_code') 
           THEN 'YES - investment_records.investor_code exists'
           ELSE 'NO - investment_records.investor_code missing'
       END as investment_column;

-- 2. Count investors and their codes
SELECT 'Investor count' as check_type,
       COUNT(*) as total_investors,
       COUNT(investor_code) as with_codes,
       COUNT(*) - COUNT(investor_code) as without_codes
FROM users WHERE role = 'Investor';

-- 3. Show all investors
SELECT 'All investors' as check_type,
       email,
       investor_code,
       created_at
FROM users 
WHERE role = 'Investor'
ORDER BY created_at DESC;

-- 4. Count investment records
SELECT 'Investment records' as check_type,
       COUNT(*) as total_records,
       COUNT(investor_code) as with_codes,
       COUNT(*) - COUNT(investor_code) as without_codes
FROM investment_records;

-- 5. Show recent investment records
SELECT 'Recent investments' as check_type,
       id,
       startup_id,
       investor_name,
       investor_code,
       amount,
       created_at
FROM investment_records 
ORDER BY created_at DESC 
LIMIT 5;
