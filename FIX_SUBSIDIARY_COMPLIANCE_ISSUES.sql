-- =====================================================
-- FIX SUBSIDIARY COMPLIANCE ISSUES
-- =====================================================
-- This script fixes the missing columns and functions needed
-- for subsidiary compliance task generation to work properly

-- =====================================================
-- STEP 1: ADD MISSING COLUMNS TO SUBSIDIARIES TABLE
-- =====================================================

-- Add company_type column (required for compliance task generation)
ALTER TABLE public.subsidiaries 
ADD COLUMN IF NOT EXISTS company_type TEXT NOT NULL DEFAULT 'C-Corporation';

-- Add user_id column for proper ownership tracking
ALTER TABLE public.subsidiaries 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add profile_updated_at column for tracking changes
ALTER TABLE public.subsidiaries 
ADD COLUMN IF NOT EXISTS profile_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- =====================================================
-- STEP 2: UPDATE SUBSIDIARY MANAGEMENT FUNCTIONS
-- =====================================================

-- Update add_subsidiary function to include company_type
CREATE OR REPLACE FUNCTION add_subsidiary(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE,
    user_id_param UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    subsidiary_id INTEGER;
    actual_user_id UUID;
BEGIN
    -- Get user_id if not provided
    IF user_id_param IS NULL THEN
        SELECT user_id INTO actual_user_id FROM public.startups WHERE id = startup_id_param;
    ELSE
        actual_user_id := user_id_param;
    END IF;
    
    INSERT INTO public.subsidiaries (
        startup_id, country, company_type, registration_date, user_id
    ) VALUES (
        startup_id_param, country_param, company_type_param, registration_date_param, actual_user_id
    ) RETURNING id INTO subsidiary_id;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, new_values
    ) VALUES (
        startup_id_param,
        actual_user_id,
        'created',
        'subsidiaries',
        subsidiary_id::TEXT,
        jsonb_build_object(
            'country', country_param,
            'company_type', company_type_param,
            'registration_date', registration_date_param
        )
    );
    
    -- Create notification
    INSERT INTO public.profile_notifications (
        startup_id, user_id, notification_type, title, message
    ) VALUES (
        startup_id_param,
        actual_user_id,
        'subsidiary_added',
        'Subsidiary Added',
        'New subsidiary added: ' || country_param || ' - ' || company_type_param
    );
    
    RETURN subsidiary_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update update_subsidiary function to include company_type
CREATE OR REPLACE FUNCTION update_subsidiary(
    subsidiary_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE
)
RETURNS BOOLEAN AS $$
DECLARE
    startup_id_val INTEGER;
    user_id_val UUID;
    old_values JSONB;
    new_values JSONB;
