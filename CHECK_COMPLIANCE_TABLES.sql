-- =====================================================
-- COMPLIANCE TABLES DIAGNOSTIC SCRIPT
-- =====================================================
-- This script checks what compliance-related tables exist and their data

-- 1. Check if all compliance tables exist
SELECT 
    'Table Existence Check' as check_type,
    schemaname,
    tablename,
    CASE 
        WHEN tablename IN ('compliance_rules', 'compliance_rules_new', 'auditor_types', 'governance_types', 'company_types') 
        THEN '✅ EXISTS' 
        ELSE '❌ MISSING' 
    END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE '%compliance%' 
   OR tablename IN ('auditor_types', 'governance_types', 'company_types')
ORDER BY tablename;

-- 2. Check data counts in each table
SELECT 'compliance_rules' as table_name, COUNT(*) as record_count FROM compliance_rules
UNION ALL
SELECT 'compliance_rules_new' as table_name, COUNT(*) as record_count FROM compliance_rules_new
UNION ALL
SELECT 'auditor_types' as table_name, COUNT(*) as record_count FROM auditor_types
UNION ALL
SELECT 'governance_types' as table_name, COUNT(*) as record_count FROM governance_types
UNION ALL
SELECT 'company_types' as table_name, COUNT(*) as record_count FROM company_types;

-- 3. Sample data from each table
SELECT 'compliance_rules sample' as info, country_code, rules FROM compliance_rules LIMIT 3;

SELECT 'compliance_rules_new sample' as info, name, country_code, frequency, validation_required 
FROM compliance_rules_new LIMIT 3;

SELECT 'auditor_types sample' as info, name, description FROM auditor_types LIMIT 3;

SELECT 'governance_types sample' as info, name, description FROM governance_types LIMIT 3;

SELECT 'company_types sample' as info, name, country_code, description FROM company_types LIMIT 3;

-- 4. Check if there are any views
SELECT 
    'Views Check' as check_type,
    schemaname,
    viewname,
    'VIEW EXISTS' as status
FROM pg_views 
WHERE schemaname = 'public' 
  AND viewname LIKE '%compliance%'
ORDER BY viewname;
