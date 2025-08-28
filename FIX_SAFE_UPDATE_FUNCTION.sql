-- Fix the safe_update_diligence_status function
-- This ensures the RPC function exists and works correctly

-- 1. Drop the function if it exists to recreate it
DROP FUNCTION IF EXISTS safe_update_diligence_status(UUID, TEXT, TEXT);

-- 2. Create the function with proper parameter handling
CREATE OR REPLACE FUNCTION safe_update_diligence_status(
    p_application_id UUID,
    p_new_status TEXT,
    p_expected_current_status TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_status TEXT;
    update_count INTEGER;
BEGIN
    -- Get current status
    SELECT diligence_status INTO current_status
    FROM opportunity_applications
    WHERE id = p_application_id;
    
    -- If no record found, return false
    IF current_status IS NULL THEN
        RAISE NOTICE 'No application found with ID: %', p_application_id;
        RETURN FALSE;
    END IF;
    
    -- If expected current status is provided, check it matches
    IF p_expected_current_status IS NOT NULL AND current_status != p_expected_current_status THEN
        RAISE NOTICE 'Expected status % but found % for application %', p_expected_current_status, current_status, p_application_id;
        RETURN FALSE;
    END IF;
    
    -- Prevent updating if already approved
    IF current_status = 'approved' AND p_new_status = 'approved' THEN
        RAISE NOTICE 'Diligence already approved for application %', p_application_id;
        RETURN FALSE;
    END IF;
    
    -- Update the status
    UPDATE opportunity_applications
    SET diligence_status = p_new_status,
        updated_at = NOW()
    WHERE id = p_application_id
    AND diligence_status != 'approved'; -- Prevent overwriting approved status
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    
    RAISE NOTICE 'Updated % rows for application % from % to %', update_count, p_application_id, current_status, p_new_status;
    
    RETURN update_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION safe_update_diligence_status(UUID, TEXT, TEXT) TO authenticated;

-- 4. Test the function
SELECT 'Testing safe_update_diligence_status function:' as test_step;

-- Check if function exists
SELECT 
    'Function exists' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'safe_update_diligence_status'
        ) THEN '✅ Function created successfully'
        ELSE '❌ Function creation failed'
    END as status;

-- 5. Show current applications that could be used for testing
SELECT 'Current applications for testing:' as test_step;
SELECT 
    id,
    startup_id,
    opportunity_id,
    status,
    diligence_status,
    created_at
FROM opportunity_applications
WHERE diligence_status = 'requested'
ORDER BY created_at DESC
LIMIT 5;

-- 6. Test the function with a sample application (if any exist)
DO $$
DECLARE
    test_app_id UUID;
    test_result BOOLEAN;
BEGIN
    -- Get a test application ID
    SELECT id INTO test_app_id
    FROM opportunity_applications
    WHERE diligence_status = 'requested'
    LIMIT 1;
    
    IF test_app_id IS NOT NULL THEN
        -- Test the function
        SELECT safe_update_diligence_status(test_app_id, 'approved', 'requested') INTO test_result;
        
        RAISE NOTICE 'Test result for application %: %', test_app_id, test_result;
    ELSE
        RAISE NOTICE 'No test applications found with diligence_status = requested';
    END IF;
END $$;

-- 7. Show function signature
SELECT 'Function signature:' as info;
SELECT 
    routine_name,
    data_type as return_type,
    parameter_name,
    parameter_mode,
    data_type as param_type
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON r.specific_name = p.specific_name
WHERE routine_name = 'safe_update_diligence_status'
ORDER BY ordinal_position;
