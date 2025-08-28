-- UNDO_STARTUP_CODE_CHANGES.sql
-- This script undoes all the startup_code changes and reverts to using existing id column

-- Step 1: Remove startup_code column from opportunity_applications table
SELECT '=== REMOVING STARTUP_CODE FROM APPLICATIONS ===' as info;

ALTER TABLE public.opportunity_applications 
DROP COLUMN IF EXISTS startup_code;

-- Step 2: Remove startup_code column from startups table
SELECT '=== REMOVING STARTUP_CODE FROM STARTUPS ===' as info;

ALTER TABLE public.startups 
DROP COLUMN IF EXISTS startup_code;

-- Step 3: Remove the auto-generation functions
SELECT '=== REMOVING AUTO-GENERATION FUNCTIONS ===' as info;

DROP FUNCTION IF EXISTS set_startup_code() CASCADE;
DROP FUNCTION IF EXISTS generate_startup_code() CASCADE;

-- Step 4: Remove the index
SELECT '=== REMOVING INDEX ===' as info;

DROP INDEX IF EXISTS idx_startups_startup_code;

-- Step 5: Verify the cleanup
SELECT '=== VERIFICATION ===' as info;

-- Check if startup_code columns are gone
SELECT 
    'startups table' as table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'startups' 
AND column_name = 'startup_code'
UNION ALL
SELECT 
    'opportunity_applications table' as table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications' 
AND column_name = 'startup_code';

-- Step 6: Show current table structure
SELECT '=== CURRENT TABLE STRUCTURE ===' as info;

-- Show startups table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'startups'
ORDER BY ordinal_position;

-- Show applications table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'opportunity_applications'
ORDER BY ordinal_position;

-- Step 7: Test using existing id column for connection
SELECT '=== TESTING WITH EXISTING ID COLUMN ===' as info;

-- Show how to connect facilitators and startups using existing id
SELECT 
    'Startup-Facilitator Connection' as connection_type,
    s.id as startup_id,
    s.name as startup_name,
    oa.id as application_id,
    oa.status as application_status,
    oa.diligence_status,
    io.id as opportunity_id,
    io.program_name,
    io.facilitator_code,
    u.email as facilitator_email
FROM startups s
JOIN opportunity_applications oa ON s.id = oa.startup_id
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
JOIN users u ON io.facilitator_id = u.id
WHERE s.id = 11  -- Test with startup 11
ORDER BY oa.created_at DESC;

SELECT '=== CLEANUP COMPLETE - USING EXISTING ID COLUMN ===' as info;
