-- FIX_INVESTOR_CODES.sql
-- Fix script to ensure all existing investors have proper investor codes

-- Step 1: Check current state
SELECT '=== CURRENT STATE ===' as info;

SELECT 
    'Investors without codes' as check_type,
    COUNT(*) as count
FROM users 
WHERE role = 'Investor' AND (investor_code IS NULL OR investor_code = '');

-- Step 2: Generate codes for investors who don't have them
DO $$
DECLARE
    user_record RECORD;
    new_code TEXT;
    attempts INTEGER;
    max_attempts INTEGER := 100;
BEGIN
    FOR user_record IN 
        SELECT id, email 
        FROM users 
        WHERE role = 'Investor' 
        AND (investor_code IS NULL OR investor_code = '')
    LOOP
        -- Generate a unique investor code
        attempts := 0;
        LOOP
            attempts := attempts + 1;
            new_code := 'INV-' || 
                       upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 6));
            
            -- Check if code already exists
            IF NOT EXISTS (
                SELECT 1 FROM users WHERE investor_code = new_code
            ) THEN
                EXIT;
            END IF;
            
            -- Prevent infinite loop
            IF attempts >= max_attempts THEN
                RAISE EXCEPTION 'Unable to generate unique investor code after % attempts for user %', max_attempts, user_record.email;
            END IF;
        END LOOP;
        
        -- Update the user with the new investor code
        UPDATE users 
        SET investor_code = new_code 
        WHERE id = user_record.id;
        
        RAISE NOTICE 'Generated investor code % for user % (%)', new_code, user_record.email, user_record.id;
    END LOOP;
END $$;

-- Step 3: Verify the fix
SELECT '=== VERIFICATION ===' as info;

SELECT 
    'Investors after fix' as check_type,
    COUNT(*) as total_investors,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes
FROM users 
WHERE role = 'Investor';

-- Step 4: Show sample of fixed codes
SELECT 
    'Sample fixed codes' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at
FROM users 
WHERE role = 'Investor' 
ORDER BY created_at DESC 
LIMIT 5;

-- Step 5: Check code format validity
SELECT 
    'Code format validation' as check_type,
    COUNT(*) as total_investors,
    COUNT(CASE WHEN investor_code ~ '^INV-[A-Z0-9]{6}$' THEN 1 END) as valid_format,
    COUNT(CASE WHEN investor_code !~ '^INV-[A-Z0-9]{6}$' THEN 1 END) as invalid_format
FROM users 
WHERE role = 'Investor' AND investor_code IS NOT NULL;

-- Step 6: Update investment records if needed
-- This will link existing investment records to investor codes
UPDATE investment_records 
SET investor_code = u.investor_code
FROM users u
WHERE investment_records.investor_name = u.name 
AND investment_records.investor_code IS NULL
AND u.role = 'Investor'
AND u.investor_code IS NOT NULL;

-- Step 7: Final verification
SELECT '=== FINAL VERIFICATION ===' as info;

SELECT 
    'Final investment records status' as check_type,
    COUNT(*) as total_records,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes
FROM investment_records;

-- Show any remaining investment records without codes
SELECT 
    'Remaining records without codes' as check_type,
    id,
    startup_id,
    investor_name,
    investor_code,
    amount,
    created_at
FROM investment_records 
WHERE investor_code IS NULL
ORDER BY created_at DESC;

