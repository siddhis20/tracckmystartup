-- =====================================================
-- VERIFY SUBSIDIARY UPDATE FUNCTION
-- =====================================================

-- First, let's see the current state
SELECT 'Current subsidiaries before update:' as info;
SELECT id, startup_id, country, company_type, registration_date, updated_at 
FROM subsidiaries 
ORDER BY id;

-- Test the update_subsidiary function on a specific subsidiary
DO $$
DECLARE
    test_subsidiary_id INTEGER := 7; -- Use a specific ID we know exists
    update_result BOOLEAN;
    test_date DATE := '2025-12-25';
BEGIN
    RAISE NOTICE 'Testing update_subsidiary function on subsidiary ID: %', test_subsidiary_id;
    RAISE NOTICE 'Test date: %', test_date;
    
    -- Show current data for this specific subsidiary
    RAISE NOTICE 'Current data for subsidiary %:', test_subsidiary_id;
    PERFORM id, country, company_type, registration_date 
    FROM subsidiaries WHERE id = test_subsidiary_id;
    
    -- Call the update function
    SELECT update_subsidiary(
        test_subsidiary_id,
        'Test Country Updated',
        'Test Company Type Updated',
        test_date
    ) INTO update_result;
    
    RAISE NOTICE 'update_subsidiary result: %', update_result;
    
    -- Show updated data
    RAISE NOTICE 'Updated data for subsidiary %:', test_subsidiary_id;
    PERFORM id, country, company_type, registration_date 
    FROM subsidiaries WHERE id = test_subsidiary_id;
    
END $$;

-- Show final state
SELECT 'Final subsidiaries after update:' as info;
SELECT id, startup_id, country, company_type, registration_date, updated_at 
FROM subsidiaries 
ORDER BY id;

-- Check if the function exists and its definition
SELECT 'Function definition:' as info;
SELECT pg_get_functiondef(oid) as function_definition
FROM pg_proc 
WHERE proname = 'update_subsidiary' 
AND pronargs = 4;