BEGIN
    -- Get startup_id, user_id and old values
    SELECT startup_id, user_id, jsonb_build_object(
        'country', country,
        'company_type', company_type,
        'registration_date', registration_date
    ) INTO startup_id_val, user_id_val, old_values
    FROM public.subsidiaries
    WHERE id = subsidiary_id_param;
    
    -- Update subsidiary
    UPDATE public.subsidiaries 
    SET 
        country = country_param,
        company_type = company_type_param,
        registration_date = registration_date_param,
        profile_updated_at = NOW()
    WHERE id = subsidiary_id_param;
    
    -- Get new values
    SELECT jsonb_build_object(
        'country', country,
        'company_type', company_type,
        'registration_date', registration_date
    ) INTO new_values
    FROM public.subsidiaries
    WHERE id = subsidiary_id_param;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, old_values, new_values
    ) VALUES (
        startup_id_val,
        user_id_val,
        'updated',
        'subsidiaries',
        subsidiary_id_param::TEXT,
        old_values,
        new_values
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 3: UPDATE INTERNATIONAL OPERATIONS TABLE
-- =====================================================

-- Add company_type column to international_ops table as well
ALTER TABLE public.international_ops 
ADD COLUMN IF NOT EXISTS company_type TEXT NOT NULL DEFAULT 'C-Corporation';

-- Add user_id column for proper ownership tracking
ALTER TABLE public.international_ops 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add profile_updated_at column for tracking changes
ALTER TABLE public.international_ops 
ADD COLUMN IF NOT EXISTS profile_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- =====================================================
-- STEP 4: UPDATE INTERNATIONAL OPERATIONS FUNCTIONS
-- =====================================================

-- Update add_international_op function to include company_type
CREATE OR REPLACE FUNCTION add_international_op(
    startup_id_param INTEGER,
    country_param TEXT,
    start_date_param DATE,
    company_type_param TEXT DEFAULT 'C-Corporation',
    user_id_param UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    op_id INTEGER;
    actual_user_id UUID;
BEGIN
    -- Get user_id if not provided
    IF user_id_param IS NULL THEN
        SELECT user_id INTO actual_user_id FROM public.startups WHERE id = startup_id_param;
    ELSE
        actual_user_id := user_id_param;
    END IF;
    
    INSERT INTO public.international_ops (
        startup_id, country, start_date, company_type, user_id
    ) VALUES (
        startup_id_param, country_param, start_date_param, company_type_param, actual_user_id
    ) RETURNING id INTO op_id;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, new_values
    ) VALUES (
        startup_id_param,
        actual_user_id,
        'created',
        'international_ops',
        op_id::TEXT,
        jsonb_build_object(
            'country', country_param,
            'start_date', start_date_param,
            'company_type', company_type_param
        )
    );
    
    -- Create notification
    INSERT INTO public.profile_notifications (
        startup_id, user_id, notification_type, title, message
    ) VALUES (
        startup_id_param,
        actual_user_id,
        'international_op_added',
        'International Operation Added',
        'New international operation added: ' || country_param || ' - ' || company_type_param
    );
    
    RETURN op_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update update_international_op function to include company_type
CREATE OR REPLACE FUNCTION update_international_op(
    op_id_param INTEGER,
    country_param TEXT,
    start_date_param DATE,
    company_type_param TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    startup_id_val INTEGER;
    user_id_val UUID;
    old_values JSONB;
    new_values JSONB;
BEGIN
    -- Get startup_id, user_id and old values
    SELECT startup_id, user_id, jsonb_build_object(
        'country', country,
        'start_date', start_date,
        'company_type', company_type
    ) INTO startup_id_val, user_id_val, old_values
    FROM public.international_ops
    WHERE id = op_id_param;
    
    -- Update international operation
    UPDATE public.international_ops 
    SET 
        country = country_param,
        start_date = start_date_param,
        company_type = company_type_param,
        profile_updated_at = NOW()
    WHERE id = op_id_param;
    
    -- Get new values
    SELECT jsonb_build_object(
        'country', country,
        'start_date', start_date,
        'company_type', company_type
    ) INTO new_values
    FROM public.international_ops
    WHERE id = op_id_param;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, old_values, new_values
    ) VALUES (
        startup_id_val,
        user_id_val,
        'updated',
        'international_ops',
        op_id_param::TEXT,
        old_values,
        new_values
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 5: UPDATE PROFILE FUNCTIONS
-- =====================================================

-- Update get_startup_profile function to include company_type for subsidiaries and international ops
CREATE OR REPLACE FUNCTION get_startup_profile(startup_id_param INTEGER)
RETURNS JSONB AS $$
DECLARE
    profile_data JSONB;
BEGIN
    SELECT jsonb_build_object(
        'startup', jsonb_build_object(
            'id', s.id,
            'name', s.name,
            'country_of_registration', s.country_of_registration,
            'company_type', s.company_type,
            'registration_date', s.registration_date,
            'ca_service_code', s.ca_service_code,
            'cs_service_code', s.cs_service_code,
            'profile_updated_at', s.profile_updated_at
        ),
        'subsidiaries', COALESCE(
            (SELECT jsonb_agg(jsonb_build_object(
                'id', sub.id,
                'country', sub.country,
                'company_type', sub.company_type,
                'registration_date', sub.registration_date,
                'profile_updated_at', sub.profile_updated_at
            )) FROM public.subsidiaries sub WHERE sub.startup_id = s.id),
            '[]'::jsonb
        ),
        'international_ops', COALESCE(
            (SELECT jsonb_agg(jsonb_build_object(
                'id', io.id,
                'country', io.country,
                'start_date', io.start_date,
                'company_type', io.company_type,
                'profile_updated_at', io.profile_updated_at
            )) FROM public.international_ops io WHERE io.startup_id = s.id),
            '[]'::jsonb
        )
    ) INTO profile_data
    FROM public.startups s
    WHERE s.id = startup_id_param;
    
    RETURN profile_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 6: CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for subsidiaries table
CREATE INDEX IF NOT EXISTS idx_subsidiaries_company_type ON public.subsidiaries(company_type);
CREATE INDEX IF NOT EXISTS idx_subsidiaries_user_id ON public.subsidiaries(user_id);
CREATE INDEX IF NOT EXISTS idx_subsidiaries_profile_updated_at ON public.subsidiaries(profile_updated_at);

-- Indexes for international_ops table
CREATE INDEX IF NOT EXISTS idx_international_ops_company_type ON public.international_ops(company_type);
CREATE INDEX IF NOT EXISTS idx_international_ops_user_id ON public.international_ops(user_id);
CREATE INDEX IF NOT EXISTS idx_international_ops_profile_updated_at ON public.international_ops(profile_updated_at);

-- =====================================================
-- STEP 7: UPDATE ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Update subsidiaries policies to include user_id
DROP POLICY IF EXISTS "Users can manage their own subsidiaries" ON public.subsidiaries;
CREATE POLICY "Users can manage their own subsidiaries" ON public.subsidiaries
    FOR ALL USING (
        user_id = auth.uid() OR 
        startup_id IN (SELECT id FROM public.startups WHERE user_id = auth.uid())
    );

-- Update international_ops policies to include user_id
DROP POLICY IF EXISTS "Users can manage their own international ops" ON public.international_ops;
CREATE POLICY "Users can manage their own international ops" ON public.international_ops
    FOR ALL USING (
        user_id = auth.uid() OR 
        startup_id IN (SELECT id FROM public.startups WHERE user_id = auth.uid())
    );

-- =====================================================
-- STEP 8: CREATE TRIGGERS FOR REAL-TIME UPDATES
-- =====================================================

-- Create trigger for subsidiaries profile updates
CREATE TRIGGER trigger_subsidiaries_profile_updated_at
    BEFORE UPDATE ON public.subsidiaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create trigger for international_ops profile updates
CREATE TRIGGER trigger_international_ops_profile_updated_at
    BEFORE UPDATE ON public.international_ops
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- STEP 9: VERIFICATION QUERIES
-- =====================================================

-- Verify subsidiaries table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'subsidiaries' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verify international_ops table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'international_ops' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test compliance task generation for subsidiaries
-- SELECT * FROM generate_compliance_tasks_for_startup(1) WHERE entity_identifier LIKE 'sub-%';

-- =====================================================
-- STEP 10: COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON COLUMN public.subsidiaries.company_type IS 'Company type for compliance rule matching (e.g., C-Corporation, LLC, Private Limited)';
COMMENT ON COLUMN public.subsidiaries.user_id IS 'User who owns this subsidiary for proper access control';
COMMENT ON COLUMN public.subsidiaries.profile_updated_at IS 'Timestamp when subsidiary profile was last updated';

COMMENT ON COLUMN public.international_ops.company_type IS 'Company type for compliance rule matching (e.g., C-Corporation, LLC, Private Limited)';
COMMENT ON COLUMN public.international_ops.user_id IS 'User who owns this international operation for proper access control';
COMMENT ON COLUMN public.international_ops.profile_updated_at IS 'Timestamp when international operation profile was last updated';

-- =====================================================
-- END OF SCRIPT
-- =====================================================
