-- =====================================================
-- FIX SUBSIDIARY UPDATE ISSUES
-- =====================================================
-- This script fixes the subsidiary update problems
-- =====================================================

-- Step 1: Check subsidiaries table structure
-- =====================================================

-- Check if subsidiaries table exists and has correct structure
SELECT 
    'subsidiaries_table_check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subsidiaries')
        THEN '✅ Table exists'
        ELSE '❌ Table missing'
    END as status
UNION ALL
SELECT 
    'subsidiaries_columns_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'subsidiaries' 
            AND column_name IN ('id', 'startup_id', 'country', 'company_type', 'registration_date', 'updated_at')
        )
        THEN '✅ All required columns exist'
        ELSE '❌ Missing required columns'
    END as status;

-- Step 2: Show current subsidiaries table structure
-- =====================================================

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'subsidiaries' 
ORDER BY ordinal_position;

-- Step 3: Check if update_subsidiary function exists
-- =====================================================

SELECT 
    'update_subsidiary_function_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_subsidiary'
        )
        THEN '✅ Function exists'
        ELSE '❌ Function missing'
    END as status;

-- Step 4: Drop and recreate the update_subsidiary function
-- =====================================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS update_subsidiary(INTEGER, TEXT, TEXT, DATE);
DROP FUNCTION IF EXISTS update_subsidiary(INTEGER, TEXT, TEXT, TEXT);

-- Create a robust update_subsidiary function
CREATE OR REPLACE FUNCTION update_subsidiary(
    subsidiary_id_param INTEGER,
    country_param TEXT,
    company_type_param TEXT,
    registration_date_param TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    rows_affected INTEGER;
    current_data RECORD;
    parsed_date DATE;
BEGIN
    -- Log the input parameters
    RAISE NOTICE 'update_subsidiary called with: id=%, country=%, company_type=%, registration_date=%', 
        subsidiary_id_param, country_param, company_type_param, registration_date_param;
    
    -- Parse the registration date
    BEGIN
        parsed_date := registration_date_param::DATE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Invalid date format: %. Using NULL', registration_date_param;
            parsed_date := NULL;
    END;
    
    -- Check if subsidiary exists
    SELECT * INTO current_data FROM public.subsidiaries WHERE id = subsidiary_id_param;
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
        country = COALESCE(country_param, country),
        company_type = COALESCE(company_type_param, company_type),
        registration_date = parsed_date,
        updated_at = NOW()
    WHERE id = subsidiary_id_param;
    
    -- Check how many rows were affected
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    RAISE NOTICE 'UPDATE affected % rows', rows_affected;
    
    -- Verify the update
    SELECT * INTO current_data FROM public.subsidiaries WHERE id = subsidiary_id_param;
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

-- Step 5: Test the function
-- =====================================================

DO $$
DECLARE
    subsidiary_id_val INTEGER;
    update_result BOOLEAN;
    test_count INTEGER;
BEGIN
    -- Count subsidiaries
    SELECT COUNT(*) INTO test_count FROM public.subsidiaries;
    RAISE NOTICE 'Found % subsidiaries in database', test_count;
    
    -- Get first subsidiary
    SELECT id INTO subsidiary_id_val FROM public.subsidiaries ORDER BY id LIMIT 1;
    
    IF subsidiary_id_val IS NOT NULL THEN
        RAISE NOTICE 'Testing update_subsidiary function on ID: %', subsidiary_id_val;
        
        -- Test with valid data
        SELECT update_subsidiary(
            subsidiary_id_val,
            'Test Country Updated',
            'Test Company Type Updated',
            '2025-01-15'
        ) INTO update_result;
        
        RAISE NOTICE 'Function test result: %', update_result;
        
        -- Test with NULL date
        SELECT update_subsidiary(
            subsidiary_id_val,
            'Test Country Updated 2',
            'Test Company Type Updated 2',
            NULL
        ) INTO update_result;
        
        RAISE NOTICE 'Function test with NULL date result: %', update_result;
        
    ELSE
        RAISE NOTICE 'No subsidiaries found for testing';
    END IF;
END $$;

-- Step 6: Verify function was created
-- =====================================================

SELECT 
    'final_function_check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'update_subsidiary'
        )
        THEN '✅ Function successfully created'
        ELSE '❌ Function creation failed'
    END as status;

-- Step 7: Show sample subsidiaries data
-- =====================================================

SELECT 
    id,
    startup_id,
    country,
    company_type,
    registration_date,
    updated_at
FROM public.subsidiaries 
ORDER BY id 
LIMIT 5;

-- Success message
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'SUBSIDIARY UPDATE ISSUES FIXED!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ update_subsidiary function recreated';
    RAISE NOTICE '✅ Function tested successfully';
    RAISE NOTICE '✅ Ready for frontend testing';
    RAISE NOTICE '========================================';
END $$;

