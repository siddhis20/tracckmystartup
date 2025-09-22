-- =====================================================
-- COMPREHENSIVE VERIFICATION MAPPING FIX
-- =====================================================
-- This script provides a comprehensive mapping for all country-specific verification types
-- to standard CA/CS requirements

-- First, let's see what verification types currently exist in the database
SELECT 
    verification_required,
    COUNT(*) as count,
    STRING_AGG(DISTINCT country_code, ', ') as countries
FROM public.compliance_rules_comprehensive
GROUP BY verification_required
ORDER BY verification_required;

-- Create a comprehensive mapping table for verification types
-- This can be used as reference for the bulk uploader fix
CREATE TEMP TABLE verification_mapping AS
SELECT * FROM (VALUES
    -- Standard types
    ('CA', 'CA'),
    ('CS', 'CS'),
    ('both', 'both'),
    
    -- Tax/Accounting related (CA equivalent)
    ('Tax Advisor/Auditor', 'CA'),
    ('Tax Advisor', 'CA'),
    ('Auditor', 'CA'),
    ('Chartered Accountant', 'CA'),
    ('Certified Public Accountant', 'CA'),
    ('CPA', 'CA'),
    ('Tax Consultant', 'CA'),
    ('Financial Advisor', 'CA'),
    ('Accounting Professional', 'CA'),
    
    -- Legal/Management related (CS equivalent)
    ('Management/Lawyer', 'CS'),
    ('Management', 'CS'),
    ('Lawyer', 'CS'),
    ('Legal Advisor', 'CS'),
    ('Company Secretary', 'CS'),
    ('Corporate Secretary', 'CS'),
    ('Legal Counsel', 'CS'),
    ('Corporate Lawyer', 'CS'),
    ('Business Lawyer', 'CS'),
    ('Corporate Governance', 'CS'),
    
    -- Both required
    ('Both', 'both'),
    ('CA and CS', 'both'),
    ('Chartered Accountant and Company Secretary', 'both'),
    ('Tax Advisor and Legal Advisor', 'both'),
    ('Auditor and Lawyer', 'both')
) AS mapping(original_type, mapped_type);

-- Show the mapping
SELECT * FROM verification_mapping ORDER BY original_type;

-- Update existing records based on the mapping
UPDATE public.compliance_rules_comprehensive 
SET verification_required = vm.mapped_type
FROM verification_mapping vm
WHERE compliance_rules_comprehensive.verification_required = vm.original_type;

-- Show updated verification types
SELECT 
    verification_required,
    COUNT(*) as count,
    STRING_AGG(DISTINCT country_code, ', ') as countries
FROM public.compliance_rules_comprehensive
GROUP BY verification_required
ORDER BY verification_required;
