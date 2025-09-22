-- =====================================================
-- FULL COMPLIANCE TABLES DIAGNOSTIC
-- =====================================================
-- This script provides a complete overview of your compliance system

-- 1. Check all compliance-related tables and views
SELECT 
    'Tables & Views' as category,
    schemaname,
    tablename as name,
    'table' as type
FROM pg_tables 
WHERE schemaname = 'public' 
  AND (tablename LIKE '%compliance%' OR tablename IN ('auditor_types', 'governance_types', 'company_types'))
UNION ALL
SELECT 
    'Tables & Views' as category,
    schemaname,
    viewname as name,
    'view' as type
FROM pg_views 
WHERE schemaname = 'public' 
  AND viewname LIKE '%compliance%'
ORDER BY name;

-- 2. Check record counts in each table
SELECT 
    'Record Counts' as category,
    'compliance_rules' as table_name, 
    COUNT(*) as record_count 
FROM compliance_rules
UNION ALL
SELECT 
    'Record Counts' as category,
    'compliance_rules_new' as table_name, 
    COUNT(*) as record_count 
FROM compliance_rules_new
UNION ALL
SELECT 
    'Record Counts' as category,
    'auditor_types' as table_name, 
    COUNT(*) as record_count 
FROM auditor_types
UNION ALL
SELECT 
    'Record Counts' as category,
    'governance_types' as table_name, 
    COUNT(*) as record_count 
FROM governance_types
UNION ALL
SELECT 
    'Record Counts' as category,
    'company_types' as table_name, 
    COUNT(*) as record_count 
FROM company_types;

-- 3. Sample data from compliance_rules (old structure)
SELECT 
    'compliance_rules (old)' as source,
    country_code,
    jsonb_object_keys(rules) as company_types,
    jsonb_pretty(rules) as rules_structure
FROM compliance_rules 
LIMIT 2;

-- 4. Sample data from compliance_rules_new (new structure)
SELECT 
    'compliance_rules_new (new)' as source,
    cr.name as rule_name,
    cr.country_code,
    ct.name as company_type,
    cr.frequency,
    cr.validation_required
FROM compliance_rules_new cr
JOIN company_types ct ON cr.company_type_id = ct.id
LIMIT 5;

-- 5. Sample data from auditor_types
SELECT 
    'auditor_types' as source,
    name,
    description
FROM auditor_types
LIMIT 5;

-- 6. Sample data from governance_types
SELECT 
    'governance_types' as source,
    name,
    description
FROM governance_types
LIMIT 5;

-- 7. Sample data from company_types
SELECT 
    'company_types' as source,
    name,
    country_code,
    description
FROM company_types
ORDER BY country_code, name
LIMIT 10;

-- 8. Check the compliance_rules_view structure
SELECT 
    'compliance_rules_view' as source,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'compliance_rules_view'
ORDER BY ordinal_position;
