-- =====================================================
-- DYNAMIC PROFILE SECTION TABLES AND FUNCTIONS
-- =====================================================

-- This SQL script creates the necessary tables and functions
-- for a dynamic profile section with real-time updates

-- =====================================================
-- 1. ENHANCE EXISTING TABLES
-- =====================================================

-- Add missing columns to startups table for profile data
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS country_of_registration TEXT DEFAULT 'USA',
ADD COLUMN IF NOT EXISTS company_type TEXT DEFAULT 'C-Corporation',
ADD COLUMN IF NOT EXISTS ca_service_code TEXT,
ADD COLUMN IF NOT EXISTS cs_service_code TEXT,
ADD COLUMN IF NOT EXISTS profile_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add user_id to startups table for proper ownership
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- =====================================================
-- 2. CREATE PROFILE AUDIT TABLE FOR REAL-TIME TRACKING
-- =====================================================

CREATE TABLE IF NOT EXISTS public.profile_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- 'created', 'updated', 'deleted'
    table_name TEXT NOT NULL, -- 'startups', 'subsidiaries', 'international_ops'
    record_id TEXT NOT NULL, -- ID of the affected record
    old_values JSONB, -- Previous values
    new_values JSONB, -- New values
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. CREATE PROFILE NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.profile_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    startup_id INTEGER REFERENCES public.startups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL, -- 'profile_updated', 'subsidiary_added', 'international_op_added'
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. CREATE PROFILE TEMPLATES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.profile_templates (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    country TEXT NOT NULL,
    company_type TEXT NOT NULL,
    sector TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 5. CREATE FUNCTIONS FOR PROFILE OPERATIONS
-- =====================================================

-- Function to get complete profile data for a startup
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
                'registration_date', sub.registration_date
            )) FROM public.subsidiaries sub WHERE sub.startup_id = s.id),
            '[]'::jsonb
        ),
        'international_ops', COALESCE(
            (SELECT jsonb_agg(jsonb_build_object(
                'id', io.id,
                'country', io.country,
                'start_date', io.start_date
            )) FROM public.international_ops io WHERE io.startup_id = s.id),
            '[]'::jsonb
        )
    ) INTO profile_data
    FROM public.startups s
    WHERE s.id = startup_id_param;
    
    RETURN profile_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update startup profile
CREATE OR REPLACE FUNCTION update_startup_profile(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    ca_service_code_param TEXT DEFAULT NULL,
    cs_service_code_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    old_values JSONB;
    new_values JSONB;
BEGIN
    -- Get old values for audit
    SELECT jsonb_build_object(
        'country_of_registration', country_of_registration,
        'company_type', company_type,
        'ca_service_code', ca_service_code,
        'cs_service_code', cs_service_code
    ) INTO old_values
    FROM public.startups
    WHERE id = startup_id_param;
    
    -- Update startup profile
    UPDATE public.startups 
    SET 
        country_of_registration = country_param,
        company_type = company_type_param,
        ca_service_code = ca_service_code_param,
        cs_service_code = cs_service_code_param,
        profile_updated_at = NOW()
    WHERE id = startup_id_param;
    
    -- Get new values for audit
    SELECT jsonb_build_object(
        'country_of_registration', country_of_registration,
        'company_type', company_type,
        'ca_service_code', ca_service_code,
        'cs_service_code', cs_service_code
    ) INTO new_values
    FROM public.startups
    WHERE id = startup_id_param;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, old_values, new_values
    ) VALUES (
        startup_id_param,
        (SELECT user_id FROM public.startups WHERE id = startup_id_param),
        'updated',
        'startups',
        startup_id_param::TEXT,
        old_values,
        new_values
    );
    
    -- Create notification
    INSERT INTO public.profile_notifications (
        startup_id, user_id, notification_type, title, message
    ) VALUES (
        startup_id_param,
        (SELECT user_id FROM public.startups WHERE id = startup_id_param),
        'profile_updated',
        'Profile Updated',
        'Startup profile information has been updated successfully.'
    );
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add subsidiary
CREATE OR REPLACE FUNCTION add_subsidiary(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE
)
RETURNS INTEGER AS $$
DECLARE
    subsidiary_id INTEGER;
BEGIN
    INSERT INTO public.subsidiaries (
        startup_id, country, company_type, registration_date
    ) VALUES (
        startup_id_param, country_param, company_type_param, registration_date_param
    ) RETURNING id INTO subsidiary_id;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, new_values
    ) VALUES (
        startup_id_param,
        (SELECT user_id FROM public.startups WHERE id = startup_id_param),
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
        (SELECT user_id FROM public.startups WHERE id = startup_id_param),
        'subsidiary_added',
        'Subsidiary Added',
        'New subsidiary added: ' || country_param || ' - ' || company_type_param
    );
    
    RETURN subsidiary_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update subsidiary
