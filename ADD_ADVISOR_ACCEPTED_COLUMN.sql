-- Add advisor_accepted column to users table for Investment Advisor workflow
-- This column tracks whether an investor/startup has been accepted by an investment advisor

-- Add the advisor_accepted column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS advisor_accepted BOOLEAN DEFAULT FALSE;

-- Add a comment to explain the column purpose
COMMENT ON COLUMN users.advisor_accepted IS 'Tracks whether an investor/startup has been accepted by an investment advisor after entering their code';

-- Create an index for better performance when filtering by advisor_accepted
CREATE INDEX IF NOT EXISTS idx_users_advisor_accepted ON users(advisor_accepted);

-- Create a composite index for efficient filtering by investment advisor code and acceptance status
CREATE INDEX IF NOT EXISTS idx_users_investment_advisor_code_accepted 
ON users(investment_advisor_code_entered, advisor_accepted) 
WHERE investment_advisor_code_entered IS NOT NULL;

-- Verify the column was added successfully
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'advisor_accepted';

-- Show sample data to verify the column exists
SELECT 
    id,
    name,
    email,
    role,
    investment_advisor_code_entered,
    advisor_accepted,
    created_at
FROM users 
WHERE investment_advisor_code_entered IS NOT NULL
ORDER BY role, name
LIMIT 10;
