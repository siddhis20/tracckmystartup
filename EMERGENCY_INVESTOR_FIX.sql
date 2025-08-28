-- EMERGENCY_INVESTOR_FIX.sql
-- Emergency fix for investor code issues and profile problems

-- Step 1: Check current state
SELECT '=== EMERGENCY DIAGNOSIS ===' as info;

-- Check the specific user having issues
SELECT 
    'Problem User Analysis' as check_type,
    id,
    email,
    role,
    investor_code,
    startup_name,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ CRITICAL: Missing Investor Code'
        WHEN investor_code = '' THEN '⚠️ WARNING: Empty Investor Code'
        ELSE '✅ OK: Has Investor Code'
    END as code_status,
    CASE 
        WHEN startup_name IS NULL THEN '⚠️ WARNING: startup_name is NULL'
        WHEN startup_name = '' THEN '⚠️ WARNING: startup_name is empty'
        ELSE '✅ OK: startup_name has value'
    END as startup_status
FROM users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- Step 2: Check if investor_code column exists
SELECT 
    'Column Check' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'investor_code';

-- Step 3: EMERGENCY FIX - Generate investor code for the specific user
DO $$
DECLARE
    user_id UUID;
    new_code TEXT;
    attempts INTEGER;
    max_attempts INTEGER := 100;
BEGIN
    -- Get the user ID
    SELECT id INTO user_id 
    FROM users 
    WHERE email = 'olympiad_info1@startupnationindia.com';
    
    IF user_id IS NULL THEN
        RAISE EXCEPTION 'User not found: olympiad_info1@startupnationindia.com';
    END IF;
    
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
            RAISE EXCEPTION 'Unable to generate unique investor code after % attempts', max_attempts;
        END IF;
    END LOOP;
    
    -- Update the user with the new investor code
    UPDATE users 
    SET investor_code = new_code 
    WHERE id = user_id;
    
    RAISE NOTICE 'EMERGENCY FIX: Generated investor code % for user % (%)', new_code, 'olympiad_info1@startupnationindia.com', user_id;
END $$;

-- Step 3.5: COMPREHENSIVE FIX - Generate codes for ALL investors missing codes
DO $$
DECLARE
    user_record RECORD;
    new_code TEXT;
    attempts INTEGER;
    max_attempts INTEGER := 100;
    codes_generated INTEGER := 0;
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
                       upper(substring(md5(random()::text || clock_timestamp()::text || user_record.id::text) from 1 for 6));
            
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
        
        codes_generated := codes_generated + 1;
        RAISE NOTICE 'COMPREHENSIVE FIX: Generated investor code % for user % (%)', new_code, user_record.email, user_record.id;
    END LOOP;
    
    RAISE NOTICE 'COMPREHENSIVE FIX: Generated % investor codes for missing users', codes_generated;
END $$;

-- Step 4: Fix startup_name type issue if it exists
UPDATE users 
SET startup_name = NULL 
WHERE email = 'olympiad_info1@startupnationindia.com' 
AND startup_name IS NOT NULL 
AND startup_name::text = 'null';

-- Step 5: Verify the fix
SELECT 
    'Fix Verification' as check_type,
    id,
    email,
    role,
    investor_code,
    startup_name,
    created_at,
    CASE 
        WHEN investor_code IS NULL THEN '❌ STILL MISSING CODE'
        WHEN investor_code = '' THEN '⚠️ STILL EMPTY CODE'
        ELSE '✅ FIXED: Has Investor Code'
    END as code_status
FROM users 
WHERE email = 'olympiad_info1@startupnationindia.com';

-- Step 6: Check all investors after fix
SELECT 
    'All Investors Status' as check_type,
    COUNT(*) as total_investors,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes
FROM users 
WHERE role = 'Investor';

-- Step 7: Show sample of fixed codes
SELECT 
    'Sample Fixed Codes' as check_type,
    id,
    email,
    role,
    investor_code,
    created_at
FROM users 
WHERE role = 'Investor' 
AND investor_code IS NOT NULL
ORDER BY created_at DESC 
LIMIT 5;

-- Step 8: Check for any remaining issues
SELECT 
    'Remaining Issues Check' as check_type,
    COUNT(*) as investors_without_codes
FROM users 
WHERE role = 'Investor' 
AND (investor_code IS NULL OR investor_code = '');

-- Step 9: Final status
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM users 
            WHERE role = 'Investor' AND (investor_code IS NULL OR investor_code = '')
        ) THEN '❌ EMERGENCY: Some investors still missing codes'
        ELSE '✅ SUCCESS: All investors now have codes'
    END as final_status;
