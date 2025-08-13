-- =====================================================
-- TEST SUBSIDIARY UPDATE DIRECTLY
-- =====================================================

-- First, let's see what subsidiaries we have
SELECT 'Available subsidiaries:' as info;
SELECT id, startup_id, country, company_type, registration_date 
FROM subsidiaries 
ORDER BY id;

-- Test direct update on the first subsidiary
DO $$
DECLARE
    first_subsidiary_id INTEGER;
    update_result BOOLEAN;
BEGIN
    -- Get the first subsidiary ID
    SELECT id INTO first_subsidiary_id FROM subsidiaries ORDER BY id LIMIT 1;
    
    IF first_subsidiary_id IS NOT NULL THEN
        RAISE NOTICE 'Testing update on subsidiary ID: %', first_subsidiary_id;
        
        -- Show before
        RAISE NOTICE 'BEFORE UPDATE:';
        PERFORM id, country, company_type, registration_date 
        FROM subsidiaries WHERE id = first_subsidiary_id;
        
        -- Perform update
        SELECT update_subsidiary(
            first_subsidiary_id,
            'Updated Country',
            'Updated Company Type',
            '2025-12-31'::DATE
        ) INTO update_result;
        
        RAISE NOTICE 'Update result: %', update_result;
        
        -- Show after
        RAISE NOTICE 'AFTER UPDATE:';
        PERFORM id, country, company_type, registration_date 
        FROM subsidiaries WHERE id = first_subsidiary_id;
        
    ELSE
        RAISE NOTICE 'No subsidiaries found!';
    END IF;
END $$;

-- Also test with a direct SQL UPDATE to compare
DO $$
DECLARE
    first_subsidiary_id INTEGER;
    rows_affected INTEGER;
BEGIN
    SELECT id INTO first_subsidiary_id FROM subsidiaries ORDER BY id LIMIT 1;
    
    IF first_subsidiary_id IS NOT NULL THEN
        RAISE NOTICE 'Testing direct SQL UPDATE on subsidiary ID: %', first_subsidiary_id;
        
        -- Direct SQL update
        UPDATE subsidiaries 
        SET 
            country = 'Direct SQL Country',
            company_type = 'Direct SQL Type',
            registration_date = '2025-11-30'::DATE,
            updated_at = NOW()
        WHERE id = first_subsidiary_id;
        
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Direct SQL UPDATE affected % rows', rows_affected;
        
        -- Show result
        RAISE NOTICE 'After direct SQL UPDATE:';
        PERFORM id, country, company_type, registration_date 
        FROM subsidiaries WHERE id = first_subsidiary_id;
        
    END IF;
END $$;
