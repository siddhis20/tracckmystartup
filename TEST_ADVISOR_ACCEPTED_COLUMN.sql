-- Test script to check if advisor_accepted column exists and add it if missing
-- This is a minimal fix to get the basic acceptance working

-- Check if the advisor_accepted column exists
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'advisor_accepted';

-- If the above query returns no results, run this to add the column:
-- ALTER TABLE users ADD COLUMN IF NOT EXISTS advisor_accepted BOOLEAN DEFAULT FALSE;

-- Test the column by trying to update a user (replace with actual user ID)
-- UPDATE users SET advisor_accepted = true WHERE id = 'your-user-id-here';

-- Verify the column works by selecting a user
SELECT 
    id,
    name,
    email,
    role,
    advisor_accepted,
    created_at
FROM users 
WHERE role IN ('Investor', 'Startup')
LIMIT 5;


