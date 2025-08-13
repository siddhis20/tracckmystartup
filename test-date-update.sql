-- =====================================================
-- TEST DATE UPDATE FUNCTIONALITY
-- =====================================================

-- Test updating a subsidiary with a new date
DO $$
DECLARE
    subsidiary_id_val INTEGER;
    update_result BOOLEAN;
    current_date_val DATE;
BEGIN
    -- Get first subsidiary
    SELECT id INTO subsidiary_id_val FROM subsidiaries ORDER BY id LIMIT 1;
    
    IF subsidiary_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing date update for subsidiary ID: %', subsidiary_id_val;
        
        -- Get current date
        current_date_val := CURRENT_DATE;
        RAISE NOTICE 'Current date: %', current_date_val;
        
        -- Show current data
        RAISE NOTICE 'Current subsidiary data:';
        PERFORM id, startup_id, country, company_type, registration_date, updated_at
        FROM subsidiaries WHERE id = subsidiary_id_val;
        
        -- Test update with current date
        SELECT update_subsidiary(
            subsidiary_id_val,
            'Germany',
            'GmbH',
            current_date_val
        ) INTO update_result;
        
        RAISE NOTICE 'update_subsidiary result: %', update_result;
        
        -- Show updated data
        RAISE NOTICE 'Updated subsidiary data:';
        PERFORM id, startup_id, country, company_type, registration_date, updated_at
        FROM subsidiaries WHERE id = subsidiary_id_val;
        
    ELSE
        RAISE NOTICE 'No subsidiaries found for testing';
    END IF;
END $$;

-- Test with a specific date string
DO $$
DECLARE
    subsidiary_id_val INTEGER;
    update_result BOOLEAN;
BEGIN
    -- Get first subsidiary
    SELECT id INTO subsidiary_id_val FROM subsidiaries ORDER BY id LIMIT 1;
    
    IF subsidiary_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing with specific date string for subsidiary ID: %', subsidiary_id_val;
        
        -- Test update with specific date
        SELECT update_subsidiary(
            subsidiary_id_val,
            'Japan',
            'Kabushiki Kaisha',
            '2025-12-25'::DATE
        ) INTO update_result;
        
        RAISE NOTICE 'update_subsidiary result: %', update_result;
        
        -- Show final data
        RAISE NOTICE 'Final subsidiary data:';
        PERFORM id, startup_id, country, company_type, registration_date, updated_at
        FROM subsidiaries WHERE id = subsidiary_id_val;
        
    ELSE
        RAISE NOTICE 'No subsidiaries found for testing';
    END IF;
END $$;
