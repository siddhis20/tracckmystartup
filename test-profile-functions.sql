-- =====================================================
-- TEST PROFILE FUNCTIONS
-- =====================================================

-- This script tests the profile functions to ensure they work correctly

-- First, let's check what startups exist in the database
SELECT 'Checking available startups...' as test_step;
SELECT id, name, country_of_registration, company_type FROM startups ORDER BY id LIMIT 10;

-- Get the first available startup ID (or create one if none exist)
DO $$
DECLARE
    startup_id_val INTEGER;
BEGIN
    -- Try to get the first startup ID
    SELECT id INTO startup_id_val FROM startups ORDER BY id LIMIT 1;
    
    -- If no startups exist, create one for testing
    IF startup_id_val IS NULL THEN
        INSERT INTO startups (
            name, 
            investment_type, 
            investment_value, 
            equity_allocation, 
            current_valuation, 
            compliance_status, 
            sector, 
            total_funding, 
            total_revenue, 
            registration_date,
            country_of_registration,
            company_type
        ) VALUES (
            'Test Startup', 
            'Seed', 
            1000000, 
            10.0, 
            5000000, 
            'Pending', 
            'Technology', 
            1000000, 
            500000, 
            '2023-01-01',
            'USA',
            'C-Corporation'
        ) RETURNING id INTO startup_id_val;
        
        RAISE NOTICE 'Created test startup with ID: %', startup_id_val;
    ELSE
        RAISE NOTICE 'Using existing startup with ID: %', startup_id_val;
    END IF;
    
    -- Store the startup ID in a temporary table for use in subsequent queries
    CREATE TEMP TABLE test_startup_id AS SELECT startup_id_val as id;
END $$;

-- Get the startup ID we'll use for testing
SELECT 'Using startup ID:' as test_step, id as startup_id FROM test_startup_id;

-- Test 1: Get startup profile (should work even if no profile data exists)
SELECT 'Test 1: Get startup profile' as test_step;
SELECT get_startup_profile((SELECT id FROM test_startup_id));

-- Test 2: Update startup profile
SELECT 'Test 2: Update startup profile' as test_step;
SELECT update_startup_profile((SELECT id FROM test_startup_id), 'USA', 'C-Corporation', 'CA-12345', 'CS-67890');

-- Test 3: Verify the update worked
SELECT 'Test 3: Verify profile update' as test_step;
SELECT get_startup_profile((SELECT id FROM test_startup_id));

-- Test 4: Add a subsidiary
SELECT 'Test 4: Add subsidiary' as test_step;
SELECT add_subsidiary((SELECT id FROM test_startup_id), 'UK', 'Limited Company (Ltd)', '2023-06-01');

-- Test 5: Add another subsidiary
SELECT 'Test 5: Add another subsidiary' as test_step;
SELECT add_subsidiary((SELECT id FROM test_startup_id), 'Singapore', 'Private Limited', '2023-09-15');

-- Test 6: Add international operation
SELECT 'Test 6: Add international operation' as test_step;
SELECT add_international_op((SELECT id FROM test_startup_id), 'Canada', '2023-01-15');

-- Test 7: Verify all data was added correctly
SELECT 'Test 7: Verify complete profile' as test_step;
SELECT get_startup_profile((SELECT id FROM test_startup_id));

-- Test 8: Check audit log
SELECT 'Test 8: Check audit log' as test_step;
SELECT action, table_name, record_id, changed_at 
FROM profile_audit_log 
WHERE startup_id = (SELECT id FROM test_startup_id)
ORDER BY changed_at DESC 
LIMIT 10;

-- Test 9: Check notifications
SELECT 'Test 9: Check notifications' as test_step;
SELECT notification_type, title, message, created_at 
FROM profile_notifications 
WHERE startup_id = (SELECT id FROM test_startup_id)
ORDER BY created_at DESC 
LIMIT 10;

-- Test 10: Check subsidiaries table
SELECT 'Test 10: Check subsidiaries' as test_step;
SELECT id, country, company_type, registration_date 
FROM subsidiaries 
WHERE startup_id = (SELECT id FROM test_startup_id);

-- Test 11: Check international operations table
SELECT 'Test 11: Check international operations' as test_step;
SELECT id, country, start_date 
FROM international_ops 
WHERE startup_id = (SELECT id FROM test_startup_id);

-- Test 12: Test profile templates
SELECT 'Test 12: Check profile templates' as test_step;
SELECT name, country, company_type, sector 
FROM profile_templates 
WHERE is_active = true;

-- Test 13: Check the enhanced startups table
SELECT 'Test 13: Check enhanced startups table' as test_step;
SELECT id, name, country_of_registration, company_type, ca_service_code, cs_service_code, profile_updated_at
FROM startups 
WHERE id = (SELECT id FROM test_startup_id);

-- =====================================================
-- SUMMARY
-- =====================================================

SELECT 'All tests completed. Check the results above.' as summary;
SELECT 'Test startup ID used:' as info, id as startup_id FROM test_startup_id;
