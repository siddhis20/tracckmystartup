-- =====================================================
-- SIMPLE DELETE TEST
-- =====================================================
-- This script simply tests that delete operations work without ID type assumptions

-- First, let's check the current data counts
SELECT 'investment_records' as table_name, COUNT(*) as record_count FROM investment_records
UNION ALL
SELECT 'financial_records' as table_name, COUNT(*) as record_count FROM financial_records
UNION ALL
SELECT 'employees' as table_name, COUNT(*) as record_count FROM employees
UNION ALL
SELECT 'fundraising_details' as table_name, COUNT(*) as record_count FROM fundraising_details;

-- Check table structure to understand ID types
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('investment_records', 'financial_records', 'employees', 'fundraising_details')
    AND column_name = 'id'
ORDER BY table_name;

-- Check sample data in each table
SELECT 'investment_records' as table_name, id, startup_id, investor_name, amount FROM investment_records LIMIT 3;
SELECT 'financial_records' as table_name, id, startup_id, record_type, amount FROM financial_records LIMIT 3;
SELECT 'employees' as table_name, id, startup_id, name, department FROM employees LIMIT 3;
SELECT 'fundraising_details' as table_name, id, startup_id, type, value FROM fundraising_details LIMIT 3;

-- Simple manual delete test (you can run these one by one)
-- Replace the IDs with actual IDs from your data

-- Test 1: Try to delete one investment record (replace with actual ID)
-- DELETE FROM investment_records WHERE id = 'actual-uuid-here' LIMIT 1;

-- Test 2: Try to delete one financial record (replace with actual ID)
-- DELETE FROM financial_records WHERE id = 'actual-uuid-here' LIMIT 1;

-- Test 3: Try to delete one employee (replace with actual ID)
-- DELETE FROM employees WHERE id = 'actual-uuid-here' LIMIT 1;

-- Test 4: Try to delete one fundraising detail (replace with actual ID)
-- DELETE FROM fundraising_details WHERE id = 'actual-uuid-here' LIMIT 1;

-- Verify RLS policies are working
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('investment_records', 'financial_records', 'employees', 'fundraising_details')
    AND schemaname = 'public'
ORDER BY tablename, cmd;
