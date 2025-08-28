-- CREATE_STARTUP_UNIQUE_IDS.sql
-- This script creates unique IDs for all startups and updates the system

-- Step 1: Add startup_code column to startups table
ALTER TABLE public.startups 
ADD COLUMN IF NOT EXISTS startup_code TEXT;

-- Step 2: Generate unique startup codes for existing startups
UPDATE startups 
SET startup_code = 'ST-' || LPAD(id::text, 6, '0')
WHERE startup_code IS NULL;

-- Step 3: Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_startups_startup_code ON startups(startup_code);

-- Step 4: Show current startups with their codes
SELECT '=== STARTUPS WITH CODES ===' as info;

SELECT 
    id,
    name,
    startup_code,
    created_at
FROM startups
ORDER BY created_at DESC;

-- Step 5: Update opportunity_applications to include startup_code
ALTER TABLE public.opportunity_applications 
ADD COLUMN IF NOT EXISTS startup_code TEXT;

-- Step 6: Populate startup_code in opportunity_applications
UPDATE opportunity_applications 
SET startup_code = startups.startup_code
FROM startups 
WHERE opportunity_applications.startup_id = startups.id
AND opportunity_applications.startup_code IS NULL;

-- Step 7: Show applications with startup codes
SELECT '=== APPLICATIONS WITH STARTUP CODES ===' as info;

SELECT 
    oa.id,
    oa.startup_id,
    oa.startup_code,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    s.name as startup_name
FROM opportunity_applications oa
JOIN startups s ON oa.startup_id = s.id
ORDER BY oa.created_at DESC;

-- Step 8: Create a function to generate new startup codes
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

-- Step 9: Add trigger to auto-generate startup codes for new startups
CREATE OR REPLACE FUNCTION set_startup_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.startup_code IS NULL THEN
        NEW.startup_code := generate_startup_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_startup_code ON startups;
CREATE TRIGGER trigger_set_startup_code
    BEFORE INSERT ON startups
    FOR EACH ROW
    EXECUTE FUNCTION set_startup_code();

-- Step 10: Verify the setup
SELECT '=== VERIFICATION ===' as info;

SELECT 
    'Startups table' as table_name,
    COUNT(*) as total_records,
    COUNT(startup_code) as records_with_codes
FROM startups
UNION ALL
SELECT 
    'Applications table' as table_name,
    COUNT(*) as total_records,
    COUNT(startup_code) as records_with_codes
FROM opportunity_applications;
