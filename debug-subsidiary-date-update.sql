-- =====================================================
-- DEBUG SUBSIDIARY DATE UPDATE ISSUE
-- =====================================================

-- First, let's check what subsidiaries exist
SELECT 'Current subsidiaries:' as info;
SELECT id, startup_id, country, company_type, registration_date, updated_at 
FROM subsidiaries 
ORDER BY id;

-- Check if update_subsidiary function exists
SELECT 'Checking update_subsidiary function:' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'update_subsidiary';

-- Test updating a subsidiary with a new date
DO $$
DECLARE
    subsidiary_id_val INTEGER;
    update_result BOOLEAN;
    test_date DATE := '2025-12-25';
BEGIN
    -- Get first subsidiary
    SELECT id INTO subsidiary_id_val FROM subsidiaries ORDER BY id LIMIT 1;
    
    IF subsidiary_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing date update for subsidiary ID: %', subsidiary_id_val;
        RAISE NOTICE 'Test date: %', test_date;
        
        -- Show current data
        RAISE NOTICE 'Current subsidiary data:';
        PERFORM id, startup_id, country, company_type, registration_date, updated_at
        FROM subsidiaries WHERE id = subsidiary_id_val;
        
        -- Test update with specific date
        SELECT update_subsidiary(
            subsidiary_id_val,
            'Test Country',
            'Test Company Type',
            test_date
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

-- Check if there are any triggers that might be interfering
SELECT 'Checking for triggers on subsidiaries table:' as info;
SELECT trigger_name, event_manipulation, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'subsidiaries';

-- Check the actual update_subsidiary function definition
SELECT 'update_subsidiary function definition:' as info;
SELECT pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'update_subsidiary';
