-- Check if tables have data
SELECT 
    'auditor_types' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as status
FROM auditor_types
UNION ALL
SELECT 
    'governance_types' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as status
FROM governance_types
UNION ALL
SELECT 
    'company_types' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as status
FROM company_types
UNION ALL
SELECT 
    'compliance_rules_new' as table_name, 
    COUNT(*) as record_count,
    CASE WHEN COUNT(*) > 0 THEN '✅ HAS DATA' ELSE '❌ EMPTY' END as status
FROM compliance_rules_new;
