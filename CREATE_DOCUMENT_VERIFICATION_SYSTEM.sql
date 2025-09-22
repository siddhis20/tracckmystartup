-- =====================================================
-- DOCUMENT VERIFICATION SYSTEM
-- =====================================================
-- This script creates a comprehensive document verification system
-- to track and validate whether uploaded documents are verified or not
-- =====================================================

-- Step 1: Create document verification status enum
-- =====================================================
CREATE TYPE document_verification_status AS ENUM (
    'pending',      -- Document uploaded but not yet verified
    'verified',     -- Document has been verified as authentic
    'rejected',     -- Document failed verification
    'expired',      -- Document verification has expired
    'under_review'  -- Document is currently under review
);

-- Step 2: Create document verification table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.document_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_id UUID NOT NULL, -- References the uploaded document
    document_type TEXT NOT NULL, -- Type of document (compliance, IP, financial, etc.)
    verification_status document_verification_status DEFAULT 'pending',
    verified_by TEXT, -- Email/ID of person who verified
    verified_at TIMESTAMP WITH TIME ZONE,
    verification_notes TEXT, -- Notes from verifier
    rejection_reason TEXT, -- Reason for rejection if applicable
    expiry_date TIMESTAMP WITH TIME ZONE, -- When verification expires
    verification_method TEXT, -- How it was verified (manual, automated, etc.)
    confidence_score DECIMAL(3,2), -- Confidence score 0.00-1.00
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create document verification rules table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.document_verification_rules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_type TEXT NOT NULL,
    verification_required BOOLEAN DEFAULT true,
    auto_verification BOOLEAN DEFAULT false,
    verification_expiry_days INTEGER DEFAULT 365, -- Days until verification expires
    required_verifier_role TEXT, -- Role required to verify (Admin, CA, CS, etc.)
    verification_criteria JSONB, -- Criteria for verification
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(document_type)
);

-- Step 4: Create document verification history table
-- =====================================================
CREATE TABLE IF NOT EXISTS public.document_verification_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    document_verification_id UUID NOT NULL REFERENCES public.document_verifications(id) ON DELETE CASCADE,
    previous_status document_verification_status,
    new_status document_verification_status NOT NULL,
    changed_by TEXT NOT NULL,
    change_reason TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Add verification columns to existing upload tables
-- =====================================================

-- Add verification columns to compliance_uploads
ALTER TABLE public.compliance_uploads 
ADD COLUMN IF NOT EXISTS verification_status document_verification_status DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS verified_by TEXT,
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS verification_notes TEXT,
ADD COLUMN IF NOT EXISTS verification_expiry TIMESTAMP WITH TIME ZONE;

-- Add verification columns to ip_trademark_documents
ALTER TABLE public.ip_trademark_documents 
ADD COLUMN IF NOT EXISTS verification_status document_verification_status DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS verified_by TEXT,
ADD COLUMN IF NOT EXISTS verified_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS verification_notes TEXT,
ADD COLUMN IF NOT EXISTS verification_expiry TIMESTAMP WITH TIME ZONE;

-- Step 6: Create indexes for performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_document_verifications_document_id ON public.document_verifications(document_id);
CREATE INDEX IF NOT EXISTS idx_document_verifications_status ON public.document_verifications(verification_status);
CREATE INDEX IF NOT EXISTS idx_document_verifications_type ON public.document_verifications(document_type);
CREATE INDEX IF NOT EXISTS idx_document_verifications_verified_by ON public.document_verifications(verified_by);
CREATE INDEX IF NOT EXISTS idx_document_verifications_expiry ON public.document_verifications(expiry_date);

CREATE INDEX IF NOT EXISTS idx_compliance_uploads_verification_status ON public.compliance_uploads(verification_status);
CREATE INDEX IF NOT EXISTS idx_ip_trademark_documents_verification_status ON public.ip_trademark_documents(verification_status);

-- Step 7: Create triggers for automatic updates
-- =====================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_document_verification_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_document_verification_updated_at
    BEFORE UPDATE ON public.document_verifications
    FOR EACH ROW
    EXECUTE FUNCTION update_document_verification_updated_at();

-- Trigger to create history record when status changes
CREATE OR REPLACE FUNCTION create_document_verification_history()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.verification_status IS DISTINCT FROM NEW.verification_status THEN
        INSERT INTO public.document_verification_history (
            document_verification_id,
            previous_status,
            new_status,
            changed_by,
            change_reason
        ) VALUES (
            NEW.id,
            OLD.verification_status,
            NEW.verification_status,
            COALESCE(NEW.verified_by, 'system'),
            NEW.verification_notes
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_document_verification_history
    AFTER UPDATE ON public.document_verifications
    FOR EACH ROW
    EXECUTE FUNCTION create_document_verification_history();

-- Step 8: Insert default verification rules
-- =====================================================
INSERT INTO public.document_verification_rules (document_type, verification_required, auto_verification, verification_expiry_days, required_verifier_role, verification_criteria) VALUES
('compliance_document', true, false, 365, 'CA', '{"requires_manual_review": true, "file_types": ["pdf", "doc", "docx"], "max_size_mb": 50}'),
('ip_trademark_document', true, false, 730, 'Admin', '{"requires_manual_review": true, "file_types": ["pdf", "jpg", "png"], "max_size_mb": 25}'),
('financial_document', true, false, 180, 'CS', '{"requires_manual_review": true, "file_types": ["pdf", "xlsx", "csv"], "max_size_mb": 10}'),
('government_id', true, false, 365, 'Admin', '{"requires_manual_review": true, "file_types": ["pdf", "jpg", "png"], "max_size_mb": 5}'),
('license_document', true, false, 365, 'Admin', '{"requires_manual_review": true, "file_types": ["pdf", "jpg", "png"], "max_size_mb": 10}')
ON CONFLICT (document_type) DO NOTHING;

-- Step 9: Enable Row Level Security
-- =====================================================
ALTER TABLE public.document_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_verification_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_verification_history ENABLE ROW LEVEL SECURITY;

-- Step 10: Create RLS policies
-- =====================================================

-- Policies for document_verifications
CREATE POLICY "Users can view their own document verifications" ON public.document_verifications
    FOR SELECT USING (
        document_id IN (
            SELECT id FROM public.compliance_uploads 
            WHERE startup_id IN (
                SELECT id FROM public.startups 
                WHERE user_id = auth.uid()
            )
        ) OR
        document_id IN (
            SELECT id FROM public.ip_trademark_documents 
            WHERE ip_record_id IN (
                SELECT id FROM public.ip_trademark_records 
                WHERE startup_id IN (
                    SELECT id FROM public.startups 
                    WHERE user_id = auth.uid()
                )
            )
        )
    );

CREATE POLICY "Admins can manage all document verifications" ON public.document_verifications
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'Admin'
        )
    );

