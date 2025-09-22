-- =====================================================
-- CHECK DATABASE COLUMNS FOR INVESTMENT ADVISOR CODE
-- =====================================================

-- 1. Check if investment_advisor_code_entered column exists in users table
SELECT 
  'Column Check' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
  AND column_name LIKE '%investment_advisor%'
ORDER BY column_name;

-- 2. Check all columns in users table to see what's available
SELECT 
  'All Users Columns' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'public'
ORDER BY column_name;

-- 3. Test if we can insert/update investment_advisor_code_entered
-- This will fail if the column doesn't exist
SELECT 
  'Test Update' as info,
  'Testing if investment_advisor_code_entered column exists' as message;

