-- =====================================================
-- AGGRESSIVE PROFILE FUNCTION FIX
-- =====================================================

-- Drop the existing function
DROP FUNCTION IF EXISTS get_startup_profile_simple(INTEGER);

-- Create a more aggressive version that forces fresh data
CREATE OR REPLACE FUNCTION get_startup_profile_simple(startup_id_param INTEGER)
RETURNS JSONB AS $$
DECLARE
    profile_data JSONB;
    startup_data RECORD;
    subsidiaries_data JSONB;
    international_ops_data JSONB;
BEGIN
    -- Force a completely fresh read by doing separate queries
    -- This bypasses any potential caching or transaction isolation issues
    
    -- Get startup data
    SELECT 
        s.id,
        s.name,
        COALESCE(s.country_of_registration, 'USA') as country_of_registration,
        COALESCE(s.company_type, 'C-Corporation') as company_type,
        s.registration_date,
        s.ca_service_code,
        s.cs_service_code,
        COALESCE(s.profile_updated_at, NOW()) as profile_updated_at
    INTO startup_data
    FROM public.startups s
    WHERE s.id = startup_id_param;
    
    -- Get subsidiaries data with explicit ordering
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id', sub.id,
                'country', sub.country,
                'company_type', sub.company_type,
                'registration_date', sub.registration_date
            ) ORDER BY sub.id
        ),
        '[]'::jsonb
    ) INTO subsidiaries_data
    FROM public.subsidiaries sub 
    WHERE sub.startup_id = startup_id_param;
    
    -- Get international operations data
    SELECT COALESCE(
        jsonb_agg(
            jsonb_build_object(
                'id', io.id,
                'country', io.country,
                'start_date', io.start_date
            ) ORDER BY io.id
        ),
        '[]'::jsonb
    ) INTO international_ops_data
    FROM public.international_ops io 
    WHERE io.startup_id = startup_id_param;
    
    -- Build the final result
    SELECT jsonb_build_object(
        'startup', jsonb_build_object(
            'id', startup_data.id,
            'name', startup_data.name,
            'country_of_registration', startup_data.country_of_registration,
            'company_type', startup_data.company_type,
            'registration_date', startup_data.registration_date,
            'ca_service_code', startup_data.ca_service_code,
            'cs_service_code', startup_data.cs_service_code,
            'profile_updated_at', startup_data.profile_updated_at
        ),
        'subsidiaries', subsidiaries_data,
        'international_ops', international_ops_data
    ) INTO profile_data;
    
    RETURN profile_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the aggressive fix
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    profile_data JSONB;
BEGIN
    RAISE NOTICE 'Testing aggressive get_startup_profile_simple function...';
    
    SELECT get_startup_profile_simple(test_startup_id) INTO profile_data;
    
    RAISE NOTICE 'Aggressive function result: %', profile_data;
    
    IF profile_data IS NOT NULL AND profile_data ? 'subsidiaries' THEN
        RAISE NOTICE 'Subsidiaries from aggressive function: %', profile_data->'subsidiaries';
    END IF;
    
END $$;

-- Also create a simple direct query function as backup
CREATE OR REPLACE FUNCTION get_subsidiaries_direct(startup_id_param INTEGER)
RETURNS JSONB AS $$
BEGIN
    RETURN COALESCE(
        (SELECT jsonb_agg(
            jsonb_build_object(
                'id', sub.id,
                'country', sub.country,
                'company_type', sub.company_type,
                'registration_date', sub.registration_date
            )
        ) FROM public.subsidiaries sub WHERE sub.startup_id = startup_id_param),
        '[]'::jsonb
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the direct subsidiaries function
DO $$
DECLARE
    test_startup_id INTEGER := 11;
    subsidiaries_data JSONB;
BEGIN
    RAISE NOTICE 'Testing direct subsidiaries function...';
    
    SELECT get_subsidiaries_direct(test_startup_id) INTO subsidiaries_data;
    
    RAISE NOTICE 'Direct subsidiaries result: %', subsidiaries_data;
    
END $$;
