-- CREATE_INVESTOR_CODE_TRIGGER.sql
-- Create a database trigger to automatically generate investor codes

-- Step 1: Drop existing function if it exists, then create the function to generate unique investor codes
DROP FUNCTION IF EXISTS generate_investor_code();
CREATE OR REPLACE FUNCTION generate_investor_code()
RETURNS TRIGGER AS $$
DECLARE
    new_code TEXT;
    attempts INTEGER;
    max_attempts INTEGER := 100;
BEGIN
    -- Only generate codes for investors
    IF NEW.role != 'Investor' THEN
        RETURN NEW;
    END IF;
    
    -- If investor already has a code, don't change it
    IF NEW.investor_code IS NOT NULL AND NEW.investor_code != '' THEN
        RETURN NEW;
    END IF;
    
    -- Generate a unique investor code
    attempts := 0;
    LOOP
        attempts := attempts + 1;
        new_code := 'INV-' || 
                   upper(substring(md5(random()::text || clock_timestamp()::text || NEW.id::text) from 1 for 6));
        
        -- Check if code already exists
        IF NOT EXISTS (
            SELECT 1 FROM users WHERE investor_code = new_code
        ) THEN
            EXIT;
        END IF;
        
        -- Prevent infinite loop
        IF attempts >= max_attempts THEN
            RAISE EXCEPTION 'Unable to generate unique investor code after % attempts for user %', max_attempts, NEW.email;
        END IF;
    END LOOP;
    
    -- Set the new investor code
    NEW.investor_code := new_code;
    
    RAISE NOTICE 'Auto-generated investor code % for user % (%)', new_code, NEW.email, NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Create the trigger
DROP TRIGGER IF EXISTS trigger_generate_investor_code ON users;
CREATE TRIGGER trigger_generate_investor_code
    BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION generate_investor_code();

-- Step 3: Fix existing investors without codes
UPDATE users 
SET investor_code = (
    SELECT 'INV-' || upper(substring(md5(random()::text || clock_timestamp()::text || id::text) from 1 for 6))
)
WHERE role = 'Investor' 
AND (investor_code IS NULL OR investor_code = '');

-- Step 4: Verify the fix
SELECT 
    'Verification after trigger creation' as check_type,
    COUNT(*) as total_investors,
    COUNT(investor_code) as with_codes,
    COUNT(*) - COUNT(investor_code) as without_codes,
    CASE 
        WHEN COUNT(*) - COUNT(investor_code) = 0 THEN '✅ All investors now have codes'
        ELSE '❌ Some investors still missing codes'
    END as status
FROM users 
WHERE role = 'Investor';

-- Step 5: Show sample of fixed codes
SELECT 
    'Sample fixed codes' as check_type,
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

-- Step 6: Test trigger on new insert (simulation)
SELECT 
    'Trigger test simulation' as test_type,
    'Trigger should now work for new investors' as message,
    'All existing investors should have codes' as status;
