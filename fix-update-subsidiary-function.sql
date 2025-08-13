-- =====================================================
-- FIX UPDATE SUBSIDIARY FUNCTION
-- =====================================================

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS update_subsidiary(INTEGER, TEXT, TEXT, DATE);

-- Create an improved version with better error handling
CREATE OR REPLACE FUNCTION update_subsidiary(
    subsidiary_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param DATE
)
RETURNS BOOLEAN AS $$
DECLARE
    rows_affected INTEGER;
    current_data RECORD;
BEGIN
    -- Log the input parameters
    RAISE NOTICE 'update_subsidiary called with: id=%, country=%, company_type=%, registration_date=%', 
        subsidiary_id_param, country_param, company_type_param, registration_date_param;
    
    -- Check if subsidiary exists
    SELECT * INTO current_data FROM subsidiaries WHERE id = subsidiary_id_param;
    IF NOT FOUND THEN
        RAISE NOTICE 'Subsidiary with ID % not found', subsidiary_id_param;
        RETURN FALSE;
    END IF;
    
    -- Log current data
    RAISE NOTICE 'Current subsidiary data: id=%, country=%, company_type=%, registration_date=%', 
        current_data.id, current_data.country, current_data.company_type, current_data.registration_date;
    
    -- Perform the update
    UPDATE public.subsidiaries 
    SET 
        country = country_param,
        company_type = company_type_param,
        registration_date = registration_date_param,
        updated_at = NOW()
    WHERE id = subsidiary_id_param;
    
    -- Check how many rows were affected
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'UPDATE affected % rows', rows_affected;
    
    -- Verify the update
    SELECT * INTO current_data FROM subsidiaries WHERE id = subsidiary_id_param;
    RAISE NOTICE 'Updated subsidiary data: id=%, country=%, company_type=%, registration_date=%', 
        current_data.id, current_data.country, current_data.company_type, current_data.registration_date;
    
    -- Return success if at least one row was updated
    RETURN rows_affected > 0;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in update_subsidiary: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Test the improved function
DO $$
DECLARE
    subsidiary_id_val INTEGER;
    update_result BOOLEAN;
BEGIN
    -- Get first subsidiary
    SELECT id INTO subsidiary_id_val FROM subsidiaries ORDER BY id LIMIT 1;
    
    IF subsidiary_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing improved update_subsidiary function on ID: %', subsidiary_id_val;
        
        SELECT update_subsidiary(
            subsidiary_id_val,
            'Improved Test Country',
            'Improved Test Type',
            '2025-10-15'::DATE
        ) INTO update_result;
        
        RAISE NOTICE 'Improved function result: %', update_result;
        
    ELSE
        RAISE NOTICE 'No subsidiaries found for testing';
    END IF;
END $$;
