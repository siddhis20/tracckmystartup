-- ADD_FACILITATOR_CODE_COLUMN.sql
-- Add facilitator_code column to users table and set up facilitator code system

-- 1. Add facilitator_code column to users table if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS facilitator_code TEXT;

-- 2. Create index for better performance when querying by facilitator_code
CREATE INDEX IF NOT EXISTS idx_users_facilitator_code ON users(facilitator_code);

-- 3. Add facilitator_code column to incubation_opportunities table if it doesn't exist
ALTER TABLE incubation_opportunities 
ADD COLUMN IF NOT EXISTS facilitator_code TEXT;

-- 4. Create index for better performance when querying opportunities by facilitator_code
CREATE INDEX IF NOT EXISTS idx_incubation_opportunities_facilitator_code ON incubation_opportunities(facilitator_code);

-- 5. Generate facilitator codes for existing facilitators who don't have one
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

-- 6. Update existing incubation opportunities with facilitator codes
UPDATE incubation_opportunities 
SET facilitator_code = users.facilitator_code
FROM users 
WHERE incubation_opportunities.facilitator_id = users.id 
AND users.facilitator_code IS NOT NULL
AND incubation_opportunities.facilitator_code IS NULL;

-- 7. Verify the setup
SELECT 
    'Users with facilitator codes' as check_type,
    COUNT(*) as count
FROM users 
WHERE role = 'Startup Facilitation Center' AND facilitator_code IS NOT NULL;

-- 8. Show sample facilitator codes
SELECT 
    id,
    email,
    facilitator_code,
    role
FROM users 
WHERE role = 'Startup Facilitation Center' 
ORDER BY created_at DESC 
LIMIT 5;

-- 9. Check incubation_opportunities structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'incubation_opportunities' 
AND column_name = 'facilitator_code';

-- 10. Show opportunities with facilitator codes
SELECT 
    'Opportunities with facilitator codes' as check_type,
    COUNT(*) as count
FROM incubation_opportunities 
WHERE facilitator_code IS NOT NULL;
