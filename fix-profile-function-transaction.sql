-- =====================================================
-- FIX PROFILE FUNCTION TRANSACTION ISSUE
-- =====================================================

-- Drop the existing function
DROP FUNCTION IF EXISTS get_startup_profile_simple(INTEGER);

-- Create a fixed version that ensures it sees the latest data
CREATE OR REPLACE FUNCTION get_startup_profile_simple(startup_id_param INTEGER)
RETURNS JSONB AS $$
DECLARE
    profile_data JSONB;
BEGIN
    -- Force a fresh read by using READ COMMITTED isolation
    -- This ensures we see the latest committed data
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    
    SELECT jsonb_build_object(
        'startup', jsonb_build_object(
            'id', s.id,
            'name', s.name,
            'country_of_registration', COALESCE(s.country_of_registration, 'USA'),
            'company_type', COALESCE(s.company_type, 'C-Corporation'),
            'registration_date', s.registration_date,
            'ca_service_code', s.ca_service_code,
            'cs_service_code', s.cs_service_code,
            'profile_updated_at', COALESCE(s.profile_updated_at, NOW())
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

-- Test the fixed function
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    profile_data JSONB;
BEGIN
    RAISE NOTICE 'Testing fixed get_startup_profile_simple function...';
    
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data;
    
    RAISE NOTICE 'Fixed function result: %', profile_data;
    
    IF profile_data IS NOT NULL AND profile_data ? 'subsidiaries' THEN
        RAISE NOTICE 'Subsidiaries from fixed function: %', profile_data->'subsidiaries';
    END IF;
    
END $$;
