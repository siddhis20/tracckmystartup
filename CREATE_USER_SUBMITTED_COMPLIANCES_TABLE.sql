-- =====================================================
-- USER SUBMITTED COMPLIANCES TABLE
-- =====================================================
-- This table stores compliance rules submitted by users (Startup, CA, CS)
-- for parent companies, subsidiaries, or international operations
-- Admin can review and approve these to add to main compliance rules

-- =====================================================
-- STEP 1: CREATE THE USER SUBMITTED COMPLIANCES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_submitted_compliances (
    id SERIAL PRIMARY KEY,
    submitted_by_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    submitted_by_name VARCHAR(100) NOT NULL,
    submitted_by_role VARCHAR(50) NOT NULL,
    submitted_by_email VARCHAR(255) NOT NULL,
    
    -- Company information
    company_name VARCHAR(200) NOT NULL,
    company_type VARCHAR(100) NOT NULL,
    operation_type VARCHAR(50) NOT NULL CHECK (operation_type IN ('parent', 'subsidiary', 'international')),
    
    -- Compliance details
    country_code VARCHAR(10) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    ca_type VARCHAR(50),
    cs_type VARCHAR(50),
    compliance_name VARCHAR(200) NOT NULL,
    compliance_description TEXT,
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('first-year', 'monthly', 'quarterly', 'annual')),
    verification_required VARCHAR(20) NOT NULL CHECK (verification_required IN ('CA', 'CS', 'both')),
    
    -- Additional context
    justification TEXT, -- Why this compliance is needed
    supporting_documents TEXT[], -- Array of document URLs/paths
    regulatory_reference VARCHAR(500), -- Reference to specific regulation/law
    
    -- Status and approval
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'under_review')),
    reviewed_by_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- STEP 2: CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_user_submitted_compliances_submitted_by ON public.user_submitted_compliances(submitted_by_user_id);
CREATE INDEX IF NOT EXISTS idx_user_submitted_compliances_status ON public.user_submitted_compliances(status);
CREATE INDEX IF NOT EXISTS idx_user_submitted_compliances_country ON public.user_submitted_compliances(country_code);
CREATE INDEX IF NOT EXISTS idx_user_submitted_compliances_company_type ON public.user_submitted_compliances(company_type);
CREATE INDEX IF NOT EXISTS idx_user_submitted_compliances_operation_type ON public.user_submitted_compliances(operation_type);
CREATE INDEX IF NOT EXISTS idx_user_submitted_compliances_created_at ON public.user_submitted_compliances(created_at);

-- =====================================================
-- STEP 3: CREATE TRIGGER FOR UPDATED_AT
-- =====================================================
CREATE OR REPLACE FUNCTION public.update_user_submitted_compliances_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_user_submitted_compliances_updated_at ON public.user_submitted_compliances;
CREATE TRIGGER update_user_submitted_compliances_updated_at 
    BEFORE UPDATE ON public.user_submitted_compliances 
    FOR EACH ROW EXECUTE FUNCTION public.update_user_submitted_compliances_updated_at();

-- =====================================================
-- STEP 4: GRANT PERMISSIONS
-- =====================================================
GRANT ALL PRIVILEGES ON public.user_submitted_compliances TO authenticated;
GRANT ALL PRIVILEGES ON SEQUENCE public.user_submitted_compliances_id_seq TO authenticated;

-- =====================================================
-- STEP 5: CREATE ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.user_submitted_compliances ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own submissions
CREATE POLICY "Users can view own submissions" ON public.user_submitted_compliances
    FOR SELECT USING (auth.uid() = submitted_by_user_id);

-- Policy: Users can insert their own submissions
CREATE POLICY "Users can submit compliances" ON public.user_submitted_compliances
    FOR INSERT WITH CHECK (
        auth.uid() = submitted_by_user_id AND
        (SELECT role FROM public.users WHERE id = auth.uid()) IN ('Startup', 'CA', 'CS')
    );

-- Policy: Users can update their own pending submissions
CREATE POLICY "Users can update own pending submissions" ON public.user_submitted_compliances
    FOR UPDATE USING (
        auth.uid() = submitted_by_user_id AND 
        status = 'pending'
    );

-- Policy: Admins can view all submissions
CREATE POLICY "Admins can view all submissions" ON public.user_submitted_compliances
    FOR SELECT USING (
        (SELECT role FROM public.users WHERE id = auth.uid()) = 'Admin'
    );

-- Policy: Admins can update all submissions (for approval/rejection)
CREATE POLICY "Admins can update all submissions" ON public.user_submitted_compliances
    FOR UPDATE USING (
        (SELECT role FROM public.users WHERE id = auth.uid()) = 'Admin'
    );

-- Policy: Admins can delete submissions
CREATE POLICY "Admins can delete submissions" ON public.user_submitted_compliances
    FOR DELETE USING (
        (SELECT role FROM public.users WHERE id = auth.uid()) = 'Admin'
    );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================
-- Uncomment these to verify the setup:

-- SELECT 'User Submitted Compliances Table Created Successfully' as info;
-- SELECT 'Total User Submissions' as info, COUNT(*) as count FROM public.user_submitted_compliances;
-- SELECT 'Submissions by Status' as info, status, COUNT(*) as count FROM public.user_submitted_compliances GROUP BY status;
-- SELECT 'Submissions by Operation Type' as info, operation_type, COUNT(*) as count FROM public.user_submitted_compliances GROUP BY operation_type;
