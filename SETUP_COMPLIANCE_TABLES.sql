-- =====================================================
-- COMPLIANCE MANAGEMENT SYSTEM - PROPER DATABASE SETUP
-- =====================================================
-- This script creates the proper three-dimensional structure:
-- Country → Company Type → Compliance Rules

-- =====================================================
-- STEP 1: CREATE AUDITOR TYPES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.auditor_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 2: CREATE GOVERNANCE TYPES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.governance_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 3: CREATE COMPANY TYPES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.company_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    country_code VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, country_code)
);

-- =====================================================
-- STEP 4: CREATE COMPLIANCE RULES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.compliance_rules_new (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('first-year', 'monthly', 'quarterly', 'annual')),
    validation_required VARCHAR(20) NOT NULL CHECK (validation_required IN ('auditor', 'governance', 'both')),
    country_code VARCHAR(10) NOT NULL,
    company_type_id INTEGER NOT NULL REFERENCES public.company_types(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 5: CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_company_types_country ON public.company_types(country_code);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_country ON public.compliance_rules_new(country_code);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_company_type ON public.compliance_rules_new(company_type_id);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_frequency ON public.compliance_rules_new(frequency);

-- =====================================================
-- STEP 6: CREATE TRIGGER FUNCTION FOR UPDATED_AT
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- =====================================================
-- STEP 7: CREATE TRIGGERS
-- =====================================================
DROP TRIGGER IF EXISTS update_auditor_types_updated_at ON public.auditor_types;
CREATE TRIGGER update_auditor_types_updated_at 
    BEFORE UPDATE ON public.auditor_types 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_governance_types_updated_at ON public.governance_types;
CREATE TRIGGER update_governance_types_updated_at 
    BEFORE UPDATE ON public.governance_types 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_company_types_updated_at ON public.company_types;
CREATE TRIGGER update_company_types_updated_at 
    BEFORE UPDATE ON public.company_types 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_compliance_rules_new_updated_at ON public.compliance_rules_new;
CREATE TRIGGER update_compliance_rules_new_updated_at 
    BEFORE UPDATE ON public.compliance_rules_new 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- STEP 8: INSERT DEFAULT DATA
-- =====================================================

-- Insert default auditor types
INSERT INTO public.auditor_types (name, description) VALUES
('CA', 'Chartered Accountant'),
('CFA', 'Chartered Financial Analyst'),
('Auditor', 'Certified Auditor'),
('CPA', 'Certified Public Accountant'),
('CMA', 'Certified Management Accountant')
ON CONFLICT (name) DO NOTHING;

-- Insert default governance types
INSERT INTO public.governance_types (name, description) VALUES
('CS', 'Company Secretary'),
('Director', 'Board Director'),
('Legal', 'Legal Counsel'),
('Compliance Officer', 'Compliance Officer'),
('Company Secretary', 'Company Secretary'),
('Independent Director', 'Independent Director')
ON CONFLICT (name) DO NOTHING;

-- Insert default company types for major countries
INSERT INTO public.company_types (name, description, country_code) VALUES
-- India
('Private Limited Company', 'Private Limited Company under Companies Act 2013', 'IN'),
('Public Limited Company', 'Public Limited Company under Companies Act 2013', 'IN'),
('Limited Liability Partnership', 'Limited Liability Partnership under LLP Act 2008', 'IN'),
('One Person Company', 'One Person Company under Companies Act 2013', 'IN'),
('Partnership Firm', 'Partnership Firm under Partnership Act 1932', 'IN'),

-- United States
('C-Corporation', 'C-Corporation under US Corporate Law', 'US'),
('S-Corporation', 'S-Corporation under US Corporate Law', 'US'),
('Limited Liability Company', 'Limited Liability Company under US State Law', 'US'),
('Partnership', 'General Partnership under US State Law', 'US'),
('Limited Partnership', 'Limited Partnership under US State Law', 'US'),

-- United Kingdom
('Private Limited Company', 'Private Limited Company under UK Companies Act', 'UK'),
('Public Limited Company', 'Public Limited Company under UK Companies Act', 'UK'),
('Limited Liability Partnership', 'Limited Liability Partnership under UK LLP Act', 'UK'),
('Partnership', 'Partnership under UK Partnership Act', 'UK'),

-- Canada
('Corporation', 'Corporation under Canada Business Corporations Act', 'CA'),
('Limited Liability Company', 'Limited Liability Company under Provincial Law', 'CA'),
('Partnership', 'Partnership under Provincial Law', 'CA'),

-- Australia
('Proprietary Limited Company', 'Proprietary Limited Company under Corporations Act', 'AU'),
('Public Company', 'Public Company under Corporations Act', 'AU'),
('Limited Liability Partnership', 'Limited Liability Partnership under State Law', 'AU'),
('Partnership', 'Partnership under State Law', 'AU')
ON CONFLICT (name, country_code) DO NOTHING;

-- =====================================================
-- STEP 9: INSERT SAMPLE COMPLIANCE RULES
-- =====================================================

-- Get company type IDs for sample rules
DO $$
DECLARE
    pvt_limited_in_id INTEGER;
    pub_limited_in_id INTEGER;
    c_corp_us_id INTEGER;
    llc_us_id INTEGER;
BEGIN
    -- Get company type IDs
    SELECT id INTO pvt_limited_in_id FROM public.company_types WHERE name = 'Private Limited Company' AND country_code = 'IN';
    SELECT id INTO pub_limited_in_id FROM public.company_types WHERE name = 'Public Limited Company' AND country_code = 'IN';
    SELECT id INTO c_corp_us_id FROM public.company_types WHERE name = 'C-Corporation' AND country_code = 'US';
    SELECT id INTO llc_us_id FROM public.company_types WHERE name = 'Limited Liability Company' AND country_code = 'US';

    -- Insert sample compliance rules for India Private Limited
    IF pvt_limited_in_id IS NOT NULL THEN
        INSERT INTO public.compliance_rules_new (name, description, frequency, validation_required, country_code, company_type_id) VALUES
        ('Annual Return Filing', 'File annual return with ROC within 60 days of AGM', 'annual', 'both', 'IN', pvt_limited_in_id),
        ('Board Meetings', 'Hold minimum 4 board meetings per year', 'quarterly', 'governance', 'IN', pvt_limited_in_id),
        ('Audit Report', 'Get annual audit report from CA', 'annual', 'auditor', 'IN', pvt_limited_in_id),
        ('GST Returns', 'File monthly GST returns', 'monthly', 'auditor', 'IN', pvt_limited_in_id),
        ('First Year Compliance', 'Complete all first-year statutory requirements', 'first-year', 'both', 'IN', pvt_limited_in_id)
        ON CONFLICT DO NOTHING;
    END IF;

    -- Insert sample compliance rules for India Public Limited
    IF pub_limited_in_id IS NOT NULL THEN
        INSERT INTO public.compliance_rules_new (name, description, frequency, validation_required, country_code, company_type_id) VALUES
        ('Annual Return Filing', 'File annual return with ROC within 60 days of AGM', 'annual', 'both', 'IN', pub_limited_in_id),
        ('Board Meetings', 'Hold minimum 4 board meetings per year', 'quarterly', 'governance', 'IN', pub_limited_in_id),
        ('Audit Report', 'Get annual audit report from CA', 'annual', 'auditor', 'IN', pub_limited_in_id),
        ('SEBI Compliance', 'Comply with SEBI regulations for public companies', 'quarterly', 'both', 'IN', pub_limited_in_id),
        ('First Year Compliance', 'Complete all first-year statutory requirements', 'first-year', 'both', 'IN', pub_limited_in_id)
        ON CONFLICT DO NOTHING;
    END IF;

    -- Insert sample compliance rules for US C-Corporation
    IF c_corp_us_id IS NOT NULL THEN
        INSERT INTO public.compliance_rules_new (name, description, frequency, validation_required, country_code, company_type_id) VALUES
        ('Annual Report', 'File annual report with state', 'annual', 'both', 'US', c_corp_us_id),
        ('Board Meetings', 'Hold regular board meetings', 'quarterly', 'governance', 'US', c_corp_us_id),
        ('Tax Returns', 'File corporate tax returns', 'annual', 'auditor', 'US', c_corp_us_id),
        ('First Year Compliance', 'Complete all first-year statutory requirements', 'first-year', 'both', 'US', c_corp_us_id)
        ON CONFLICT DO NOTHING;
    END IF;

    -- Insert sample compliance rules for US LLC
    IF llc_us_id IS NOT NULL THEN
        INSERT INTO public.compliance_rules_new (name, description, frequency, validation_required, country_code, company_type_id) VALUES
        ('Annual Report', 'File annual report with state', 'annual', 'both', 'US', llc_us_id),
        ('Tax Returns', 'File LLC tax returns', 'annual', 'auditor', 'US', llc_us_id),
        ('Operating Agreement', 'Maintain operating agreement', 'annual', 'governance', 'US', llc_us_id),
        ('First Year Compliance', 'Complete all first-year statutory requirements', 'first-year', 'both', 'US', llc_us_id)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- =====================================================
-- STEP 10: GRANT PERMISSIONS
-- =====================================================
-- Grant necessary permissions (adjust as needed for your setup)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Uncomment these to verify the setup:

-- SELECT 'Auditor Types' as table_name, COUNT(*) as count FROM public.auditor_types;
-- SELECT 'Governance Types' as table_name, COUNT(*) as count FROM public.governance_types;
-- SELECT 'Company Types' as table_name, COUNT(*) as count FROM public.company_types;
-- SELECT 'Compliance Rules' as table_name, COUNT(*) as count FROM public.compliance_rules_new;

-- SELECT 
--     cr.name as rule_name,
--     ct.name as company_type,
--     ct.country_code,
--     cr.frequency,
--     cr.validation_required
-- FROM public.compliance_rules_new cr
-- JOIN public.company_types ct ON cr.company_type_id = ct.id
-- ORDER BY ct.country_code, ct.name, cr.name;
