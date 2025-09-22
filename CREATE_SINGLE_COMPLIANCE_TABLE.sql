-- =====================================================
-- SINGLE COMPLIANCE RULES TABLE - COMPREHENSIVE STRUCTURE
-- =====================================================
-- This creates one table that stores all compliance information
-- One row = One compliance rule with all related information

-- =====================================================
-- STEP 1: CREATE THE SINGLE COMPREHENSIVE TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.compliance_rules_comprehensive (
    id SERIAL PRIMARY KEY,
    country_code VARCHAR(10) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    ca_type VARCHAR(50),
    cs_type VARCHAR(50),
    company_type VARCHAR(100) NOT NULL,
    compliance_name VARCHAR(200) NOT NULL,
    compliance_description TEXT,
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('first-year', 'monthly', 'quarterly', 'annual')),
    verification_required VARCHAR(20) NOT NULL CHECK (verification_required IN ('CA', 'CS', 'both')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 2: CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_compliance_rules_comp_country ON public.compliance_rules_comprehensive(country_code);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_comp_company_type ON public.compliance_rules_comprehensive(company_type);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_comp_frequency ON public.compliance_rules_comprehensive(frequency);
CREATE INDEX IF NOT EXISTS idx_compliance_rules_comp_verification ON public.compliance_rules_comprehensive(verification_required);

-- =====================================================
-- STEP 3: CREATE TRIGGER FOR UPDATED_AT
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_compliance_rules_comp_updated_at ON public.compliance_rules_comprehensive;
CREATE TRIGGER update_compliance_rules_comp_updated_at 
    BEFORE UPDATE ON public.compliance_rules_comprehensive 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =====================================================
-- STEP 4: TABLE IS READY FOR ADMIN TO ADD DATA
-- =====================================================
-- The table is now ready for the admin to add compliance rules
-- through the web interface. No sample data is inserted.

-- =====================================================
-- STEP 5: GRANT PERMISSIONS
-- =====================================================
GRANT ALL PRIVILEGES ON public.compliance_rules_comprehensive TO authenticated;
GRANT ALL PRIVILEGES ON SEQUENCE public.compliance_rules_comprehensive_id_seq TO authenticated;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Uncomment these to verify the setup:

-- SELECT 'Table Created Successfully' as info, 'compliance_rules_comprehensive' as table_name;
-- SELECT 'Total Compliance Rules' as info, COUNT(*) as count FROM public.compliance_rules_comprehensive;
-- SELECT 'Rules by Country' as info, country_name, COUNT(*) as count FROM public.compliance_rules_comprehensive GROUP BY country_name ORDER BY count DESC;
-- SELECT 'Rules by Company Type' as info, company_type, COUNT(*) as count FROM public.compliance_rules_comprehensive GROUP BY company_type ORDER BY count DESC;
-- SELECT 'Rules by Verification Required' as info, verification_required, COUNT(*) as count FROM public.compliance_rules_comprehensive GROUP BY verification_required;
