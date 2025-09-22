-- Quick check for new compliance tables
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'auditor_types') 
        THEN '✅ auditor_types EXISTS' 
        ELSE '❌ auditor_types MISSING' 
    END as auditor_types_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'governance_types') 
        THEN '✅ governance_types EXISTS' 
        ELSE '❌ governance_types MISSING' 
    END as governance_types_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'company_types') 
        THEN '✅ company_types EXISTS' 
        ELSE '❌ company_types MISSING' 
    END as company_types_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'compliance_rules_new') 
        THEN '✅ compliance_rules_new EXISTS' 
        ELSE '❌ compliance_rules_new MISSING' 
    END as compliance_rules_new_status;
