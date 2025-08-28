-- =====================================================
-- QUICK CA CODE FIX
-- =====================================================
-- This script quickly fixes common CA code issues
-- Run this in your Supabase SQL Editor

-- =====================================================
-- STEP 1: ENSURE CA SERVICE CODE COLUMN EXISTS
-- =====================================================

-- Add ca_service_code column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'ca_service_code'
    ) THEN
        ALTER TABLE public.startups ADD COLUMN ca_service_code VARCHAR(50);
        RAISE NOTICE 'Added ca_service_code column to startups table';
    ELSE
        RAISE NOTICE 'ca_service_code column already exists';
    END IF;
END $$;

-- Add cs_service_code column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'startups' AND column_name = 'cs_service_code'
    ) THEN
        ALTER TABLE public.startups ADD COLUMN cs_service_code VARCHAR(50);
        RAISE NOTICE 'Added cs_service_code column to startups table';
    ELSE
        RAISE NOTICE 'cs_service_code column already exists';
    END IF;
END $$;

-- =====================================================
-- STEP 2: RECREATE TRIGGER FUNCTION
-- =====================================================

-- Drop and recreate the trigger function
DROP FUNCTION IF EXISTS handle_ca_code_assignment() CASCADE;

-- Recreate the function
CREATE OR REPLACE FUNCTION handle_ca_code_assignment()
RETURNS TRIGGER AS $$
BEGIN
    -- If CA service code is being set and it's different from before
    IF NEW.ca_service_code IS NOT NULL AND 
       (OLD.ca_service_code IS NULL OR NEW.ca_service_code != OLD.ca_service_code) THEN
        
        -- Create assignment request
        PERFORM create_ca_assignment_request(
            NEW.id, 
            NEW.ca_service_code, 
            'CA assignment requested via startup profile update'
        );
        
        RAISE NOTICE 'CA assignment request created for startup % with CA code %', NEW.name, NEW.ca_service_code;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- STEP 3: RECREATE TRIGGER
-- =====================================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_ca_code_assignment ON public.startups;

-- Create the trigger
CREATE TRIGGER trigger_ca_code_assignment
    AFTER UPDATE ON public.startups
    FOR EACH ROW
    EXECUTE FUNCTION handle_ca_code_assignment();

-- =====================================================
-- STEP 4: TEST THE TRIGGER
-- =====================================================

-- Test by updating a startup with a CA code
DO $$
DECLARE
    test_startup_id INTEGER;
BEGIN
    -- Get first startup ID
    SELECT id INTO test_startup_id FROM public.startups LIMIT 1;
    
    IF test_startup_id IS NOT NULL THEN
        -- Update with a test CA code to trigger the function
        UPDATE public.startups 
        SET ca_service_code = 'CA-TEST01'
        WHERE id = test_startup_id;
        
        RAISE NOTICE 'Test update completed for startup ID %', test_startup_id;
    ELSE
        RAISE NOTICE 'No startups found to test with';
    END IF;
END $$;

-- =====================================================
-- STEP 5: VERIFICATION
-- =====================================================

-- Check if trigger was created
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_ca_code_assignment';

-- Check if any CA assignment requests were created
SELECT 
    COUNT(*) as total_requests,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_requests
FROM ca_assignment_requests;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================

SELECT '✅ Quick CA Code Fix Complete!' as status;
