-- =====================================================
-- FUNDRAISING DEBUG SCRIPT
-- =====================================================
-- This script helps debug fundraising_details table issues

-- Check if fundraising_details table exists and its structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'fundraising_details' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check if RLS is enabled on fundraising_details
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'fundraising_details' 
    AND schemaname = 'public';

-- Check existing RLS policies on fundraising_details
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'fundraising_details' 
    AND schemaname = 'public';

-- Check if there are any existing fundraising_details records
SELECT COUNT(*) as total_records FROM fundraising_details;

-- Check sample data if any exists
SELECT * FROM fundraising_details LIMIT 5;

-- Test basic insert (this will help identify RLS issues)
-- Note: This might fail due to RLS, but will show the exact error
DO $$
DECLARE
    test_startup_id INTEGER;
    insert_result RECORD;
BEGIN
    -- Get a startup ID for testing
    SELECT id INTO test_startup_id FROM startups LIMIT 1;
    
    IF test_startup_id IS NULL THEN
        RAISE NOTICE 'No startups found in database';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Testing with startup ID: %', test_startup_id;
    
    -- Try to insert a test record
    BEGIN
        INSERT INTO fundraising_details (
            startup_id,
            active,
            type,
            value,
            equity,
            validation_requested,
            pitch_deck_url,
            pitch_video_url
        ) VALUES (
            test_startup_id,
            true,
            'SeriesA',
            5000000,
            15,
            false,
            'https://example.com/pitch.pdf',
            'https://youtube.com/watch?v=test'
        ) RETURNING * INTO insert_result;
        
        RAISE NOTICE '✅ Test insert successful: %', insert_result;
        
        -- Clean up test data
        DELETE FROM fundraising_details WHERE startup_id = test_startup_id;
        RAISE NOTICE '🧹 Test data cleaned up';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Test insert failed: %', SQLERRM;
    END;
END
$$;
