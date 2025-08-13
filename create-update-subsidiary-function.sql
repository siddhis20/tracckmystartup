-- =====================================================
-- CREATE UPDATE SUBSIDIARY FUNCTION
-- =====================================================

-- Create the update_subsidiary function
CREATE OR REPLACE FUNCTION update_subsidiary(
    subsidiary_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.subsidiaries 
    SET 
        country = country_param,
        company_type = company_type_param,
        registration_date = registration_date_param,
        updated_at = NOW()
    WHERE id = subsidiary_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the update_international_op function
CREATE OR REPLACE FUNCTION update_international_op(
    op_id_param INTEGER,
    country_param TEXT,
    start_date_param DATE
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.international_ops 
    SET 
        country = country_param,
        start_date = start_date_param,
        updated_at = NOW()
    WHERE id = op_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the functions
DO $$
DECLARE
    subsidiary_id_val INTEGER;
    op_id_val INTEGER;
    update_result BOOLEAN;
BEGIN
    -- Get first subsidiary
    SELECT id INTO subsidiary_id_val FROM subsidiaries ORDER BY id LIMIT 1;
    
    IF subsidiary_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing update_subsidiary with ID: %', subsidiary_id_val;
        
        -- Test update subsidiary
        SELECT update_subsidiary(
            subsidiary_id_val,
            'India',
            'Private Limited Company',
            '2025-01-20'::DATE
        ) INTO update_result;
        
        RAISE NOTICE 'update_subsidiary result: %', update_result;
        
        -- Show the updated data
        PERFORM id, startup_id, country, company_type, registration_date 
        FROM subsidiaries WHERE id = subsidiary_id_val;
    ELSE
        RAISE NOTICE 'No subsidiaries found for testing';
    END IF;
    
    -- Get first international operation
    SELECT id INTO op_id_val FROM international_ops ORDER BY id LIMIT 1;
    
    IF op_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing update_international_op with ID: %', op_id_val;
        
        -- Test update international operation
        SELECT update_international_op(
            op_id_val,
            'Japan',
            '2025-02-15'::DATE
        ) INTO update_result;
        
        RAISE NOTICE 'update_international_op result: %', update_result;
        
        -- Show the updated data
        PERFORM id, startup_id, country, start_date 
        FROM international_ops WHERE id = op_id_val;
    ELSE
        RAISE NOTICE 'No international operations found for testing';
    END IF;
END $$;
