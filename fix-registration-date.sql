-- =====================================================
-- FIX REGISTRATION DATE UPDATE ISSUE
-- =====================================================

-- Update the simple update_startup_profile function to include registration_date
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

-- Test the updated function
DO $$
DECLARE
    startup_id_val INTEGER;
    update_result BOOLEAN;
BEGIN
    -- Get first startup
    SELECT id INTO startup_id_val FROM startups ORDER BY id LIMIT 1;
    
    IF startup_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing updated function with startup ID: %', startup_id_val;
        
        -- Test update with registration date
        SELECT update_startup_profile_simple(
            startup_id_val,
            'India',
            'Private Limited Company',
            '2025-01-15'::DATE,
            'TEST123',
            'TEST456'
        ) INTO update_result;
        
        RAISE NOTICE 'Update result: %', update_result;
        
        -- Show the updated data
        PERFORM id, name, country_of_registration, company_type, registration_date, ca_service_code, cs_service_code 
        FROM startups WHERE id = startup_id_val;
    ELSE
        RAISE NOTICE 'No startups found for testing';
    END IF;
END $$;
