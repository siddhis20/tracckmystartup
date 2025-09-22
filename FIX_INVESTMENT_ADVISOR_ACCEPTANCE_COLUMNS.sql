-- Fix Investment Advisor Acceptance Bug - Add Missing Database Columns
-- This script adds all the missing columns needed for the Investment Advisor acceptance workflow

-- 1. Add advisor_accepted column (if not exists)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS advisor_accepted BOOLEAN DEFAULT FALSE;

-- 2. Add advisor_accepted_date column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS advisor_accepted_date TIMESTAMP WITH TIME ZONE;

-- 3. Add financial matrix columns for accepted investors/startups
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS minimum_investment DECIMAL(15,2),
ADD COLUMN IF NOT EXISTS maximum_investment DECIMAL(15,2),
ADD COLUMN IF NOT EXISTS investment_stage TEXT,
ADD COLUMN IF NOT EXISTS success_fee DECIMAL(15,2),
ADD COLUMN IF NOT EXISTS success_fee_type TEXT DEFAULT 'percentage',
ADD COLUMN IF NOT EXISTS scouting_fee DECIMAL(15,2);

-- 4. Add comments to explain the column purposes
COMMENT ON COLUMN users.advisor_accepted IS 'Tracks whether an investor/startup has been accepted by an investment advisor after entering their code';
COMMENT ON COLUMN users.advisor_accepted_date IS 'Timestamp when the advisor accepted the investor/startup request';
COMMENT ON COLUMN users.minimum_investment IS 'Minimum investment amount set by the advisor for this investor/startup';
COMMENT ON COLUMN users.maximum_investment IS 'Maximum investment amount set by the advisor for this investor/startup';
COMMENT ON COLUMN users.investment_stage IS 'Investment stage preference set by the advisor';
COMMENT ON COLUMN users.success_fee IS 'Success fee amount or percentage set by the advisor';
COMMENT ON COLUMN users.success_fee_type IS 'Type of success fee: percentage or fixed amount';
COMMENT ON COLUMN users.scouting_fee IS 'Scouting fee amount set by the advisor';

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_advisor_accepted ON users(advisor_accepted);
CREATE INDEX IF NOT EXISTS idx_users_advisor_accepted_date ON users(advisor_accepted_date);
CREATE INDEX IF NOT EXISTS idx_users_investment_advisor_code_accepted 
ON users(investment_advisor_code_entered, advisor_accepted) 
WHERE investment_advisor_code_entered IS NOT NULL;

-- 6. Verify the columns were added successfully
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN (
    'advisor_accepted', 
    'advisor_accepted_date', 
    'minimum_investment', 
    'maximum_investment', 
    'investment_stage', 
    'success_fee', 
    'success_fee_type', 
    'scouting_fee'
)
ORDER BY column_name;

-- 7. Show sample data to verify the columns exist and work
SELECT 
    id,
    name,
    email,
    role,
    investment_advisor_code_entered,
    advisor_accepted,
    advisor_accepted_date,
    minimum_investment,
    maximum_investment,
    investment_stage,
    success_fee,
    success_fee_type,
    scouting_fee,
    created_at
FROM users 
WHERE investment_advisor_code_entered IS NOT NULL
ORDER BY role, name
LIMIT 10;


