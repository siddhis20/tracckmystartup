-- COMPLETE_FACILITATOR_SYSTEM_UPDATE.sql
-- This script updates the entire facilitator system with startup unique IDs and proper access control

-- Step 1: Create startup unique IDs system
SELECT '=== CREATING STARTUP UNIQUE ID SYSTEM ===' as info;

-- Add startup_code column to startups table
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS startup_code TEXT;

-- Generate unique startup codes for existing startups
UPDATE startups 
SET startup_code = 'ST-' || LPAD(id::text, 6, '0')
WHERE startup_code IS NULL;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_startups_startup_code ON startups(startup_code);

-- Step 2: Update opportunity_applications with startup codes
SELECT '=== UPDATING APPLICATIONS WITH STARTUP CODES ===' as info;

-- Add startup_code column to opportunity_applications
ALTER TABLE public.opportunity_applications 
ADD COLUMN IF NOT EXISTS startup_code TEXT;

-- Populate startup_code in opportunity_applications
UPDATE opportunity_applications 
SET startup_code = startups.startup_code
FROM startups 
WHERE opportunity_applications.startup_id = startups.id
AND opportunity_applications.startup_code IS NULL;

-- Step 3: Update facilitator codes for existing opportunities
SELECT '=== UPDATING FACILITATOR CODES ===' as info;

-- Update opportunities with real facilitator codes from users table
UPDATE incubation_opportunities 
SET facilitator_code = users.facilitator_code
FROM users 
WHERE incubation_opportunities.facilitator_id = users.id 
AND users.facilitator_code IS NOT NULL
AND incubation_opportunities.facilitator_code IS NULL;

-- Step 4: Create functions for auto-generating codes
SELECT '=== CREATING AUTO-GENERATION FUNCTIONS ===' as info;

-- Create function to generate new startup codes
CREATE OR REPLACE FUNCTION generate_startup_code()
RETURNS TEXT AS $$
DECLARE
    new_code TEXT;
    counter INTEGER := 1;
BEGIN
    LOOP
        new_code := 'ST-' || LPAD(counter::text, 6, '0');
        
        -- Check if code already exists
        IF NOT EXISTS (SELECT 1 FROM startups WHERE startup_code = new_code) THEN
            RETURN new_code;
        END IF;
        
        counter := counter + 1;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Create function to set startup code on insert
CREATE OR REPLACE FUNCTION set_startup_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.startup_code IS NULL THEN
        NEW.startup_code := generate_startup_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-generating startup codes
DROP TRIGGER IF EXISTS trigger_set_startup_code ON startups;
CREATE TRIGGER trigger_set_startup_code
    BEFORE INSERT ON startups
    FOR EACH ROW
    EXECUTE FUNCTION set_startup_code();

-- Step 5: Verify the complete system
SELECT '=== VERIFICATION ===' as info;

-- Show startups with their codes
SELECT 
    'Startups' as table_name,
    COUNT(*) as total_records,
    COUNT(startup_code) as records_with_codes
FROM startups
UNION ALL
SELECT 
    'Applications' as table_name,
    COUNT(*) as total_records,
    COUNT(startup_code) as records_with_codes
FROM opportunity_applications
UNION ALL
SELECT 
    'Opportunities' as table_name,
    COUNT(*) as total_records,
    COUNT(facilitator_code) as records_with_codes
FROM incubation_opportunities;

-- Step 6: Show sample data
SELECT '=== SAMPLE DATA ===' as info;

-- Show startups with codes
SELECT 
    id,
    name,
    startup_code,
    created_at
FROM startups
ORDER BY created_at DESC
LIMIT 5;

-- Show applications with startup and facilitator codes
SELECT 
    oa.id,
    oa.startup_id,
    oa.startup_code,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    s.name as startup_name,
    io.program_name,
    io.facilitator_code
FROM opportunity_applications oa
JOIN startups s ON oa.startup_id = s.id
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
ORDER BY oa.created_at DESC
LIMIT 5;

-- Show facilitators with their codes
SELECT 
    id,
    email,
    role,
    facilitator_code,
    created_at
FROM users 
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at DESC;

-- Step 7: Test compliance access query
SELECT '=== TESTING COMPLIANCE ACCESS ===' as info;

-- Test the exact query the service will use
WITH facilitator_info AS (
    SELECT facilitator_code 
    FROM users 
    WHERE role = 'Startup Facilitation Center' 
    LIMIT 1
)
SELECT 
    'Facilitator Code' as info,
    facilitator_code
FROM facilitator_info;

-- Test opportunities query
WITH facilitator_info AS (
    SELECT facilitator_code 
    FROM users 
    WHERE role = 'Startup Facilitation Center' 
    LIMIT 1
)
SELECT 
    'Opportunities for facilitator code' as info,
    io.id,
    io.program_name,
    io.facilitator_code
FROM incubation_opportunities io, facilitator_info fi
WHERE io.facilitator_code = fi.facilitator_code;

-- Test applications query for startup 11
WITH facilitator_info AS (
    SELECT facilitator_code 
    FROM users 
    WHERE role = 'Startup Facilitation Center' 
    LIMIT 1
)
SELECT 
    'Applications for startup 11 with approved diligence' as info,
    oa.id,
    oa.startup_id,
    oa.startup_code,
    oa.opportunity_id,
    oa.diligence_status,
    io.facilitator_code
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id, facilitator_info fi
WHERE oa.startup_id = 11 
AND io.facilitator_code = fi.facilitator_code
AND oa.diligence_status = 'approved';

SELECT '=== SYSTEM UPDATE COMPLETE ===' as info;

