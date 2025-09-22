-- Minimal fix for Investment Advisor acceptance bug
-- This adds only the essential column needed for basic acceptance to work

-- Add the advisor_accepted column if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS advisor_accepted BOOLEAN DEFAULT FALSE;

-- Add the advisor_accepted_date column if it doesn't exist  
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS advisor_accepted_date TIMESTAMP WITH TIME ZONE;

-- Create a simple index for performance
CREATE INDEX IF NOT EXISTS idx_users_advisor_accepted ON users(advisor_accepted);

-- Verify the columns were added
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('advisor_accepted', 'advisor_accepted_date')
ORDER BY column_name;