CREATE OR REPLACE FUNCTION update_subsidiary(
    subsidiary_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE
)
RETURNS BOOLEAN AS $$
DECLARE
    startup_id_val INTEGER;
    old_values JSONB;
    new_values JSONB;
BEGIN
    -- Get startup_id and old values
    SELECT startup_id, jsonb_build_object(
        'country', country,
        'company_type', company_type,
        'registration_date', registration_date
    ) INTO startup_id_val, old_values
    FROM public.subsidiaries
    WHERE id = subsidiary_id_param;
    
    -- Update subsidiary
    UPDATE public.subsidiaries 
    SET 
        country = country_param,
        company_type = company_type_param,
        registration_date = registration_date_param
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
        (SELECT user_id FROM public.startups WHERE id = startup_id_val),
        'updated',
        'subsidiaries',
        subsidiary_id_param::TEXT,
        old_values,
        new_values
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete subsidiary
CREATE OR REPLACE FUNCTION delete_subsidiary(subsidiary_id_param INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    startup_id_val INTEGER;
    old_values JSONB;
BEGIN
    -- Get startup_id and old values
    SELECT startup_id, jsonb_build_object(
        'country', country,
        'company_type', company_type,
        'registration_date', registration_date
    ) INTO startup_id_val, old_values
    FROM public.subsidiaries
    WHERE id = subsidiary_id_param;
    
    -- Delete subsidiary
    DELETE FROM public.subsidiaries WHERE id = subsidiary_id_param;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, old_values
    ) VALUES (
        startup_id_val,
        (SELECT user_id FROM public.startups WHERE id = startup_id_val),
        'deleted',
        'subsidiaries',
        subsidiary_id_param::TEXT,
        old_values
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add international operation
CREATE OR REPLACE FUNCTION add_international_op(
    startup_id_param INTEGER,
    country_param TEXT,
    start_date_param DATE
)
RETURNS INTEGER AS $$
DECLARE
    op_id INTEGER;
BEGIN
    INSERT INTO public.international_ops (
        startup_id, country, start_date
    ) VALUES (
        startup_id_param, country_param, start_date_param
    ) RETURNING id INTO op_id;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, new_values
    ) VALUES (
        startup_id_param,
        (SELECT user_id FROM public.startups WHERE id = startup_id_param),
        'created',
        'international_ops',
        op_id::TEXT,
        jsonb_build_object(
            'country', country_param,
            'start_date', start_date_param
        )
    );
    
    -- Create notification
    INSERT INTO public.profile_notifications (
        startup_id, user_id, notification_type, title, message
    ) VALUES (
        startup_id_param,
        (SELECT user_id FROM public.startups WHERE id = startup_id_param),
        'international_op_added',
        'International Operation Added',
        'New international operation added: ' || country_param
    );
    
    RETURN op_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update international operation
CREATE OR REPLACE FUNCTION update_international_op(
    op_id_param INTEGER,
    country_param TEXT,
    start_date_param DATE
)
RETURNS BOOLEAN AS $$
DECLARE
    startup_id_val INTEGER;
    old_values JSONB;
    new_values JSONB;
