-- ADD_INVESTOR_CODE_COLUMN.sql
-- Add investor_code column to users table and set up investor code system

-- 1. Add investor_code column to users table if it doesn't exist
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS investor_code TEXT;

-- 2. Create index for better performance when querying by investor_code
CREATE INDEX IF NOT EXISTS idx_users_investor_code ON users(investor_code);

-- 3. Add investor_code column to investment_records table if it doesn't exist
ALTER TABLE investment_records 
ADD COLUMN IF NOT EXISTS investor_code TEXT;

-- 4. Create index for better performance when querying investments by investor_code
CREATE INDEX IF NOT EXISTS idx_investment_records_investor_code ON investment_records(investor_code);

-- 5. Generate investor codes for existing investors who don't have one
DO $$
DECLARE
    user_record RECORD;
    new_code TEXT;
BEGIN
    FOR user_record IN 
        SELECT id, email 
        FROM users 
        WHERE role = 'Investor' 
        AND investor_code IS NULL
    LOOP
        -- Generate a unique investor code
        new_code := 'INV-' || to_char(now(), 'YYYYMMDD') || '-' || 
                    upper(substring(md5(random()::text) from 1 for 6));
        
        -- Update the user with the new investor code
        UPDATE users 
        SET investor_code = new_code 
        WHERE id = user_record.id;
        
        RAISE NOTICE 'Generated investor code % for user % (%)', new_code, user_record.email, user_record.id;
    END LOOP;
END $$;

-- 6. Verify the setup
SELECT 
    'Users with investor codes' as check_type,
    COUNT(*) as count
FROM users 
WHERE role = 'Investor' AND investor_code IS NOT NULL;

-- 7. Show sample investor codes
SELECT 
    id,
    email,
    investor_code,
    role
FROM users 
WHERE role = 'Investor' 
ORDER BY created_at DESC 
LIMIT 5;

-- 8. Check investment_records structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'investment_records' 
AND column_name IN ('investor_code', 'investor_name', 'amount', 'equity_allocated')
ORDER BY column_name;

