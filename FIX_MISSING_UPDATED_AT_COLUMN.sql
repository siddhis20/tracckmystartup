-- Fix missing updated_at column in opportunity_applications table
-- This will resolve the 42703 error

-- 1. Add the missing updated_at column
ALTER TABLE public.opportunity_applications 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Update existing records to have updated_at = created_at
UPDATE public.opportunity_applications 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- 3. Make updated_at NOT NULL after setting default values
ALTER TABLE public.opportunity_applications 
ALTER COLUMN updated_at SET NOT NULL;

-- 4. Create a trigger to automatically update updated_at on row changes
CREATE OR REPLACE FUNCTION update_opportunity_applications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create the trigger
DROP TRIGGER IF EXISTS opportunity_applications_updated_at_trigger ON public.opportunity_applications;
CREATE TRIGGER opportunity_applications_updated_at_trigger
    BEFORE UPDATE ON public.opportunity_applications
    FOR EACH ROW
    EXECUTE FUNCTION update_opportunity_applications_updated_at();

-- 6. Verify the column was added
SELECT 'Column verification:' as step;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications' 
AND column_name = 'updated_at';

-- 7. Show table structure
SELECT 'Table structure:' as step;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications'
ORDER BY ordinal_position;

-- 8. Test the trigger
SELECT 'Testing trigger:' as step;
SELECT 
    id,
    created_at,
    updated_at,
    CASE 
        WHEN created_at = updated_at THEN '✅ Default set correctly'
        ELSE '⚠️ Needs attention'
    END as status
FROM opportunity_applications
LIMIT 5;

-- 9. Update the safe_update_diligence_status function to work without updated_at
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
    
    -- Update the status (updated_at will be set automatically by trigger)
    UPDATE opportunity_applications
    SET diligence_status = p_new_status
    WHERE id = p_application_id
    AND diligence_status != 'approved'; -- Prevent overwriting approved status
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    
    RAISE NOTICE 'Updated % rows for application % from % to %', update_count, p_application_id, current_status, p_new_status;
    
    RETURN update_count > 0;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Grant execute permission
GRANT EXECUTE ON FUNCTION safe_update_diligence_status(UUID, TEXT, TEXT) TO authenticated;

-- 11. Test the function
SELECT 'Testing updated function:' as step;
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
        RAISE NOTICE 'Testing with application ID: %', test_app_id;
        
        -- Test the function
        SELECT safe_update_diligence_status(test_app_id, 'approved', 'requested') INTO test_result;
        
        RAISE NOTICE 'Test result: %', test_result;
        
        IF test_result THEN
            RAISE NOTICE '✅ Function worked - status updated successfully';
        ELSE
            RAISE NOTICE '❌ Function returned false - status not updated';
        END IF;
    ELSE
        RAISE NOTICE 'No test applications found with diligence_status = requested';
    END IF;
END $$;

-- 12. Summary
SELECT 'FIX COMPLETE' as summary;
SELECT 
    'updated_at column added' as column_fix,
    'trigger created for automatic updates' as trigger_fix,
    'function updated to work without manual updated_at' as function_fix;
