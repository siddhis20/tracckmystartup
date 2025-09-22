
-- Test script to check compliance setup
-- Run this to see what's currently in your database

-- 1. Check if compliance_rules table exists and has data
SELECT 'compliance_rules table:' as test;
SELECT country_code, rules FROM compliance_rules ORDER BY country_code;

-- 2. Check if the RPC function exists
SELECT 'RPC function exists:' as test;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'generate_compliance_tasks_for_startup';

-- 3. Check startup profile data
SELECT 'Startup profile data:' as test;
SELECT id, name, country_of_registration, company_type, registration_date 
FROM startups 
ORDER BY id;

-- 4. Check subsidiaries data
SELECT 'Subsidiaries data:' as test;
SELECT id, startup_id, country, company_type, registration_date 
FROM subsidiaries 
ORDER BY startup_id, id;

-- 5. Check international operations data
SELECT 'International operations data:' as test;
SELECT id, startup_id, country, company_type, start_date 
FROM international_ops 
ORDER BY startup_id, id;

-- 6. Test the RPC function with a specific startup (replace :startup_id with actual ID)
-- SELECT 'Test RPC function:' as test;
-- SELECT * FROM generate_compliance_tasks_for_startup(1); -- Replace 1 with actual startup ID
