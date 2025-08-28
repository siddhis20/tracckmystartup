-- Create facilitator access control system
-- This allows facilitators to view startup compliance tabs for 30 days

-- 1. Create facilitator_access table to track permissions
CREATE TABLE IF NOT EXISTS public.facilitator_access (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    facilitator_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    startup_id INTEGER NOT NULL REFERENCES public.startups(id) ON DELETE CASCADE,
    access_type TEXT NOT NULL DEFAULT 'compliance_view',
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '30 days'),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Add unique constraint to prevent duplicate access
ALTER TABLE public.facilitator_access 
ADD CONSTRAINT unique_facilitator_startup_access 
UNIQUE (facilitator_id, startup_id, access_type);

-- 3. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_facilitator_access_facilitator_id 
ON public.facilitator_access(facilitator_id);

CREATE INDEX IF NOT EXISTS idx_facilitator_access_startup_id 
ON public.facilitator_access(startup_id);

CREATE INDEX IF NOT EXISTS idx_facilitator_access_expires_at 
ON public.facilitator_access(expires_at) WHERE is_active = TRUE;

-- 4. Create RLS policies for facilitator_access table
ALTER TABLE public.facilitator_access ENABLE ROW LEVEL SECURITY;

-- Facilitators can view their own access records
CREATE POLICY facilitator_access_select_policy ON public.facilitator_access
    FOR SELECT TO authenticated
    USING (facilitator_id = auth.uid());

-- Startups can view who has access to their data
CREATE POLICY facilitator_access_startup_select_policy ON public.facilitator_access
    FOR SELECT TO authenticated
    USING (
        startup_id IN (
            SELECT id FROM public.startups 
            WHERE user_id = auth.uid()
        )
    );

-- System can insert/update access records
CREATE POLICY facilitator_access_insert_policy ON public.facilitator_access
    FOR INSERT TO authenticated
    WITH CHECK (TRUE);

CREATE POLICY facilitator_access_update_policy ON public.facilitator_access
    FOR UPDATE TO authenticated
    USING (TRUE);

-- 5. Create function to grant facilitator access
CREATE OR REPLACE FUNCTION grant_facilitator_compliance_access(
    p_facilitator_id UUID,
    p_startup_id INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    access_record_id UUID;
BEGIN
    -- Insert or update access record
    INSERT INTO public.facilitator_access (
        facilitator_id,
        startup_id,
        access_type,
        granted_at,
        expires_at,
        is_active
    ) VALUES (
        p_facilitator_id,
        p_startup_id,
        'compliance_view',
        NOW(),
        NOW() + INTERVAL '30 days',
        TRUE
    )
    ON CONFLICT (facilitator_id, startup_id, access_type)
    DO UPDATE SET
        granted_at = NOW(),
        expires_at = NOW() + INTERVAL '30 days',
        is_active = TRUE,
        updated_at = NOW()
    RETURNING id INTO access_record_id;
    
    RETURN access_record_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create function to check if facilitator has access
CREATE OR REPLACE FUNCTION check_facilitator_access(
    p_facilitator_id UUID,
    p_startup_id INTEGER,
    p_access_type TEXT DEFAULT 'compliance_view'
)
RETURNS BOOLEAN AS $$
DECLARE
    has_access BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM public.facilitator_access
        WHERE facilitator_id = p_facilitator_id
        AND startup_id = p_startup_id
        AND access_type = p_access_type
        AND is_active = TRUE
        AND expires_at > NOW()
    ) INTO has_access;
    
    RETURN has_access;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create function to revoke access
CREATE OR REPLACE FUNCTION revoke_facilitator_access(
    p_facilitator_id UUID,
    p_startup_id INTEGER,
    p_access_type TEXT DEFAULT 'compliance_view'
)
RETURNS BOOLEAN AS $$
DECLARE
    update_count INTEGER;
BEGIN
    UPDATE public.facilitator_access
    SET is_active = FALSE,
        updated_at = NOW()
    WHERE facilitator_id = p_facilitator_id
    AND startup_id = p_startup_id
    AND access_type = p_access_type;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RETURN update_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Create function to cleanup expired access
CREATE OR REPLACE FUNCTION cleanup_expired_access()
RETURNS INTEGER AS $$
DECLARE
    cleanup_count INTEGER;
BEGIN
    UPDATE public.facilitator_access
    SET is_active = FALSE,
        updated_at = NOW()
    WHERE expires_at <= NOW()
    AND is_active = TRUE;
    
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RETURN cleanup_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create trigger to automatically grant access when diligence is approved
CREATE OR REPLACE FUNCTION grant_facilitator_access_on_diligence_approval()
RETURNS TRIGGER AS $$
BEGIN
    -- Only trigger when diligence_status changes to 'approved'
    IF NEW.diligence_status = 'approved' AND OLD.diligence_status != 'approved' THEN
        -- Get facilitator_id from the opportunity
        PERFORM grant_facilitator_compliance_access(
            (SELECT facilitator_id FROM public.incubation_opportunities WHERE id = NEW.opportunity_id),
            NEW.startup_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 10. Create the trigger
DROP TRIGGER IF EXISTS diligence_approval_access_trigger ON public.opportunity_applications;
CREATE TRIGGER diligence_approval_access_trigger
    AFTER UPDATE ON public.opportunity_applications
    FOR EACH ROW
    EXECUTE FUNCTION grant_facilitator_access_on_diligence_approval();

-- 11. Grant execute permissions
GRANT EXECUTE ON FUNCTION grant_facilitator_compliance_access(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION check_facilitator_access(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION revoke_facilitator_access(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_access() TO authenticated;

-- 12. Create RPC functions for frontend access
CREATE OR REPLACE FUNCTION get_facilitator_access_list(p_facilitator_id UUID)
RETURNS TABLE (
    access_id UUID,
    startup_id INTEGER,
    startup_name TEXT,
    access_type TEXT,
    granted_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN,
    days_remaining INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fa.id as access_id,
        fa.startup_id,
        s.name as startup_name,
        fa.access_type,
        fa.granted_at,
        fa.expires_at,
        fa.is_active,
        EXTRACT(DAY FROM (fa.expires_at - NOW()))::INTEGER as days_remaining
    FROM public.facilitator_access fa
    JOIN public.startups s ON fa.startup_id = s.id
    WHERE fa.facilitator_id = p_facilitator_id
    AND fa.is_active = TRUE
    ORDER BY fa.granted_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Test the setup
SELECT 'FACILITATOR ACCESS CONTROL SETUP COMPLETE' as status;

-- Show current access records (if any)
SELECT 'Current access records:' as info;
SELECT 
    fa.id,
    u.name as facilitator_name,
    s.name as startup_name,
    fa.access_type,
    fa.granted_at,
    fa.expires_at,
    fa.is_active,
    EXTRACT(DAY FROM (fa.expires_at - NOW()))::INTEGER as days_remaining
FROM public.facilitator_access fa
JOIN public.users u ON fa.facilitator_id = u.id
JOIN public.startups s ON fa.startup_id = s.id
ORDER BY fa.granted_at DESC;

-- 14. Show function verification
SELECT 'Function verification:' as info;
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name IN (
    'grant_facilitator_compliance_access',
    'check_facilitator_access',
    'revoke_facilitator_access',
    'cleanup_expired_access',
    'get_facilitator_access_list'
)
ORDER BY routine_name;
