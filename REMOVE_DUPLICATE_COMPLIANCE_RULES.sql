-- =====================================================
-- REMOVE DUPLICATE COMPLIANCE RULES
-- =====================================================
-- This script identifies and removes duplicate compliance rules
-- that may have been added twice from the admin panel

-- =====================================================
-- STEP 1: CHECK FOR DUPLICATES IN COMPREHENSIVE RULES
-- =====================================================

-- Show duplicate compliance rules in comprehensive table
SELECT 
    country_code,
    country_name,
    company_type,
    compliance_name,
    frequency,
    verification_required,
    COUNT(*) as duplicate_count
FROM public.compliance_rules_comprehensive
GROUP BY 
    country_code,
    country_name,
    company_type,
    compliance_name,
    frequency,
    verification_required
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, country_code, company_type;

-- =====================================================
-- STEP 2: REMOVE DUPLICATES (KEEP MOST RECENT)
-- =====================================================

-- Remove duplicate compliance rules, keeping the most recent one
WITH duplicates AS (
    SELECT 
        id,
        ROW_NUMBER() OVER (
            PARTITION BY 
                country_code,
                country_name,
                company_type,
                compliance_name,
                frequency,
                verification_required
            ORDER BY created_at DESC, id DESC
        ) as rn
    FROM public.compliance_rules_comprehensive
)
DELETE FROM public.compliance_rules_comprehensive 
WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
);

-- =====================================================
-- STEP 3: CHECK FOR DUPLICATES IN OLD COMPLIANCE RULES
-- =====================================================

-- Show duplicate compliance rules in old table
SELECT 
    country_code,
    COUNT(*) as duplicate_count
FROM public.compliance_rules
GROUP BY country_code
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- =====================================================
-- STEP 4: REMOVE DUPLICATES FROM OLD TABLE (KEEP MOST RECENT)
-- =====================================================

-- Remove duplicate compliance rules from old table, keeping the most recent one
WITH duplicates AS (
    SELECT 
        id,
        ROW_NUMBER() OVER (
            PARTITION BY country_code
            ORDER BY created_at DESC, id DESC
        ) as rn
    FROM public.compliance_rules
)
DELETE FROM public.compliance_rules 
WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
);

-- =====================================================
-- STEP 5: VERIFY CLEANUP
-- =====================================================

-- Check remaining compliance rules in comprehensive table
SELECT 
    country_code,
    country_name,
    COUNT(*) as rule_count
FROM public.compliance_rules_comprehensive
GROUP BY country_code, country_name
ORDER BY country_code;

-- Check remaining compliance rules in old table
SELECT 
    country_code,
    COUNT(*) as rule_count
FROM public.compliance_rules
GROUP BY country_code
ORDER BY country_code;

-- =====================================================
-- STEP 6: ADD UNIQUE CONSTRAINT TO PREVENT FUTURE DUPLICATES
-- =====================================================

-- Add unique constraint to comprehensive table to prevent future duplicates
-- First check if constraint exists, then add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'compliance_rules_comp_unique'
    ) THEN
        ALTER TABLE public.compliance_rules_comprehensive 
        ADD CONSTRAINT compliance_rules_comp_unique 
        UNIQUE (country_code, company_type, compliance_name, frequency, verification_required);
    END IF;
END $$;

-- Add unique constraint to old table to prevent future duplicates
-- First check if constraint exists, then add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'compliance_rules_country_unique'
    ) THEN
        ALTER TABLE public.compliance_rules 
        ADD CONSTRAINT compliance_rules_country_unique 
        UNIQUE (country_code);
    END IF;
END $$;

-- =====================================================
-- STEP 7: SUMMARY
-- =====================================================

-- Show final summary
SELECT 
    'compliance_rules_comprehensive' as table_name,
    COUNT(*) as total_rules,
    COUNT(DISTINCT country_code) as unique_countries
FROM public.compliance_rules_comprehensive

UNION ALL

SELECT 
    'compliance_rules' as table_name,
    COUNT(*) as total_rules,
    COUNT(DISTINCT country_code) as unique_countries
FROM public.compliance_rules;
