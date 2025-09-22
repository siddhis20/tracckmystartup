-- =====================================================
-- FIX AUSTRIA COMPLIANCE VERIFICATION REQUIREMENTS
-- =====================================================
-- This script fixes the verification_required field for Austria compliance rules
-- to properly map "Tax Advisor/Auditor" to CA and "Management/Lawyer" to CS

-- Update Austria compliance rules with correct verification requirements
UPDATE public.compliance_rules_comprehensive 
SET verification_required = 'CA'
WHERE country_code = 'AT' 
  AND verification_required = 'Tax Advisor/Auditor';

UPDATE public.compliance_rules_comprehensive 
SET verification_required = 'CS'
WHERE country_code = 'AT' 
  AND verification_required = 'Management/Lawyer';

-- Verify the changes
SELECT 
    country_code,
    country_name,
    company_type,
    compliance_name,
    verification_required,
    frequency
FROM public.compliance_rules_comprehensive
WHERE country_code = 'AT'
ORDER BY company_type, compliance_name;

-- Show summary of changes
SELECT 
    verification_required,
    COUNT(*) as count
FROM public.compliance_rules_comprehensive
WHERE country_code = 'AT'
GROUP BY verification_required
ORDER BY verification_required;
