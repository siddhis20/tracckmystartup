-- Add facilitator IDs to users table and assign unique IDs to facilitators
-- This will help connect startups and facilitators properly

-- 1. Add facilitator_id column to users table if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS facilitator_id VARCHAR(20) UNIQUE;

-- 2. Generate unique facilitator IDs for existing facilitators
-- First, let's see what facilitators we have
SELECT 'Current facilitators:' as info;
SELECT 
    id,
    name,
    email,
    role,
    facilitator_id
FROM users 
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at;

-- 3. Generate and assign facilitator IDs for existing facilitators
UPDATE users 
SET facilitator_id = CONCAT('FAC-', UPPER(SUBSTRING(id::text FROM 25 FOR 6)))
WHERE role = 'Startup Facilitation Center' 
AND facilitator_id IS NULL;

-- 4. Create a function to automatically generate facilitator IDs for new facilitators
CREATE OR REPLACE FUNCTION generate_facilitator_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.role = 'Startup Facilitation Center' AND NEW.facilitator_id IS NULL THEN
        -- Use the last 6 characters of the UUID for the facilitator ID
        NEW.facilitator_id := CONCAT('FAC-', UPPER(SUBSTRING(NEW.id::text FROM 25 FOR 6)));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger to automatically assign facilitator IDs
DROP TRIGGER IF EXISTS auto_generate_facilitator_id ON users;
CREATE TRIGGER auto_generate_facilitator_id
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION generate_facilitator_id();

-- 6. Update existing facilitators that might not have been updated
UPDATE users 
SET facilitator_id = CONCAT('FAC-', UPPER(SUBSTRING(id::text FROM 25 FOR 6)))
WHERE role = 'Startup Facilitation Center' 
AND (facilitator_id IS NULL OR facilitator_id = '');

-- 7. Verify the facilitator IDs were assigned
SELECT 'Facilitators with IDs:' as info;
SELECT 
    id,
    name,
    email,
    facilitator_id,
    created_at
FROM users 
WHERE role = 'Startup Facilitation Center'
ORDER BY created_at;

-- 8. Add index for better performance
CREATE INDEX IF NOT EXISTS idx_users_facilitator_id ON users(facilitator_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- 9. Show current facilitator ID format
SELECT 'Current facilitator ID format:' as info;
SELECT 
    'Facilitator IDs are in format' as info,
    'FAC-XXXXXX where XXXXXX is a 6-digit number' as format_explanation;

-- 10. Show summary
SELECT 'FACILITATOR ID SETUP COMPLETE' as summary;
SELECT 
    COUNT(*) as total_facilitators,
    COUNT(CASE WHEN facilitator_id IS NOT NULL THEN 1 END) as facilitators_with_ids,
    COUNT(CASE WHEN facilitator_id IS NULL THEN 1 END) as facilitators_without_ids
FROM users 
WHERE role = 'Startup Facilitation Center';
