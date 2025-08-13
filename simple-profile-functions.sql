-- =====================================================
-- SIMPLE PROFILE FUNCTIONS - BASIC TESTING
-- =====================================================

-- First, let's make sure we have the basic structure
-- Add missing columns to startups table if they don't exist
DO $$
BEGIN
    -- Add country_of_registration if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'startups' AND column_name = 'country_of_registration') THEN
        ALTER TABLE public.startups ADD COLUMN country_of_registration TEXT DEFAULT 'USA';
        RAISE NOTICE 'Added country_of_registration column';
    END IF;
    
    -- Add company_type if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'startups' AND column_name = 'company_type') THEN
        ALTER TABLE public.startups ADD COLUMN company_type TEXT DEFAULT 'C-Corporation';
        RAISE NOTICE 'Added company_type column';
    END IF;
    
    -- Add ca_service_code if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'startups' AND column_name = 'ca_service_code') THEN
        ALTER TABLE public.startups ADD COLUMN ca_service_code TEXT;
        RAISE NOTICE 'Added ca_service_code column';
    END IF;
    
    -- Add cs_service_code if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'startups' AND column_name = 'cs_service_code') THEN
        ALTER TABLE public.startups ADD COLUMN cs_service_code TEXT;
        RAISE NOTICE 'Added cs_service_code column';
    END IF;
    
    -- Add profile_updated_at if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'startups' AND column_name = 'profile_updated_at') THEN
        ALTER TABLE public.startups ADD COLUMN profile_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added profile_updated_at column';
    END IF;
    
    -- Add user_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'startups' AND column_name = 'user_id') THEN
        ALTER TABLE public.startups ADD COLUMN user_id UUID;
        RAISE NOTICE 'Added user_id column';
    END IF;
END $$;

-- Create simple get_startup_profile function
CREATE OR REPLACE FUNCTION get_startup_profile_simple(startup_id_param INTEGER)
RETURNS JSONB AS $$
DECLARE
    profile_data JSONB;
BEGIN
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

-- Create simple update_startup_profile function
CREATE OR REPLACE FUNCTION update_startup_profile_simple(
    startup_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE DEFAULT NULL,
    ca_service_code_param TEXT DEFAULT NULL,
    cs_service_code_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.startups 
    SET 
        country_of_registration = country_param,
        company_type = company_type_param,
        registration_date = COALESCE(registration_date_param, registration_date),
        ca_service_code = ca_service_code_param,
        cs_service_code = cs_service_code_param,
        profile_updated_at = NOW()
    WHERE id = startup_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create simple add_subsidiary function
CREATE OR REPLACE FUNCTION add_subsidiary_simple(
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
    
    RETURN subsidiary_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create simple add_international_op function
CREATE OR REPLACE FUNCTION add_international_op_simple(
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
    
    RETURN op_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the simple functions
SELECT '=== TESTING SIMPLE FUNCTIONS ===' as test_step;

-- Get a startup ID to test with
DO $$
DECLARE
    startup_id_val INTEGER;
    test_result JSONB;
    update_result BOOLEAN;
    subsidiary_id INTEGER;
    op_id INTEGER;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing with startup ID: %', startup_id_val;
        
        -- Test 1: Get profile
        BEGIN
            SELECT get_startup_profile_simple(startup_id_val) INTO test_result;
            RAISE NOTICE 'get_startup_profile_simple result: %', test_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'get_startup_profile_simple failed: %', SQLERRM;
        END;
        
        -- Test 2: Update profile
        BEGIN
            SELECT update_startup_profile_simple(startup_id_val, 'USA', 'C-Corporation', 'CA-TEST', 'CS-TEST') INTO update_result;
            RAISE NOTICE 'update_startup_profile_simple result: %', update_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'update_startup_profile_simple failed: %', SQLERRM;
        END;
        
        -- Test 3: Add subsidiary
        BEGIN
            SELECT add_subsidiary_simple(startup_id_val, 'UK', 'Limited Company (Ltd)', '2023-06-01') INTO subsidiary_id;
            RAISE NOTICE 'add_subsidiary_simple result: %', subsidiary_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'add_subsidiary_simple failed: %', SQLERRM;
        END;
        
        -- Test 4: Add international operation
        BEGIN
            SELECT add_international_op_simple(startup_id_val, 'Canada', '2023-01-15') INTO op_id;
            RAISE NOTICE 'add_international_op_simple result: %', op_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'add_international_op_simple failed: %', SQLERRM;
        END;
        
        -- Test 5: Get updated profile
        BEGIN
            SELECT get_startup_profile_simple(startup_id_val) INTO test_result;
            RAISE NOTICE 'Updated profile result: %', test_result;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Get updated profile failed: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE 'No startups found in database';
    END IF;
END $$;

SELECT 'Simple functions test completed. Check the NOTICE messages above.' as summary;
