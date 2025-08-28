-- TEST_RECOGNITION_BACKEND.sql
-- This script tests the recognition backend setup and facilitator connection

-- Step 1: Check if the recognition_records table exists
SELECT '=== CHECKING TABLE EXISTENCE ===' as info;

SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'recognition_records'
) as table_exists;

-- Step 2: Check table structure
SELECT '=== CHECKING TABLE STRUCTURE ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'recognition_records'
ORDER BY ordinal_position;

-- Step 3: Check RLS policies
SELECT '=== CHECKING RLS POLICIES ===' as info;

SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'recognition_records';

-- Step 4: Check indexes
SELECT '=== CHECKING INDEXES ===' as info;

SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'recognition_records';

-- Step 5: Check if there are any existing facilitator codes
SELECT '=== CHECKING EXISTING FACILITATOR CODES ===' as info;

SELECT 
    id,
    email,
    facilitator_code,
    role
FROM users 
WHERE role = 'Startup Facilitation Center' 
AND facilitator_code IS NOT NULL
LIMIT 5;

-- Step 6: Check if there are any existing startups
SELECT '=== CHECKING EXISTING STARTUPS ===' as info;

SELECT 
    id,
    name,
    sector
FROM startups 
LIMIT 5;

-- Step 7: Test inserting a sample recognition record (if startup ID 11 exists)
SELECT '=== TESTING RECOGNITION RECORD INSERTION ===' as info;

-- First check if startup ID 11 exists
SELECT 
    id,
    name,
    sector
FROM startups 
WHERE id = 11;

-- If startup exists, try to insert a test record
DO $$
DECLARE
    startup_exists BOOLEAN;
    test_record_id INTEGER;
BEGIN
    -- Check if startup exists
    SELECT EXISTS(SELECT 1 FROM startups WHERE id = 11) INTO startup_exists;
    
    IF startup_exists THEN
        -- Insert test record
        INSERT INTO recognition_records (
            startup_id, 
            program_name, 
            facilitator_name, 
            facilitator_code, 
            incubation_type, 
            fee_type, 
            date_added
        ) VALUES (
            11,
            'Test Incubation Program',
            'Test Facilitator',
            'FAC-TEST123',
            'Incubation Center',
            'Free',
            CURRENT_DATE
        ) RETURNING id INTO test_record_id;
        
        RAISE NOTICE 'Test record inserted with ID: %', test_record_id;
        
        -- Verify the record was inserted
        SELECT 'Test record details:' as info;
        SELECT 
            id,
            startup_id,
            program_name,
            facilitator_name,
            facilitator_code,
            incubation_type,
            fee_type,
            date_added
        FROM recognition_records 
        WHERE id = test_record_id;
        
        -- Clean up test record
        DELETE FROM recognition_records WHERE id = test_record_id;
        RAISE NOTICE 'Test record cleaned up';
        
    ELSE
        RAISE NOTICE 'Startup ID 11 does not exist, skipping test insertion';
    END IF;
END $$;

-- Step 8: Test facilitator code validation query
SELECT '=== TESTING FACILITATOR CODE VALIDATION ===' as info;

-- This is the exact query used by the recognitionService.validateFacilitatorCode function
SELECT 
    facilitator_code,
    role
FROM users 
WHERE facilitator_code = 'FAC-0EFCD9'  -- Use an existing facilitator code if available
AND role = 'Startup Facilitation Center';

-- Step 9: Test getting recognition records by startup ID
SELECT '=== TESTING RECOGNITION RECORDS BY STARTUP ID ===' as info;

-- This is the exact query used by the recognitionService.getRecognitionRecordsByStartupId function
SELECT 
    id,
    startup_id,
    program_name,
    facilitator_name,
    facilitator_code,
    incubation_type,
    fee_type,
    fee_amount,
    equity_allocated,
    pre_money_valuation,
    signed_agreement_url,
    date_added,
    created_at,
    updated_at
FROM recognition_records 
WHERE startup_id = 11  -- Use an existing startup ID if available
ORDER BY date_added DESC;

-- Step 10: Test getting recognition records by facilitator code
SELECT '=== TESTING RECOGNITION RECORDS BY FACILITATOR CODE ===' as info;

-- This is the exact query used by the recognitionService.getRecognitionRecordsByFacilitatorCode function
SELECT 
    rr.*,
    s.id as startup_id,
    s.name as startup_name,
    s.sector as startup_sector,
    s.total_funding as startup_total_funding,
    s.total_revenue as startup_total_revenue,
    s.registration_date as startup_registration_date
FROM recognition_records rr
JOIN startups s ON rr.startup_id = s.id
WHERE rr.facilitator_code = 'FAC-0EFCD9'  -- Use an existing facilitator code if available
ORDER BY rr.date_added DESC;

-- Step 11: Summary of what we've tested
SELECT '=== BACKEND TESTING SUMMARY ===' as info;

SELECT 
    'Table exists' as test,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'recognition_records'
    ) as result
UNION ALL
SELECT 
    'RLS enabled' as test,
    EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE tablename = 'recognition_records' 
        AND rowsecurity = true
    ) as result
UNION ALL
SELECT 
    'Foreign key exists' as test,
    EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'recognition_records' 
        AND constraint_type = 'FOREIGN KEY'
    ) as result
UNION ALL
SELECT 
    'Indexes exist' as test,
    EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'recognition_records'
    ) as result;

SELECT '=== RECOGNITION BACKEND TESTING COMPLETE ===' as info;