CREATE POLICY "CA/CS can verify compliance documents" ON public.document_verifications
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('CA', 'CS')
        )
    );

-- Policies for document_verification_rules
CREATE POLICY "All authenticated users can view verification rules" ON public.document_verification_rules
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins can manage verification rules" ON public.document_verification_rules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'Admin'
        )
    );

-- Policies for document_verification_history
CREATE POLICY "Users can view their own verification history" ON public.document_verification_history
    FOR SELECT USING (
        document_verification_id IN (
            SELECT id FROM public.document_verifications 
            WHERE document_id IN (
                SELECT id FROM public.compliance_uploads 
                WHERE startup_id IN (
                    SELECT id FROM public.startups 
                    WHERE user_id = auth.uid()
                )
            )
        )
    );

-- Step 11: Create helper functions
-- =====================================================

-- Function to get document verification status
CREATE OR REPLACE FUNCTION get_document_verification_status(document_id_param UUID)
RETURNS document_verification_status
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    status document_verification_status;
BEGIN
    SELECT verification_status INTO status
    FROM public.document_verifications
    WHERE document_id = document_id_param
    ORDER BY created_at DESC
    LIMIT 1;
    
    RETURN COALESCE(status, 'pending');
END;
$$;

-- Function to verify a document
CREATE OR REPLACE FUNCTION verify_document(
    document_id_param UUID,
    verifier_email TEXT,
    verification_status_param document_verification_status,
    verification_notes_param TEXT DEFAULT NULL,
    confidence_score_param DECIMAL(3,2) DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    verification_id UUID;
    expiry_days INTEGER;
BEGIN
    -- Get verification expiry days for this document type
    SELECT verification_expiry_days INTO expiry_days
    FROM public.document_verification_rules
    WHERE document_type = (
        SELECT CASE 
            WHEN document_id_param IN (SELECT id FROM public.compliance_uploads) THEN 'compliance_document'
            WHEN document_id_param IN (SELECT id FROM public.ip_trademark_documents) THEN 'ip_trademark_document'
            ELSE 'unknown'
        END
    );
    
    -- Create or update verification record
    INSERT INTO public.document_verifications (
        document_id,
        document_type,
        verification_status,
        verified_by,
        verified_at,
        verification_notes,
        expiry_date,
        confidence_score
    ) VALUES (
        document_id_param,
        CASE 
            WHEN document_id_param IN (SELECT id FROM public.compliance_uploads) THEN 'compliance_document'
            WHEN document_id_param IN (SELECT id FROM public.ip_trademark_documents) THEN 'ip_trademark_document'
            ELSE 'unknown'
        END,
        verification_status_param,
        verifier_email,
        NOW(),
        verification_notes_param,
        NOW() + INTERVAL '1 day' * COALESCE(expiry_days, 365),
        confidence_score_param
    )
    ON CONFLICT (document_id) DO UPDATE SET
        verification_status = verification_status_param,
        verified_by = verifier_email,
        verified_at = NOW(),
        verification_notes = verification_notes_param,
        expiry_date = NOW() + INTERVAL '1 day' * COALESCE(expiry_days, 365),
        confidence_score = confidence_score_param,
        updated_at = NOW();
    
    -- Update the original document table
    UPDATE public.compliance_uploads 
    SET 
        verification_status = verification_status_param,
        verified_by = verifier_email,
        verified_at = NOW(),
        verification_notes = verification_notes_param,
        verification_expiry = NOW() + INTERVAL '1 day' * COALESCE(expiry_days, 365)
    WHERE id = document_id_param;
    
    UPDATE public.ip_trademark_documents 
    SET 
        verification_status = verification_status_param,
        verified_by = verifier_email,
        verified_at = NOW(),
        verification_notes = verification_notes_param,
        verification_expiry = NOW() + INTERVAL '1 day' * COALESCE(expiry_days, 365)
    WHERE id = document_id_param;
    
    RETURN TRUE;
END;
$$;

-- Step 12: Verify the setup
-- =====================================================
SELECT 
    'document_verification_setup' as check_type,
    COUNT(*) as total_verification_rules,
    'Document verification system created successfully' as status
FROM public.document_verification_rules;

-- Success message
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'DOCUMENT VERIFICATION SYSTEM CREATED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ Document verification tables created';
    RAISE NOTICE '✅ Verification status tracking enabled';
    RAISE NOTICE '✅ Automatic expiry and history tracking';
    RAISE NOTICE '✅ RLS policies configured';
    RAISE NOTICE '✅ Helper functions created';
    RAISE NOTICE '✅ Default verification rules inserted';
    RAISE NOTICE '========================================';
END $$;