BEGIN
    -- Get startup_id and old values
    SELECT startup_id, jsonb_build_object(
        'country', country,
        'start_date', start_date
    ) INTO startup_id_val, old_values
    FROM public.international_ops
    WHERE id = op_id_param;
    
    -- Update international operation
    UPDATE public.international_ops 
    SET 
        country = country_param,
        start_date = start_date_param
    WHERE id = op_id_param;
    
    -- Get new values
    SELECT jsonb_build_object(
        'country', country,
        'start_date', start_date
    ) INTO new_values
    FROM public.international_ops
    WHERE id = op_id_param;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, old_values, new_values
    ) VALUES (
        startup_id_val,
        (SELECT user_id FROM public.startups WHERE id = startup_id_val),
        'updated',
        'international_ops',
        op_id_param::TEXT,
        old_values,
        new_values
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete international operation
CREATE OR REPLACE FUNCTION delete_international_op(op_id_param INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    startup_id_val INTEGER;
    old_values JSONB;
BEGIN
    -- Get startup_id and old values
    SELECT startup_id, jsonb_build_object(
        'country', country,
        'start_date', start_date
    ) INTO startup_id_val, old_values
    FROM public.international_ops
    WHERE id = op_id_param;
    
    -- Delete international operation
    DELETE FROM public.international_ops WHERE id = op_id_param;
    
    -- Log audit entry
    INSERT INTO public.profile_audit_log (
        startup_id, user_id, action, table_name, record_id, old_values
    ) VALUES (
        startup_id_val,
        (SELECT user_id FROM public.startups WHERE id = startup_id_val),
        'deleted',
        'international_ops',
        op_id_param::TEXT,
        old_values
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. CREATE ROW LEVEL SECURITY POLICIES
-- =====================================================

-- Enable RLS on all profile-related tables
ALTER TABLE public.profile_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_templates ENABLE ROW LEVEL SECURITY;

-- Profile audit log policies
CREATE POLICY "Users can view their own profile audit logs" ON public.profile_audit_log
    FOR SELECT USING (
        user_id = auth.uid() OR 
        startup_id IN (SELECT id FROM public.startups WHERE user_id = auth.uid())
    );

-- Profile notifications policies
CREATE POLICY "Users can view their own profile notifications" ON public.profile_notifications
    FOR SELECT USING (
        user_id = auth.uid() OR 
        startup_id IN (SELECT id FROM public.startups WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can update their own profile notifications" ON public.profile_notifications
    FOR UPDATE USING (
        user_id = auth.uid() OR 
        startup_id IN (SELECT id FROM public.startups WHERE user_id = auth.uid())
    );

-- Profile templates policies (read-only for all authenticated users)
CREATE POLICY "Authenticated users can view profile templates" ON public.profile_templates
    FOR SELECT USING (auth.role() = 'authenticated');

-- =====================================================
-- 7. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes for profile audit log
CREATE INDEX IF NOT EXISTS idx_profile_audit_startup_id ON public.profile_audit_log(startup_id);
CREATE INDEX IF NOT EXISTS idx_profile_audit_user_id ON public.profile_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_profile_audit_changed_at ON public.profile_audit_log(changed_at);

-- Indexes for profile notifications
CREATE INDEX IF NOT EXISTS idx_profile_notifications_startup_id ON public.profile_notifications(startup_id);
CREATE INDEX IF NOT EXISTS idx_profile_notifications_user_id ON public.profile_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_profile_notifications_is_read ON public.profile_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_profile_notifications_created_at ON public.profile_notifications(created_at);

-- Indexes for profile templates
CREATE INDEX IF NOT EXISTS idx_profile_templates_country ON public.profile_templates(country);
CREATE INDEX IF NOT EXISTS idx_profile_templates_sector ON public.profile_templates(sector);
CREATE INDEX IF NOT EXISTS idx_profile_templates_is_active ON public.profile_templates(is_active);

-- =====================================================
-- 8. INSERT SAMPLE PROFILE TEMPLATES
-- =====================================================

INSERT INTO public.profile_templates (name, description, country, company_type, sector) VALUES
('US Tech Startup', 'Standard template for US technology startups', 'USA', 'C-Corporation', 'Technology'),
('US FinTech Startup', 'Template for US financial technology companies', 'USA', 'C-Corporation', 'FinTech'),
('UK Tech Startup', 'Standard template for UK technology startups', 'UK', 'Limited Company (Ltd)', 'Technology'),
('India Tech Startup', 'Template for Indian technology startups', 'India', 'Private Limited Company', 'Technology'),
('Singapore Tech Startup', 'Template for Singapore technology startups', 'Singapore', 'Private Limited', 'Technology');

-- =====================================================
-- 9. CREATE TRIGGERS FOR REAL-TIME UPDATES
-- =====================================================

-- Trigger function to notify profile changes
CREATE OR REPLACE FUNCTION notify_profile_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify about profile changes via Supabase real-time
    PERFORM pg_notify(
        'profile_changes',
        json_build_object(
            'table', TG_TABLE_NAME,
            'action', TG_OP,
            'record_id', COALESCE(NEW.id, OLD.id),
            'startup_id', COALESCE(NEW.startup_id, OLD.startup_id)
        )::text
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create triggers for real-time notifications
CREATE TRIGGER trigger_profile_audit_notify
    AFTER INSERT OR UPDATE OR DELETE ON public.profile_audit_log
    FOR EACH ROW EXECUTE FUNCTION notify_profile_changes();

CREATE TRIGGER trigger_profile_notifications_notify
    AFTER INSERT OR UPDATE ON public.profile_notifications
    FOR EACH ROW EXECUTE FUNCTION notify_profile_changes();

-- =====================================================
-- 10. COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE public.profile_audit_log IS 'Audit trail for all profile-related changes';
COMMENT ON TABLE public.profile_notifications IS 'Notifications for profile-related activities';
COMMENT ON TABLE public.profile_templates IS 'Predefined profile templates for different countries and sectors';

COMMENT ON FUNCTION get_startup_profile(INTEGER) IS 'Get complete profile data for a startup including subsidiaries and international operations';
COMMENT ON FUNCTION update_startup_profile(INTEGER, TEXT, TEXT, TEXT, TEXT) IS 'Update startup profile information with audit logging';
COMMENT ON FUNCTION add_subsidiary(INTEGER, TEXT, TEXT, DATE) IS 'Add a new subsidiary with audit logging and notifications';
COMMENT ON FUNCTION add_international_op(INTEGER, TEXT, DATE) IS 'Add a new international operation with audit logging and notifications';

-- =====================================================
-- END OF SCRIPT
-- =====================================================
