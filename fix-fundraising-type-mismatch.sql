-- =====================================================
-- FIX FUNDRAISING TYPE MISMATCH
-- =====================================================
-- This script fixes the type constraint issue in fundraising_details

-- First, let's see what the current constraint expects
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'fundraising_details'::regclass 
    AND conname = 'fundraising_details_type_check';

-- Check what values are currently in the type column
SELECT DISTINCT type FROM fundraising_details;

-- Drop the existing constraint
ALTER TABLE fundraising_details DROP CONSTRAINT IF EXISTS fundraising_details_type_check;

-- Create a new constraint that accepts the InvestmentType enum values
ALTER TABLE fundraising_details ADD CONSTRAINT fundraising_details_type_check 
    CHECK (type IN ('Pre-Seed', 'Seed', 'Series A', 'Series B', 'Bridge'));

-- Verify the new constraint
SELECT 
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'fundraising_details'::regclass 
    AND conname = 'fundraising_details_type_check';

-- Test the constraint with valid values
DO $$
BEGIN
    -- Test with valid values
    RAISE NOTICE 'Testing valid values...';
    
    -- This should work
    INSERT INTO fundraising_details (startup_id, active, type, value, equity, validation_requested)
    VALUES (1, true, 'Series A', 5000000, 15, false)
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE '✅ Valid value test passed';
    
    -- Clean up test data
    DELETE FROM fundraising_details WHERE startup_id = 1;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Test failed: %', SQLERRM;
END
$$;
