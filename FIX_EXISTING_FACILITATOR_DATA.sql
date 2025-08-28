-- FIX_EXISTING_FACILITATOR_DATA.sql
-- This script fixes existing facilitator data by populating facilitator_code columns

-- Step 1: Check current state
SELECT '=== CURRENT STATE ===' as info;

-- Check if facilitator_code columns exist
SELECT 
    'Column check' as step,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('users', 'incubation_opportunities')
AND column_name = 'facilitator_code';

-- Step 2: Show facilitators without codes
SELECT 
    'Facilitators without codes' as step,
    id,
    email,
    role,
    facilitator_code
FROM users 
WHERE role = 'Startup Facilitation Center' 
AND facilitator_code IS NULL;

-- Step 3: Generate codes for facilitators who don't have one
DO $$
DECLARE
    user_record RECORD;
    new_code TEXT;
BEGIN
    FOR user_record IN 
        SELECT id, email 
        FROM users 
        WHERE role = 'Startup Facilitation Center' 
        AND facilitator_code IS NULL
    LOOP
        -- Generate a unique facilitator code
        new_code := 'FAC-' || to_char(now(), 'YYYYMMDD') || '-' || 
                    upper(substring(md5(random()::text) from 1 for 6));
        
        -- Update the user with the new facilitator code
        UPDATE users 
        SET facilitator_code = new_code 
        WHERE id = user_record.id;
        
        RAISE NOTICE 'Generated facilitator code % for user % (%)', new_code, user_record.email, user_record.id;
    END LOOP;
END $$;

-- Step 4: Update existing opportunities with facilitator codes
UPDATE incubation_opportunities 
SET facilitator_code = users.facilitator_code
FROM users 
WHERE incubation_opportunities.facilitator_id = users.id 
AND users.facilitator_code IS NOT NULL
AND incubation_opportunities.facilitator_code IS NULL;

-- Step 5: Verify the fix
SELECT 
    'Facilitators with codes' as step,
    COUNT(*) as count
FROM users 
WHERE role = 'Startup Facilitation Center' AND facilitator_code IS NOT NULL;

-- Step 6: Show opportunities with facilitator codes
SELECT 
    'Opportunities with facilitator codes' as step,
    COUNT(*) as count
FROM incubation_opportunities 
WHERE facilitator_code IS NOT NULL;

-- Step 7: Show all opportunities and their codes
SELECT 
    'All opportunities' as step,
    io.id,
    io.program_name,
    io.facilitator_id,
    io.facilitator_code,
    u.email as facilitator_email,
    u.facilitator_code as user_facilitator_code
FROM incubation_opportunities io
LEFT JOIN users u ON io.facilitator_id = u.id
ORDER BY io.created_at DESC;

-- Step 8: Show applications with facilitator info
SELECT 
    'Applications with facilitator info' as step,
    oa.id,
    oa.startup_id,
    oa.opportunity_id,
    oa.status,
    oa.diligence_status,
    io.program_name,
    io.facilitator_code,
    u.email as facilitator_email
FROM opportunity_applications oa
JOIN incubation_opportunities io ON oa.opportunity_id = io.id
LEFT JOIN users u ON io.facilitator_id = u.id
ORDER BY oa.created_at DESC;
